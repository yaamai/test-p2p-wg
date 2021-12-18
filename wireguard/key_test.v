module wireguard

fn test_key_generate() ? {
  k := wireguard.new_key()?
  assert k.keystr.len == 44
}

fn test_key_load() ? {
  priv_str := "qIZ+TGCcStq8+zBvakSPU625CMLlg1ns4vVF/6TBTFc="
  pub_str := "ABAtqWomhGRFvIWM1dKth8veypPrbODzZbaZrALzLTc="
  priv := wireguard.new_key(keystr: priv_str)?

  public := priv.public()?
  assert public.str() == pub_str

  public2 := wireguard.new_key(keystr: pub_str, is_pub: true)?
  assert public.key == public2.key
  assert public.keystr == public2.keystr
}
