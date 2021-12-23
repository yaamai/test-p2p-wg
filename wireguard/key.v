module wireguard

struct Key {
pub mut:
  key [32]byte [skip]
  keystr string
}

[params]
pub struct KeyConfig {
  keystr string
  is_pub bool
  ptr &byte = 0
}

pub fn new_key(p KeyConfig) ?Key {
  mut k := Key{}

  if p.ptr == 0 && p.keystr != "" {
    k.keystr = p.keystr
    rc := C.wg_key_from_base64(&k.key, p.keystr.str)
    if rc < 0 {
      return error("wg_key_from_base64() failed: ${rc}")
    }
    return k
  }

  if p.ptr == 0 && p.keystr == "" {
    if p.is_pub {
      private := [32]byte{}
      C.wg_generate_private_key(&private)
      C.wg_generate_public_key(&k.key, &private)
    } else {
      C.wg_generate_private_key(&k.key)
    }
  } else if p.ptr != 0 {
    unsafe { vmemcpy(&k.key, p.ptr, 32) }
  }

  buf := []byte{len: 45}
  C.wg_key_to_base64(buf.data, &k.key)
  k.keystr = unsafe { cstring_to_vstring(buf.data) }

  return k
}

pub fn (k Key) str() (string) {
  // weired but require `.clone()` @2021/12
  // if omit, below test failed.
  // assert public.keystr == public2.keystr
  return k.keystr.clone()
}

pub fn (k Key) as_wg_key(mut out &byte) ? {
  // println("as_wg_key $k.keystr")
  rc := C.wg_key_from_base64(out, k.keystr.str)
  if rc < 0 {
    return error("wg_key_from_base64() failed: ${rc}")
  }
}

pub fn (k Key) public() ?Key {
  public := []byte{len: 32}
  C.wg_generate_public_key(public.data, &k.key)
  return new_key(ptr: public.data, is_pub: true)
}

