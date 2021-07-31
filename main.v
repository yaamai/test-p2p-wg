module main

#flag @VROOT/wireguard.o
fn C.wg_list_device_names() &char
fn C.wg_get_device(wg_device &voidptr, device_name &char) int

fn cstring_array_to_vstring_array(array &char) []string {
	mut result := []string{}
	mut p := array
	for int(*p) != 0 {
	        s := unsafe { cstring_to_vstring(p)}
        	p = unsafe { p+s.len+1 }
		result << s
	}
	return result
}

fn main() {
	p := C.wg_list_device_names()
	println(cstring_array_to_vstring_array(p))

	C.wg_get_device("wg0")
}
