module main
import wireguard
import os
import netlink
import chord
import json
import net.http
import time

const default_device_name = "sss0"
const default_device_listen_port = 43617


fn main() {
  if os.args.len < 2 {
    println(error('insufficient command-line arguments'))
    return
  }

  /*
  case 1: init[A] -> gen-peer[A] -> join[B]
  case 2: init[A] -> init[B] -> gen-peer[A] -> join[B]
  */
  match os.args[1] {
    "init" { do_init()? }
    "gen-peer" { do_gen_peer()? }
    "join" { do_join()? }
    else { return }
  }
}

fn do_init() ? {
  dev := wireguard.new_device(name: default_device_name, listen_port: default_device_listen_port)?

  netlink.set_interface_up(dev.get_index())?
  netlink.add_interface_addr(dev.get_index(), "10.163.0.1", 32)?
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

fn do_gen_peer() ?JoinConfig {
  // should be random or network unique
  peer_key := wireguard.new_key()?
  peer_addr := "10.163.0.2"

  mut dev := wireguard.open_device(default_device_name)?

  peer := wireguard.new_peer(key: peer_key.public()?.str(), allowed_ip: peer_addr)?
  dev.set_peer(peer)
  netlink.add_if_route(peer_addr, 32, dev.get_index(), true)?

  return JoinConfig {
    private_key: peer_key.str(),
    tunnel_addr: peer_addr,
    // TODO: query to netlink? or hold wireguard.Device or generate ip from id
    remote_tunnel_addr: "10.163.0.1",
    remote_port: 43617,
    remote_public_key: dev.get_public_key(),
  }
}

fn do_join() ? {
  s := os.read_file("peer.json")?
  mut config := json.decode(JoinConfig, s)?
  // TODO
  config.remote_addr = "10.0.0.1"

  mut dev := wireguard.new_device(private_key: config.private_key, name: default_device_name, listen_port: default_device_listen_port)?
  peer := wireguard.new_peer(key: config.remote_public_key, addr: config.remote_addr, port: config.remote_port, allowed_ip: config.remote_tunnel_addr)?
  dev.set_peer(peer)

  netlink.set_interface_up(dev.get_index())?
  netlink.add_interface_addr(dev.get_index(), config.tunnel_addr, 32)?
  netlink.add_if_route(config.remote_tunnel_addr, 32, dev.get_index(), true)?
}

fn do_serve() ? {
    store := TestStore{}

    mut dev := wireguard.open_device(default_device_name)?
    comm := WireguardComm{dev: &dev}
    mut node := chord.bootstrap(dev.get_public_key(), store, comm)
    // os.write_file("peer.json", do_genpeer()?)?

    handler := ChordHandler{node: &node}
    mut server := &http.Server{handler: handler}

    threads := [
      go http_server_loop(mut server)
      go stabilize_loop(mut &node)
    ]
    threads.wait()
}

fn http_server_loop(mut server http.Server) {
    server.listen_and_serve() or {
      return
    }
}

fn stabilize_loop(mut node chord.Node) {
    for {
      node.stabilize() or {
        println("stabilize() failed: ${err}")
      }

      println("${node.successor} <-> ${node.predecessor}")
      time.sleep(5*time.second)
    }
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

