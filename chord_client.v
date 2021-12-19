module main
import net.http
import wireguard
import netlink
import log

struct WireguardComm {
pub mut:
  dev &wireguard.Device
  logger log.Logger
}

fn (c WireguardComm) get_url_by_id(id string) ?string {
  ips := c.dev.get_allowed_ips()
  if ip := ips[id] {
    return "http://${ip}:8080"
  }

  self_ip := netlink.get_interface_addr(c.dev.get_index())?
  return "http://${self_ip}:8080"
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
  text := http.get(url)?.text
  c.logger.debug("find_successor(): ${url} -> ${text}")

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
  url := c.get_url_by_id(id)? + "/kvs" + key
  c.logger.debug("query(): ${id} ${key} ${val} -> ${url}")
  http.post(url, val)?
}
