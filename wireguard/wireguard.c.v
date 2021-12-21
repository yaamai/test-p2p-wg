module wireguard

#flag @VMODROOT/wireguard.o
#flag -I@VMODROOT
#include "wireguard.h"

const ifnamesiz = 16
const wg_key_size = 32
const af_inet = 2
const af_inet6 = 10

fn C.wg_list_device_names() &char
fn C.wg_get_device(dev &&C.wg_device, device_name &char) int
fn C.wg_set_device(dev &C.wg_device) int
fn C.wg_add_device(device_name &char) int
fn C.wg_del_device(device_name &char) int
fn C.wg_key_to_base64(base64 &char, key &byte)
fn C.wg_key_from_base64(key &byte, base64 &char) int
fn C.wg_generate_private_key(private_key &byte)
fn C.wg_generate_public_key(public_key &byte, private_key &byte)
fn C.wg_key_is_zero(key &byte) bool

struct C.wg_key {}
struct C.timespec64 {}
struct C.in_addr {
mut:
	s_addr int
}
struct C.in6_addr {}
struct C.wg_allowedip {
	family u16
	ip4 C.in_addr
	ip6 C.in6_addr
	cidr u8
	next_allowedip &C.wg_allowedip
}
struct C.sockaddr_in {
mut:
	sin_family int
	sin_port   int
	sin_addr   C.in_addr
}
struct C.sockaddr_in6 {
	sin6_family u16
	sin6_port   u16
	sin6_addr   C.in6_addr
    sin6_scope_id u32
}
struct C.wg_peer {
mut:
    flags int
    public_key [wg_key_size]byte
    preshared_key [wg_key_size]byte
    addr4 C.sockaddr_in
    addr6 C.sockaddr_in6
    last_handshake_time C.timespec64
    rx_bytes u64
    tx_bytes u64
    persistent_keepalive_interval u16
    first_allowedip &C.wg_allowedip
    last_allowedip &C.wg_allowedip
    next_peer &C.wg_peer
}

struct C.wg_device {
mut:
	name [ifnamesiz]byte
	ifindex u32
	flags int
	public_key [wg_key_size]byte
	private_key [wg_key_size]byte
	fwmark u32
	listen_port u16
	first_peer &C.wg_peer = 0
	last_peer &C.wg_peer = 0
}

/*
fn cstring_array_to_vstring_array(array &char) []string {
	mut result := []string{}
	mut p := unsafe { array }
	for int(*p) != 0 {
        s := unsafe { cstring_to_vstring(p)}
       	p = unsafe { p+s.len+1 }
		result << s
	}
	return result
}
*/

