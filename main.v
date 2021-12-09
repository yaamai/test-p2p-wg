module main

#flag @VROOT/wireguard.o
#flag -I @VROOT
#include "wireguard.h"
fn C.wg_list_device_names() &char
fn C.wg_get_device(dev &&C.wg_device, device_name &char) int
fn C.wg_add_device(device_name &char) int
fn C.wg_del_device(device_name &char) int
fn C.wg_key_to_base64(base64 &char, key &byte)
fn C.wg_generate_private_key(private_key &byte)
fn C.wg_generate_public_key(public_key &byte, private_key &byte)
fn C.wg_key_is_zero(key &byte) bool

struct C.wg_key {}
struct C.wg_peer {}

struct C.wg_device {
	name &char
	ifindex u32
	flags int

	public_key &byte
	private_key &byte

	fwmark u32
	listen_port u16

	first_peer &C.wg_peer
	last_peer &C.wg_peer
}

fn cstring_array_to_vstring_array(array &char) []string {
	mut result := []string{}
	mut p := unsafe { array }
	println(p)
	println(int(*(p+4)))
	println((p+4))
	for int(*p) != 0 {
		println(p)
	        s := unsafe { cstring_to_vstring(p)}
		println(s)
		println(p)
		println(s.len)
        	p = unsafe { p+s.len+1 }
		println(p)
		println(int(*p))
		result << s
	}
	return result
}

fn main() {
	C.wg_add_device(c"pwg0")
	p := C.wg_list_device_names()
	println(cstring_array_to_vstring_array(p))

	dev := &C.wg_device(0)
	ret := C.wg_get_device(&dev, c"pwg0")
	println(ret)
	println((dev))

	println(C.wg_key_is_zero(dev.public_key))

	private_key := []byte{len: 32}
	C.wg_generate_private_key(private_key.data)
	println(private_key)

	public_key := []byte{len: 32}
	C.wg_generate_public_key(public_key.data, private_key.data)
	println(public_key)

	b64 := []byte{len: 45}
	C.wg_key_to_base64(b64.data, private_key.data)
	println(b64)
	C.wg_del_device(c"pwg0")
}
