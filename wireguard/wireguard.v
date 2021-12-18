module wireguard
import net

struct Key {
  private_key [32]byte
  public_key [32]byte
}

pub fn new_key() ?Key {
  k := Key{}

  C.wg_generate_private_key(&k.private_key[0])
  C.wg_generate_public_key(&k.public_key[0], &k.private_key[0])

  return k
}

pub fn (k Key) base64() (string, string) {
  public := []byte{len: 45}
  private := []byte{len: 45}
  C.wg_key_to_base64(public.data, &k.public_key[0])
  C.wg_key_to_base64(private.data, &k.private_key[0])

  return string(public), string(private)
}

// can't use ?Type in sturct literal argument
// error: incompatible types when initializing type ‘unsigned char’ using type ‘string’
// Option_wireguard__Peer _t3 = wireguard__new_peer((wireguard__PeerConfig){.key = p.remote_public_key,.addr = p.remote_addr,.port = p.remote_port,.allowed_ip = {EMPTY_STRUCT_INITIALIZATION},.allowed_ip_len = 32,});
[params]
pub struct PeerConfig {
  key string
  addr string
  port int
  allowed_ip string
  allowed_ip_len int = 32
}

struct Peer {
mut:
  base &C.wg_peer
}

pub fn new_peer(p PeerConfig) ?Peer {
  mut allowed_ip := C.wg_allowedip{
    family: u16(net.AddrFamily.ip),
    cidr: p.allowed_ip_len,
    next_allowedip: 0,
  }

  if p.allowed_ip != ""{
    mut rc := C.inet_pton(net.AddrFamily.ip, p.allowed_ip.str, &allowed_ip.ip4)
    if rc < 0 {
      return error('inte_pton() failed: ${rc}')
    }
  }

  mut peer := C.wg_peer{
    flags: C.WGPEER_HAS_PUBLIC_KEY | C.WGPEER_REPLACE_ALLOWEDIPS,
    first_allowedip: &allowed_ip,
    last_allowedip: &allowed_ip,
    next_peer: 0,
  }

  if p.addr != "" && p.port != 0 {
    // vlang's C-FFI has bug to initialize union member in struct declaration.
    // if move below assignment at struct declaration will override addr4 with addr6...
    rc := C.inet_pton(net.AddrFamily.ip, p.addr.str, &peer.addr4.sin_addr)
    if rc < 0 {
      return error('inte_pton() failed: ${rc}')
    }
    peer.addr4.sin_family = u16(net.AddrFamily.ip)
    peer.addr4.sin_port = u16(C.htons(p.port))
  }
  C.wg_key_from_base64(&peer.public_key[0], p.key.str)

  return Peer{base: &peer}
}

struct Device {
mut:
  base &C.wg_device
}

pub fn new_device(name string, allow_exists bool) ?Device {
  mut rc := -1

  rc = C.wg_add_device(name.str)
  if  rc != 0 {
    // -17 == EEXISTS
    if !allow_exists || rc != -17 {
      return error('wg_add_device() failed: ${rc}')
    }
  }

  mut dev := Device{base: &C.wg_device(0)}
  rc = C.wg_get_device(&dev.base, name.str)
  if rc != 0 {
    return error('wg_get_device() failed')
  }

  return dev
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

pub fn (mut d Device) set_public_key(public_key string) {
  C.wg_key_from_base64(&d.base.public_key[0], public_key.str)
  d.base.flags = d.base.flags | C.WGDEVICE_HAS_PUBLIC_KEY
}

pub fn (mut d Device) set_private_key(private_key string) {
  if private_key == "" {
    C.wg_generate_private_key(&d.base.private_key[0])
  } else {
    C.wg_key_from_base64(&d.base.private_key[0], private_key.str)
  }
  d.base.flags = d.base.flags | C.WGDEVICE_HAS_PRIVATE_KEY
}

pub fn (mut d Device) set_listen_port(port int) {
  d.base.listen_port = u16(port)
  d.base.flags = d.base.flags | C.WGDEVICE_HAS_LISTEN_PORT
}

pub fn (mut d Device) set_peer(peer Peer) {
  d.base.first_peer = peer.base
  d.base.last_peer = peer.base
  d.base.flags = d.base.flags | C.WGDEVICE_REPLACE_PEERS
}

pub fn (d Device) apply() ? {
  rc := C.wg_set_device(d.base)
  if rc != 0 {
    return error('wg_set_device() failed')
  }
}

fn (d Device) destroy() {
  C.wg_del_device(&d.base.name[0])
}
