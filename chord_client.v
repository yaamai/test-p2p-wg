module main
import net.http
import wireguard
import netlink

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
