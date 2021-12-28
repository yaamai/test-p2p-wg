module main
import net.http
import wireguard
import netlink
import log
import net
import chord
import json

struct WireguardComm {
pub mut:
  dev &wireguard.Device
  logger log.Logger
  connectable string
}

fn (c WireguardComm) do_nat_traversal(node chord.Node, id string) ? {
  println("do_nat_traversal(): $id")

  self_succsessor_info_str := c.query(node, c.connectable, c.connectable)?
  self_succsessor_info := json.decode(NodeInfo, self_succsessor_info_str)?
  self_external_endpoint := self_succsessor_info.wireguard.peers.filter(generate_chord_id_from_pubkey(it.public_key.keystr) == node.id)[0].addr
  println("checking self external ip $self_external_endpoint")
  
  self_pubkey := c.dev.get_public_key()
  self_tunnel_addr := netlink.get_interface_addr(c.dev.get_index())?
  peer_append_req := wireguard.DeviceRepr{
    name: "sss0",
    peers: [
      wireguard.PeerRepr{
        addr: self_external_endpoint,
        public_key: wireguard.Key{keystr: self_pubkey},
        allowed_ips: [wireguard.IpAddressCidr{IpAddress: wireguard.IpAddress{addr: self_tunnel_addr, family: net.AddrFamily.ip}, length: 32}],
        persistent_keepalive_interval: 5,
      }
    ]
  }
  c.store(node, c.connectable, id, json.encode(peer_append_req))?


  target_peer_info_str := c.query(node, c.connectable, id)?

  target_peer_info := json.decode(NodeInfo, target_peer_info_str)?
  println(target_peer_info)

  target_peer_successor_info_str := c.query(node, c.connectable, target_peer_info.successor)?
  target_peer_successor_info := json.decode(NodeInfo, target_peer_successor_info_str)?
  println(target_peer_successor_info)

  for p in target_peer_successor_info.wireguard.peers {
    t := generate_chord_id_from_pubkey(p.public_key.keystr)
    println("$id == $t ${id == t}")
  }
  candidate_peers := target_peer_successor_info.wireguard.peers.filter(generate_chord_id_from_pubkey(it.public_key.keystr) == id)
  if candidate_peers.len != 1 {
    return error('public key conflict?')
  }

  target_endpoint := candidate_peers[0].addr
  target_public_key := candidate_peers[0].public_key
  candidate_target_tunnel_addr := candidate_peers[0].allowed_ips.filter(it.length == 32)
  if candidate_target_tunnel_addr.len != 1 {
    return error("cannot determine target tunnel ip with target's successor")
  }
  target_tunnel_addr := candidate_target_tunnel_addr[0]

  println("$target_endpoint, $target_tunnel_addr")
  mut dev := wireguard.open_device_repr("sss0")?
  dev.peers << wireguard.PeerRepr{
    public_key: target_public_key,
    addr: target_endpoint,
    allowed_ips: [target_tunnel_addr],
  }
  dev.apply()?

  // println(node.find_successor(id)?)

  // node.set(id, json.encode(peer_append_req))?
  // successor_info := node.query(node.successor)?
  // println("do_nat_traversal(): successor_info: $successor_info")
}

fn (c WireguardComm) get_url_by_id(node chord.Node, id string) ?string {
  ips := c.dev.get_allowed_ips_converted(generate_chord_id_from_pubkey)
  c.logger.debug("get_url_by_id(): $id, current allowed ips by pubkey: $ips")
  if ip := ips[generate_chord_id_from_pubkey(id)] {
    return "http://${ip}:8080"
  }

  if generate_chord_id_from_pubkey(c.dev.get_public_key()) == id {
    self_ip := netlink.get_interface_addr(c.dev.get_index())?
    return "http://${self_ip}:8080"
  }

  // TODO: if incorrect peer added, this line never reached anymore
  c.do_nat_traversal(node, id) or {
    println(err)
  }
  return error('cannot communicate with ${id}')
}

fn (mut c WireguardComm) get_predecessor(node chord.Node, id string) ?string {
  url := c.get_url_by_id(node, id)? + "/predecessor"
  text := http.get(url)?.text
  c.logger.debug("get_predecessor(): ${url} -> ${text}")

  if text.len == 0 {
    return error('')
  }
  c.connectable = id
  return text
}

fn (c WireguardComm) find_successor(node chord.Node, id string, target string) ?string {
  url := c.get_url_by_id(node, id)? + "/successor" + "?target=" + target
  c.logger.debug("find_successor(): ${url}")
  text := http.get(url)?.text
  c.logger.debug("    -> ${text}")

  return text
}

fn (c WireguardComm) notify(node chord.Node, id string, data string) ? {
  url := c.get_url_by_id(node, id)? + "/notify"
  c.logger.debug("notify(): ${id} ${data} -> ${url}")
  http.post(url, data)?
}

fn (c WireguardComm) query(node chord.Node, id string, key string) ?string {
  url := c.get_url_by_id(node, id)? + "/kvs/" + key
  c.logger.debug("query(): ${id} ${key} ${url}")
  return http.get(url)?.text
}

fn (c WireguardComm) store(node chord.Node, id string, key string, val string) ? {
  url := c.get_url_by_id(node, id)? + "/kvs/" + key
  c.logger.debug("store(): ${id} ${key} ${val} -> ${url}")
  http.post(url, val)?
}
