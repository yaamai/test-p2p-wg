module main
import os
import wireguard
import netlink
import chord
import json
import net.http
import net.urllib
import time

struct WireguardComm {
pub mut:
  dev &wireguard.Device
}

fn (c WireguardComm) get_url_by_id(id string) ?string {
  ips := c.dev.get_allowed_ips()
  println(ips)
  if ip := ips[id] {
    return "http://${ip}:8080"
  }

  self_ip := netlink.get_interface_addr(c.dev.get_index())?
  return "http://${self_ip}:8080"
}

fn (c WireguardComm) get_predecessor(id string) ?string {
  url := c.get_url_by_id(id)? + "/predecessor"
  text := http.get(url)?.text
  println("get_predecessor(): ${url} -> ${text}")

  if text.len == 0 {
    return error('')
  }
  return text
}

fn (c WireguardComm) find_successor(id string, target string) ?string {
  url := c.get_url_by_id(id)? + "/successor" + "?target=" + target
  text := http.get(url)?.text
  println("find_successor(): ${url} -> ${text}")

  return text
}

fn (c WireguardComm) notify(id string, data string) ? {
  url := c.get_url_by_id(id)? + "/notify"
  println("notify(): ${id} ${data} -> ${url}")
  http.post(url, data)?
}

fn (c WireguardComm) query(id string, key string) ?string {
  return http.get(c.get_url_by_id(id)? + "/kvs/" + key)?.text
}

fn (c WireguardComm) store(id string, key string, val string) ? {
  http.post(c.get_url_by_id(id)? + "/kvs" + key, val)?
}

struct TestStore {
mut:
  m map[string]string
}

fn (s TestStore) get(key string) ?string {
  return s.m[key]
}

fn (mut s TestStore) set(key string, val string) ? {
  s.m[key] = val
}

struct ChordHandler {
mut:
  node &chord.Node
}
fn (mut h ChordHandler) handle(req http.Request) http.Response {
  url := urllib.parse(req.url) or { return http.Response{} }
  return match url.path {
    "/predecessor" { h.handle_get_predecessor(req, url) }
    "/successor" { h.handle_get_successor(req, url) }
    "/notify" { h.handle_notify(req, url) }
    "/kvs/" { h.handle_query(req, url) }
    "/kvs" { h.handle_store(req, url) }
    else { http.Response{} }
  }
}

fn (h ChordHandler) handle_get_predecessor(req http.Request, url urllib.URL) http.Response {
  if !h.node.has_predecessor {
    return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
  }
  return http.new_response(text: h.node.predecessor)
}

fn (h ChordHandler) handle_get_successor(req http.Request, url urllib.URL) http.Response {
  target := url.query().get("target")
  if succ := h.node.find_successor(target) {
    return http.new_response(text: succ)
  }
  return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
}

fn (mut h ChordHandler) handle_notify(req http.Request, url urllib.URL) http.Response {
  println("receive notify ${req.data}")
  h.node.notify(req.data)
  return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
}

fn (h ChordHandler) handle_query(req http.Request, url urllib.URL) http.Response {
  names := url.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return http.new_response(text: "invalid path")
  }
  if val := h.node.query(names[2]) {
    return http.new_response(text: val)
  }
  return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
}

fn (mut h ChordHandler) handle_store(req http.Request, url urllib.URL) http.Response {
  names := url.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return http.new_response(text: "invalid path")
  }
  h.node.set(names[2], req.data) or {
    return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
  }
  return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
}


fn bootstrap() ?wireguard.Device {
  public_key, private_key := wireguard.new_key()?.base64()
  mut dev := wireguard.new_device("sss0", true)?

  dev.set_private_key(private_key)
  dev.set_public_key(public_key)
  dev.set_listen_port(43617)
  dev.apply()?

  netlink.set_interface_up(dev.get_index())?
  netlink.add_interface_addr(dev.get_index(), "10.163.0.1", 32)?

  return dev
}

fn generate_peer_confg(mut dev wireguard.Device) ?JoinConfig {
  // should be random or network unique
  peer_addr := "10.163.0.2"
  public_key, private_key := wireguard.new_key()?.base64()

  peer := wireguard.new_peer(key: public_key, allowed_ip: peer_addr)?
  dev.set_peer(peer)
  dev.apply()?
  netlink.add_if_route(peer_addr, 32, dev.get_index(), true)?

  return JoinConfig {
    private_key: private_key,
    tunnel_addr: peer_addr,
    // TODO: query to netlink? or hold wireguard.Device or generate ip from id
    remote_tunnel_addr: "10.163.0.1",
    remote_port: 43617,
    remote_public_key: dev.get_public_key(),
  }
}

[params]
struct JoinConfig {
mut:
  private_key string
  tunnel_addr string
  remote_tunnel_addr string
  remote_addr string
  remote_port int
  remote_public_key string
}

fn join(p JoinConfig) ?wireguard.Device {
  mut dev := wireguard.new_device("sss0", true)?
  dev.set_private_key(p.private_key)
  dev.set_listen_port(43617)
  dev.set_peer(wireguard.new_peer(key: p.remote_public_key, addr: p.remote_addr, port: p.remote_port, allowed_ip: p.remote_tunnel_addr)?)
  dev.apply()?
  netlink.set_interface_up(dev.get_index())?
  netlink.add_interface_addr(dev.get_index(), p.tunnel_addr, 32)?
  netlink.add_if_route(p.remote_tunnel_addr, 32, dev.get_index(), true)?

  return dev
}

/*
sudo ip netns del siteA
sudo ip netns del siteB
sudo ip netns add siteA
sudo ip netns add siteB
sudo ip link add veth0 type veth peer name veth1
sudo ip link set dev veth0 netns siteA
sudo ip link set dev veth1 netns siteB
sudo ip netns exec siteA ip addr add dev veth0 10.0.0.1/24
sudo ip netns exec siteB ip addr add dev veth1 10.0.0.2/24
sudo ip netns exec siteA ip link set dev veth0 up
sudo ip netns exec siteB ip link set dev veth1 up
sudo ip netns exec siteA ip link set dev lo up
sudo ip netns exec siteB ip link set dev lo up
*/

fn http_server_loop(mut server http.Server) {
    server.listen_and_serve() or {
      return
    }
}

fn do_bootstrap() ? {
    store := TestStore{}

    mut dev := bootstrap()?
    comm := WireguardComm{dev: &dev}
    mut node := chord.bootstrap(dev.get_public_key(), store, comm)
    os.write_file("peer.json", do_genpeer()?)?

    handler := ChordHandler{node: &node}
    mut server := &http.Server{handler: handler}

    go http_server_loop(mut server)

    for {
      node.stabilize() or {
        println("stabilize() failed: ${err}")
      }

      println("${node.successor} <-> ${node.predecessor}")
      time.sleep(5*time.second)
    }
}

fn do_genpeer() ?string {
    mut dev := wireguard.new_device("sss0", true)?
    mut config := generate_peer_confg(mut dev)?
    config.remote_addr = "10.0.0.1"
    return json.encode(config)
}

fn do_join() ? {
  s := os.read_file("peer.json")?
  config := json.decode(JoinConfig, s)?
  mut dev := join(config)?

  store := TestStore{}
  comm := WireguardComm{dev: &dev}
  mut node := chord.join(dev.get_public_key(), config.remote_public_key, store, comm)?

  handler := ChordHandler{node: &node}
  mut server := &http.Server{handler: handler}

  go http_server_loop(mut server)

  for {
    node.stabilize() or {
      println("stabilize() failed: ${err}")
    }

    println("${node.successor} <-> ${node.predecessor}")
    time.sleep(5*time.second)
  }
}

fn main() {
  println(netlink.get_interface_addr(2)?)

  if os.args.len < 2 {
    println(error('insufficient command-line arguments'))
    return
  }
  action := os.args[1]

  if action == "bootstrap" {
    do_bootstrap()?
    do_genpeer()?
  } else if action == "genpeer" {
    do_genpeer()?
  } else if action == "join" {
    do_join()?
  }

  // println(k.base64())
  // peer := wireguard.new_peer("CPDlnyk0H7dgYNtmIoa1AAuD8ulJ2QMITrbzQi3aoW0=", "2.3.4.5", 43617)?
  // dev.set_peer(peer)
}
