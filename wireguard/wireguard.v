module wireguard

struct Device {
  base C.wg_device
}

pub fn new_device(name string) ?Device {
  mut rc := -1
  rc = C.wg_add_device(name.str)
  if rc != -17 && rc != 0 {
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

  public_key_b4 := []byte{len: 45}
  C.wg_key_to_base64(public_key_b4.data, public_key.data)
  println(public_key_b4)

  unsafe {
    vmemcpy(base.public_key, public_key.data, 32)
    vmemcpy(base.private_key, private_key.data, 32)
  }
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
