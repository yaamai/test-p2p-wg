module netlink

#flag @VMODROOT/netlink.o
#flag -I@VMODROOT
#include "netlink.h"

const rtm_newlink = u16(16)
const rtm_dellink = u16(17)
const rtm_newaddr = u16(20)
const rtm_deladdr = u16(21)
const iff_up = 1

struct C.ifinfomsg_req {}
struct C.ifaddrmsg_req {}
struct C.context {}

fn C.create_ifinfomsg_req(req &C.ifinfomsg_req, typ u16, ifindex int, flags int) int
fn C.create_ifaddrmsg_req(req &C.ifaddrmsg_req, typ u16, ifindex int, family u8, addr &byte, addrlen u8, prefix u8) int

fn C.prepare_socket(ctx &C.context) int
fn C.recv_response(ctx &C.context) int
fn C.send_request(ctx &C.context, req voidptr) int
fn C.close_socket(ctx &C.context) int
