module netlink
import net

pub fn add_if_route(addr string, prefix int, ifindex u32, allow_exists bool) ? {
  req := C.rtmsg_req{}
  ctx := C.context{}

  addr_buf := []byte{len: 4}
  mut rc := C.inet_pton(net.AddrFamily.ip, addr.str, &addr_buf[0])
  if rc < 0 {
    return error('inte_pton() failed: ${rc}')
  }

  family := byte(net.AddrFamily.ip)
  C.create_rtmsg_req(&req, rtm_newroute, family, &addr_buf[0], 4, prefix, ifindex)

  C.prepare_socket(&ctx)
  C.send_request(&ctx, &req)
  rc = C.recv_response(&ctx)
  if rc < 0 {
    // -17 == EEXISTS
    if !allow_exists || rc != -17 {
      return error('receive failed response with netlink: ${rc}')
    }
  }
  C.close_socket(&ctx)
}

pub fn set_interface_up(ifindex u32) ? {
  req := C.ifinfomsg_req{}
  ctx := C.context{}
  C.create_ifinfomsg_req(&req, rtm_newlink, ifindex, iff_up)

  C.prepare_socket(&ctx)
  C.send_request(&ctx, &req)
  C.close_socket(&ctx)
}

pub fn add_interface_addr(ifindex u32, addr string, prefix int) ? {
  req := C.ifaddrmsg_req{}
  ctx := C.context{}

  addr_buf := []byte{len: 4}
  rc := C.inet_pton(net.AddrFamily.ip, addr.str, &addr_buf[0])
  if rc < 0 {
    return error('inte_pton() failed: ${rc}')
  }

  family := byte(net.AddrFamily.ip)
  C.create_ifaddrmsg_req(&req, rtm_newaddr, ifindex, family, &addr_buf[0], 4, prefix)

  C.prepare_socket(&ctx)
  C.send_request(&ctx, &req)
  C.close_socket(&ctx)
}
