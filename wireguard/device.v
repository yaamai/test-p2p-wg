module wireguard
import net

fn inet_ntop(family net.AddrFamily, ptr voidptr) string {
  buffer_len := if family == net.AddrFamily.ip { C.INET_ADDRSTRLEN } else { C.INET6_ADDRSTRLEN }
  buffer := []byte{len: buffer_len}
  C.inet_ntop(family, ptr, buffer.data, buffer.len)

  return unsafe { cstring_to_vstring(buffer.data) }
}

fn inet_pton(family net.AddrFamily, addr string, ptr voidptr) ? {
  rc := C.inet_pton(family, addr.str, ptr)
  if rc < 0 {
    return error('inte_pton() failed: ${rc}')
  }
}


pub struct IpAddress {
  family net.AddrFamily
  addr string
}

[params]
struct NewIpAddressConfig {
  family net.AddrFamily
  ptr voidptr
}

fn new_ipaddress(p NewIpAddressConfig) ?IpAddress {
  return IpAddress {
    family: p.family,
    addr: inet_ntop(p.family, p.ptr)
  }
}

fn (addr IpAddress) as_in_addr(mut out &C.in_addr) ? {
  inet_pton(addr.family, addr.addr, &out)?
}

struct IpSocketAddress {
  IpAddress
  port u16
}

fn (addr IpSocketAddress) as_sockaddr_in(mut out &C.sockaddr_in) ? {
  if addr.family != net.AddrFamily.ip {
    println('invalid address family')
    // TODO: may require zero erase sockaddr
    return
  }

  out.sin_family = u16(addr.family)
  out.sin_port = u16(C.htons(addr.port))
  inet_pton(addr.family, addr.addr, &out.sin_addr)?
}

[params]
struct NewIpSocketAddressConfig {
  sockaddr_ptr &C.sockaddr
}

fn new_ip_socket_address(p NewIpSocketAddressConfig) ?IpSocketAddress {
  if p.sockaddr_ptr.sa_family == u16(net.AddrFamily.ip) {
    sa := C.sockaddr_in{}
	unsafe { vmemcpy(&sa, p.sockaddr_ptr, int(sizeof(C.sockaddr_in))) }

    return IpSocketAddress {
      family: net.AddrFamily.ip,
      addr: inet_ntop(net.AddrFamily.ip, &sa.sin_addr),
      port: u16(C.ntohs(sa.sin_port)),
    }
  } else {
    sa := C.sockaddr_in6{}
	unsafe { vmemcpy(&sa, p.sockaddr_ptr, int(sizeof(C.sockaddr_in6))) }

    return IpSocketAddress {
      family: net.AddrFamily.ip,
      addr: inet_ntop(net.AddrFamily.ip, &sa.sin6_addr),
      port: u16(C.ntohs(sa.sin6_port)),
    }
  }
}

/*
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
*/

pub struct IpAddressCidr {
pub:
  IpAddress
  length u8
}

fn (cidr IpAddressCidr) as_wg_allowed_ip(mut out &C.wg_allowedip) ? {
  out.family = u16(cidr.family)
  out.cidr = cidr.length
  cidr.IpAddress.as_in_addr(mut &out.ip4)?
}

[params]
struct NewIpAddressCidrConfig {
  allowed_ip_ptr &C.wg_allowedip
}

fn new_ip_address_cidr(p NewIpAddressCidrConfig) ?IpAddressCidr {
  if p.allowed_ip_ptr.family == u16(net.AddrFamily.ip) {
    return IpAddressCidr {
      family: net.AddrFamily.ip,
      addr: inet_ntop(net.AddrFamily.ip, &p.allowed_ip_ptr.ip4),
      length: p.allowed_ip_ptr.cidr,
    }
  } else {
    return IpAddressCidr {
      family: net.AddrFamily.ip6,
      addr: inet_ntop(net.AddrFamily.ip6, &p.allowed_ip_ptr.ip6),
      length: p.allowed_ip_ptr.cidr,
    }
  }
}

pub struct PeerRepr {
pub:
  flags int
  public_key Key
  addr IpSocketAddress
  allowed_ips []IpAddressCidr
  persistent_keepalive_interval int
}

fn (peer PeerRepr) as_wg_peer(mut out &C.wg_peer) ? {
  // println("as_wg_peer $out")
  // println(peer.flags)
  out.flags = peer.flags
  if peer.persistent_keepalive_interval != 0 {
    out.persistent_keepalive_interval = u16(peer.persistent_keepalive_interval)
    out.flags |= C.WGPEER_HAS_PERSISTENT_KEEPALIVE_INTERVAL
  }

  // vlang can't return and copy fixed-sized-array
  peer.public_key.as_wg_key(mut &out.public_key[0])?
  // println("as_wg_peer as_wg_key $out.public_key")
  peer.addr.as_sockaddr_in(mut &out.addr4)?

  mut prev := out.first_allowedip
  for a in peer.allowed_ips {
    mut aip := C.wg_allowedip{next_allowedip: 0}
    a.as_wg_allowed_ip(mut &aip)?
    if out.first_allowedip == 0 {
      out.first_allowedip = &aip
    }
    if prev != 0 {
      prev.next_allowedip = &aip
    }
    prev = &aip
  }
  out.last_allowedip = prev
}

pub struct DeviceRepr {
pub:
  name string
pub mut:
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
  mut addrs := []IpAddressCidr{}
  for ip := p.ptr.first_allowedip; ip != 0; ip = ip.next_allowedip {
    addr := unsafe { new_ip_address_cidr(allowed_ip_ptr: ip) }
    addrs << addr
  }

  return PeerRepr{
    flags: p.ptr.flags,
    public_key: new_key(ptr: &p.ptr.public_key[0])?,
    addr: new_ip_socket_address(sockaddr_ptr: &p.ptr.addr)?,
    allowed_ips: addrs,
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

pub fn (d DeviceRepr) as_wg_device(mut out &C.wg_device) ? {
  unsafe { vmemcpy(&out.name, d.name.str, d.name.len) }
  // currently only append peer
  mut prev := out.first_peer
  for p in d.peers {
    mut peer := C.wg_peer{}
    p.as_wg_peer(mut &peer)?
    if out.first_peer == 0 {
      out.first_peer = &peer
    }
    if prev != 0 {
      prev.next_peer = &peer
    }
    prev = &peer
  }
  out.last_peer = prev
}

pub fn (d DeviceRepr) apply() ? {
  mut base := C.wg_device{}
  d.as_wg_device(mut &base)?

  rc := C.wg_set_device(&base)
  if rc != 0 {
    return error('wg_set_device() failed ${rc}')
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

  rc := C.wg_get_device(&d.base, &d.base.name[0])
  if rc != 0 {
    println('wg_get_device() failed')
  }

  for peer := d.base.first_peer; peer != 0; peer = peer.next_peer {
    for ip := peer.first_allowedip; ip != 0; ip = ip.next_allowedip {
      C.inet_ntop(net.AddrFamily.ip, &ip.ip4, b.data, b.len)
      C.wg_key_to_base64(public.data, &peer.public_key[0])
      result[f(string(public))] = string(b).clone()
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
  // d.base.flags = C.WGDEVICE_REPLACE_PEERS

  rc := C.wg_set_device(d.base)
  if rc != 0 {
    return error('wg_set_device() failed')
  }
}

fn (d Device) destroy() {
  C.wg_del_device(&d.base.name[0])
}

