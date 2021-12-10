module main
import os
import chord

struct Device {
  base C.wg_device
}

fn new_device(name string) ?Device {
  mut rc := -1
  rc = C.wg_add_device(name.str)
  if rc != 0 {
    return error('wg_add_device() failed')
  }

  mut base := &C.wg_device(0)
  rc = C.wg_get_device(&base, name.str)
  if rc != 0 {
    return error('wg_get_device() failed')
  }

  private_key := []byte{len: 32}
  C.wg_generate_private_key(private_key.data)

  public_key := []byte{len: 32}
  C.wg_generate_public_key(public_key.data, private_key.data)

  vmemcpy(base.public_key, public_key.data, 32)
  vmemcpy(base.private_key, private_key.data, 32)
  base.flags = base.flags | C.WGDEVICE_HAS_PRIVATE_KEY | C.WGDEVICE_HAS_PUBLIC_KEY

  base.listen_port = 21212
  base.flags = base.flags | C.WGDEVICE_HAS_LISTEN_PORT

  rc = C.wg_set_device(base)
  if rc != 0 {
    return error('wg_set_device() failed')
  }

  println(C.wg_key_is_zero(base.public_key))

  return Device{
    base: base,
  }
}

fn (d Device) destroy() {
  C.wg_del_device(d.base.name)
}

fn bootstrap() {
  // create device
  // generate keys
  // decide listen port
  // assign ip address
  C.wg_add_device(c"pwg0")

  private_key := []byte{len: 32}
  C.wg_generate_private_key(private_key.data)

  public_key := []byte{len: 32}
  C.wg_generate_public_key(public_key.data, private_key.data)
}

fn generate_join_config() {
  // setup keys
  // discover endpoint address
  // output peer connection config
  // add peer
}

fn join_peer() {
  // create device
  // read config
  // setup keys
  // add peer
}

// if full-meshed, N(N-1)/2 peers needs configured
// eg.) N=1000, 499500 ...

fn main() {
}


/*
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
*/
