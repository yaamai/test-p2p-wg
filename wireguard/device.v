module wireguard
import net

struct Device {
mut:
  base &C.wg_device
}

[params]
struct DeviceConfig {
  name string
  private_key string
  public_key string
  listen_port int
  allow_exists bool
}

pub fn new_device(p DeviceConfig) ?Device {
  mut rc := -1

  rc = C.wg_add_device(p.name.str)
  if  rc != 0 {
    // -17 == EEXISTS
    if !p.allow_exists || rc != -17 {
      return error('wg_add_device() failed: ${rc}')
    }
  }

  mut dev := Device{base: &C.wg_device(0)}
  rc = C.wg_get_device(&dev.base, p.name.str)
  if rc != 0 {
    return error('wg_get_device() failed')
  }

  // if p.private_key != "" { dev.set_private_key(p.private_key)? }
  // if p.public_key != "" { dev.set_public_key(p.public_key)? }




  return dev
}

pub fn (mut d Device) set_private_key(private_key string) ? {
  if private_key == "" {
    C.wg_generate_private_key(&d.base.private_key[0])
  } else {
    C.wg_key_from_base64(&d.base.private_key[0], private_key.str)
  }
  d.base.flags = d.base.flags | C.WGDEVICE_HAS_PRIVATE_KEY
}

pub fn (mut d Device) set_public_key(public_key string) {
  C.wg_key_from_base64(&d.base.public_key[0], public_key.str)
  d.base.flags = d.base.flags | C.WGDEVICE_HAS_PUBLIC_KEY
}

pub fn (mut d Device) set_listen_port(port int) {
  d.base.listen_port = u16(port)
  d.base.flags = d.base.flags | C.WGDEVICE_HAS_LISTEN_PORT
}

pub fn (d Device) apply() ? {
  rc := C.wg_set_device(d.base)
  if rc != 0 {
    return error('wg_set_device() failed')
  }
}

fn (d Device) sync() ? {
  rc := C.wg_get_device(&d.base, &d.base.name[0])
  if rc != 0 {
    return error('wg_get_device() failed')
  }
}

pub fn (d Device) get_allowed_ips() map[string]string {
  mut result := map[string]string{}
  b := []byte{len: 15}
  public := []byte{len: 45}

  for peer := d.base.first_peer; peer != 0; peer = peer.next_peer {
    for ip := peer.first_allowedip; ip != 0; ip = ip.next_allowedip {
      C.inet_ntop(net.AddrFamily.ip, &ip.ip4, b.data, b.len)
      C.wg_key_to_base64(public.data, &peer.public_key[0])
      result[string(public)] = string(b)
    }
  }
  return result
}

pub fn (d Device) get_index() u32 {
  return d.base.ifindex
}

pub fn (d Device) get_public_key() string {
  public := []byte{len: 45}
  C.wg_key_to_base64(public.data, &d.base.public_key[0])
  return string(public)
}

pub fn (mut d Device) set_peer(peer Peer) {
  d.base.first_peer = peer.base
  d.base.last_peer = peer.base
  d.base.flags = d.base.flags | C.WGDEVICE_REPLACE_PEERS
}

fn (d Device) destroy() {
  C.wg_del_device(&d.base.name[0])
}

