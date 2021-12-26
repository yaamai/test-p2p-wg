module main
import net.http
import wireguard
import netlink
import log
import net

struct WireguardComm {
pub mut:
  dev &wireguard.Device
  logger log.Logger
}

fn (c WireguardComm) do_nat_traversal(id string) ? {
  self_pubkey := c.dev.get_public_key()
  self_tunnel_addr := netlink.get_interface_addr(c.dev.get_index())?
  peer_append_req := wireguard.DeviceRepr{
    name: "sss0",
    peers: [
      wireguard.PeerRepr{
        public_key: wireguard.Key{keystr: self_pubkey},
        allowed_ips: [wireguard.IpAddressCidr{IpAddress: wireguard.IpAddress{addr: self_tunnel_addr, family: net.AddrFamily.ip}, length: 32}]
      }
    ]
  }
}

fn (c WireguardComm) get_url_by_id(id string) ?string {
  ips := c.dev.get_allowed_ips_converted(generate_chord_id_from_pubkey)
  c.logger.debug("get_url_by_id(): current allowed ips by pubkey: $ips")
  if ip := ips[generate_chord_id_from_pubkey(id)] {
    return "http://${ip}:8080"
  }

  if generate_chord_id_from_pubkey(c.dev.get_public_key()) == id {
    self_ip := netlink.get_interface_addr(c.dev.get_index())?
    return "http://${self_ip}:8080"
  }

  c.do_nat_traversal(id)?
  return error('cannot communicate with ${id}')
}

fn (c WireguardComm) get_predecessor(id string) ?string {
  url := c.get_url_by_id(id)? + "/predecessor"
  text := http.get(url)?.text
  c.logger.debug("get_predecessor(): ${url} -> ${text}")

  if text.len == 0 {
    return error('')
  }
  return text
}

fn (c WireguardComm) find_successor(id string, target string) ?string {
  url := c.get_url_by_id(id)? + "/successor" + "?target=" + target
  c.logger.debug("find_successor(): ${url}")
  text := http.get(url)?.text
  c.logger.debug("    -> ${text}")

  return text
}

fn (c WireguardComm) notify(id string, data string) ? {
  url := c.get_url_by_id(id)? + "/notify"
  c.logger.debug("notify(): ${id} ${data} -> ${url}")
  http.post(url, data)?
}

fn (c WireguardComm) query(id string, key string) ?string {
  url := c.get_url_by_id(id)? + "/kvs/" + key
  c.logger.debug("query(): ${id} ${key} ${url}")
  return http.get(url)?.text
}

fn (c WireguardComm) store(id string, key string, val string) ? {
  url := c.get_url_by_id(id)? + "/kvs/" + key
  c.logger.debug("store(): ${id} ${key} ${val} -> ${url}")
  http.post(url, val)?
}
