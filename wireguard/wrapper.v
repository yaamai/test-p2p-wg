module wireguard
import net

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
