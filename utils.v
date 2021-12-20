module main

fn generate_ip_from_bytes(id []byte) string {
  return "10.163.${id[0]}.${id[1]}"
}

fn generate_chord_id_from_pubkey(pubkey string) string {
  if pubkey == "" { return "" }
  return pubkey.replace_each(['+', '-', '/', '_', '=', ''])[..8]
}


