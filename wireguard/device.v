module wireguard
import net

struct AllowedIpRepr {
  family u16
  addr string
  length u8
}

struct PeerRepr {
  flags int
  public_key Key
  family u16
  addr string
  allowed_ips []AllowedIpRepr
}

struct DeviceRepr {
  name string
  flags int
  public_key Key
  private_key Key
  listen_port int
  peers []PeerRepr
}
[params]
pub struct NewPeerReprConfig {
  ptr &C.wg_peer = 0
}

pub fn new_peer_repr(p NewPeerReprConfig) ?PeerRepr {
  return PeerRepr{
    flags: p.ptr.flags,
    public_key: new_key(ptr: &p.ptr.public_key[0])?,
  }
}

pub fn open_device_repr(name string) ?DeviceRepr {
  base := &C.wg_device{}
  rc := C.wg_get_device(&base, name.str)
  if rc != 0 {
    return error('wg_get_device() failed')
  }

  mut peers := []PeerRepr{}
  for peer := base.first_peer; peer != 0; peer = peer.next_peer {
    p := unsafe { new_peer_repr(ptr: peer) }
    peers << p
  }

  return DeviceRepr {
    name: unsafe { cstring_to_vstring(&base.name[0]) },
    flags: base.flags,
    public_key: new_key(ptr: &base.public_key[0], is_pub: true)?,
    private_key: new_key(ptr: &base.private_key[0])?,
    listen_port: base.listen_port,
    peers: peers,
  }
}

struct Device {
mut:
  base &C.wg_device
}

[params]
pub struct DeviceConfig {
  name string
  private_key string
  listen_port int
  allow_exists bool
}

pub fn open_device(name string) ?Device {
  mut dev := Device{base: &C.wg_device(0)}
  rc := C.wg_get_device(&dev.base, name.str)
  if rc != 0 {
    return error('wg_get_device() failed')
  }
  return dev
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

  key := new_key(keystr: p.private_key)?
  dev.base.private_key = key.key
  dev.base.public_key = key.public()?.key
  dev.base.flags = C.WGDEVICE_HAS_PRIVATE_KEY | C.WGDEVICE_HAS_PUBLIC_KEY
  if p.listen_port != 0 {
    dev.base.listen_port = u16(p.listen_port)
    dev.base.flags |= C.WGDEVICE_HAS_LISTEN_PORT
  }

  rc = C.wg_set_device(dev.base)
  if rc != 0 {
    return error('wg_set_device() failed')
  }

  return dev
}

pub fn (d Device) get_allowed_ips_converted(f fn(string) string) map[string]string {
  mut result := map[string]string{}
  b := []byte{len: 15}
  public := []byte{len: 45}

  for peer := d.base.first_peer; peer != 0; peer = peer.next_peer {
    for ip := peer.first_allowedip; ip != 0; ip = ip.next_allowedip {
      C.inet_ntop(net.AddrFamily.ip, &ip.ip4, b.data, b.len)
      C.wg_key_to_base64(public.data, &peer.public_key[0])
      result[f(string(public))] = string(b)
    }
  }
  return result
}

fn s(s string) string { return s }
pub fn (d Device) get_allowed_ips() map[string]string {
  return d.get_allowed_ips_converted(s)
}

pub fn (d Device) get_name() string {
  return unsafe { cstring_to_vstring(&d.base.name[0]) }
}

pub fn (d Device) get_index() u32 {
  return d.base.ifindex
}

pub fn (d Device) get_public_key() string {
  public := []byte{len: 45}
  C.wg_key_to_base64(public.data, &d.base.public_key[0])
  return string(public)
}

pub fn (mut d Device) set_peer(peer Peer) ? {
  d.base.first_peer = peer.base
  d.base.last_peer = peer.base
  d.base.flags = C.WGDEVICE_REPLACE_PEERS

  rc := C.wg_set_device(d.base)
  if rc != 0 {
    return error('wg_set_device() failed')
  }
}

fn (d Device) destroy() {
  C.wg_del_device(&d.base.name[0])
}

