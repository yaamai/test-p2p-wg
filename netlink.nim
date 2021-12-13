{.compile: "netlink.c".}

let RTM_NEWLINK {.importc, nodecl.}: cint
let IFF_UP {.importc, nodecl.}: cint

type
  context {.importc: "context".} = object
  ifaddrmsg_req {.importc: "ifaddrmsg_req".} = object
  ifinfomsg_req {.header: "netlink.h", importc: "ifinfomsg_req".} = object
  request = ifaddrmsg_req or ifinfomsg_req

proc prepare_socket(ctx: ptr context): cint {.importc: "prepare_socket"}
proc recv_response(ctx: ptr context): cint {.importc: "recv_response"}
proc send_request(ctx: ptr context, req: pointer): cint {.importc: "send_request"}
proc close_socket(ctx: ptr context): cint {.importc: "close_socket"}

proc create_ifaddrmsg_req(
  req: ptr ifaddrmsg_req,
  typ: uint16,
  ifindex: cint,
  family: uint8,
  address: cstring,
  addrlen: uint8,
  prefix: uint8
): cint {.importc: "create_ifaddrmsg_req"}

proc create_ifinfomsg_req(
  req: ptr ifinfomsg_req,
  typ: uint16,
  ifindex: cint,
  flags: cuint,
): cint {.importc: "create_ifinfomsg_req"}

proc nl_set_interface_up*(ifindex: uint): int =
  var
    rc: cint = 0
    req: ifinfomsg_req
    ctx: context

  rc = create_ifinfomsg_req(addr req, cast[uint16](RTM_NEWLINK), cast[cint](ifindex), cast[uint8](IFF_UP))
  rc = prepare_socket(addr ctx)
  rc = send_request(addr ctx, addr req)
  rc = close_socket(addr ctx)
