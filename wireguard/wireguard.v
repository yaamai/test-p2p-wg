module wireguard

struct Device {
mut:
  base &C.wg_device
}

pub fn new_device(name string, allow_exists bool) ?Device {
  mut rc := -1

  rc = C.wg_add_device(name.str)
  if  rc != 0 {
    // -17 == EEXISTS
    if !allow_exists || rc != -17 {
      return error('wg_add_device() failed: ${rc}')
    }
  }

  mut dev := Device{base: &C.wg_device(0)}
  dev.sync(name)?

  return dev
}

fn (mut d Device) sync(name string) ? {
  rc := C.wg_get_device(&d.base, name.str)
  if rc != 0 {
    return error('wg_get_device() failed')
  }
}

pub fn (mut d Device) set_private_key(private_key string) {
  if private_key == "" {
    C.wg_generate_private_key(&d.base.private_key[0])
  } else {
    C.wg_key_from_base64(&d.base.private_key[0], private_key.str)
  }
  d.base.flags = d.base.flags | C.WGDEVICE_HAS_PRIVATE_KEY
}

pub fn (mut d Device) set_listen_port(port int) {
  d.base.listen_port = 21212
  d.base.flags = d.base.flags | C.WGDEVICE_HAS_LISTEN_PORT
}

pub fn (d Device) apply() ? {
  rc := C.wg_set_device(d.base)
  if rc != 0 {
    return error('wg_set_device() failed')
  }
}
/*
  private_key := []byte{len: 32}
  C.wg_generate_private_key(private_key.data)

  public_key := []byte{len: 32}
  C.wg_generate_public_key(public_key.data, private_key.data)


  unsafe {
    vmemcpy(base.public_key, public_key.data, 32)
    vmemcpy(base.private_key, private_key.data, 32)
  }
  base.flags = base.flags | C.WGDEVICE_HAS_PRIVATE_KEY

  base.listen_port = 21212
  base.flags = base.flags | C.WGDEVICE_HAS_LISTEN_PORT


  // println(C.wg_key_is_zero(base.public_key))

}
*/

fn (d Device) destroy() {
  C.wg_del_device(&d.base.name[0])
}
