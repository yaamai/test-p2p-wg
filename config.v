module main
import json
import os
import wireguard

struct Config {
mut:
  private_key string
  tunnel_addr string
  peers []PeerConfig
}

struct PeerConfig {
mut:
  addr string
  tunnel_addr string
  port int
  public_key string
}

[params]
struct OpenConfigConfig {
  filename string
}

fn open_config(p OpenConfigConfig) ?Config {

  files := [
    p.filename,
    os.getenv(config_env_name)
  ]

  for file in files {
    if file == "" { continue }
    s := os.read_file(file) or { continue }
    return json.decode(Config, s) or { continue }
  }

  return error('cant open config file')
}

fn init_config() ?Config {
  private_key := wireguard.new_key()?
  public_key := private_key.public()?

  return Config {
    private_key: private_key.str(),
    tunnel_addr: generate_ip_from_bytes(public_key.key[0..]),
    peers: [],
  }
}

struct JoinConfig {
mut:
  private_key string
  tunnel_addr string
  peer PeerConfig
}

fn (c Config) merge_join_config(jc JoinConfig, force bool) ?Config {
  mut merged := c
  if !force && c.private_key != jc.private_key {
    return error('private_key is mismatch. cannot merge join config')
  } else {
    merged.private_key = jc.private_key
  }
  merged.tunnel_addr = jc.tunnel_addr
  merged.peers << jc.peer

  return merged
}

fn (c Config) save() Config {
  return c
}
