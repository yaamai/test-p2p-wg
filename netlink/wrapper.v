module netlink

pub fn set_interface_up(ifindex u32) ? {
  req := C.ifinfomsg_req{}
  ctx := C.context{}
  C.create_ifinfomsg_req(&req, rtm_newlink, ifindex, iff_up)

  C.prepare_socket(&ctx)
  C.send_request(&ctx, &req)
  C.close_socket(&ctx)
}

/*
proc nl_add_address*(ifindex: uint, address: IpAddress, prefix: int): int =
  var
    rc: cint = 0
    req: ifaddrmsg_req
    ctx: context

  let ifidx = cast[cint](ifindex)
  let typ = cast[uint16](RTM_NEWADDR)
  let family = cast[uint8](if address.family == IpAddressFamily.IPv4: AF_INET else: AF_INET6)
  let ad = cast[ptr UncheckedArray[uint8]](unsafeAddr address.address_v4)
  let p = cast[uint8](prefix)
  rc = create_ifaddrmsg_req(addr req, typ, ifidx, family, ad, 4, p)

  rc = prepare_socket(addr ctx)
  rc = send_request(addr ctx, addr req)
  rc = close_socket(addr ctx)
*/
