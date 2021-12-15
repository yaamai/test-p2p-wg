module wireguard
import net

struct Peer {
mut:
  base &C.wg_peer
}

pub fn new_peer(key string) ?Peer {
  mut peer := C.wg_peer{
    flags: C.WGPEER_HAS_PUBLIC_KEY | C.WGPEER_REPLACE_ALLOWEDIPS,
    first_allowedip: 0,
    last_allowedip: 0,
    next_peer: 0,
  }
  // vlang's C-FFI has bug to initialize union member in struct declaration.
  // if move below assignment at struct declaration will override addr4 with addr6...
  C.inet_pton(net.AddrFamily.ip, c"1.2.3.4", &peer.addr4.sin_addr)
  peer.addr4.sin_family = u16(net.AddrFamily.ip)
  peer.addr4.sin_port = u16(C.htons(11134))
  println(peer)
  C.wg_key_from_base64(&peer.public_key[0], key.str)

/*
  peer.public_key = 
struct C.wg_peer {
    flags int
    public_key [wg_key_size]byte
    preshared_key [wg_key_size]byte
    addr &C.sockaddr
    addr4 &C.sockaddr_in
    addr6 &C.sockaddr_in6
    last_handshake_time C.timespec64
    rx_bytes u64
    tx_bytes u64
    persistent_keepalive_interval u16
    first_allowedip &C.wg_allowedip
    last_allowedip &C.wg_allowedip
    next_peer &C.wg_peer
}
*/

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
  dev.sync(name)?

  return dev
}

fn (mut d Device) sync(name string) ? {
  rc := C.wg_get_device(&d.base, name.str)
  if rc != 0 {
    return error('wg_get_device() failed')
  }
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
  d.base.listen_port = 21212
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

/*
  private_key := []byte{len: 32}
  C.wg_generate_private_key(private_key.data)

  public_key := []byte{len: 32}
  C.wg_generate_public_key(public_key.data, private_key.data)


  unsafe {
    vmemcpy(base.public_key, public_key.data, 32)
    vmemcpy(base.private_key, private_key.data, 32)
  }
  base.flags = base.flags | C.WGDEVICE_HAS_PRIVATE_KEY

  base.listen_port = 21212
  base.flags = base.flags | C.WGDEVICE_HAS_LISTEN_PORT


  // println(C.wg_key_is_zero(base.public_key))

}
*/

fn (d Device) destroy() {
  C.wg_del_device(&d.base.name[0])
}
