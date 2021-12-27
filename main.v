module main
import wireguard
import os
import netlink
import chord
import json
import time
import log
import vweb

const config_env_name = "CONFIG"
const default_device_name = "sss0"
const default_device_listen_port = 43617

fn main() {

  if os.args.len < 2 {
    println(error('insufficient command-line arguments'))
    return
  }

  /*
  case 1: init[A] -> gen-peer[A] -> join[B]
  case 2: init[A] -> init[B] -> gen-peer[A] -> join[B]
  */
  match os.args[1] {
    "config" { do_config()? }
    "gen-peer" { do_gen_peer()? }
    "serve" { do_serve()? }
    else { return }
  }
}

fn do_config() ? {
  // initialize alone
  config := open_config() or { init_config()?.save()?  }

  // initialize with join config
  if os.args.len < 3 {
    return
  }

  s := os.read_file(os.args[2])?
  mut jc := json.decode(JoinConfig, s)?
  // TODO: external ip resolve when join config generation
  jc.peer.addr = "10.0.0.1"
  config.merge_join_config(jc, true)?.save()?
}

fn do_gen_peer() ?JoinConfig {
  mut config := open_config() or { init_config()?.save()?  }

  // TODO: receive public key from argument
  peer_key := wireguard.new_key()?
  peer_pubkey := peer_key.public()?
  peer_addr := generate_ip_from_bytes(peer_pubkey.key[0..])

  config.peers << PeerConfig {
    public_key: peer_pubkey.str(),
    tunnel_addr: peer_addr,
  }
  config.save()?
  apply_config(config)?

  jc := JoinConfig {
    private_key: peer_key.str(),
    tunnel_addr: peer_addr,
    peer: PeerConfig {
      tunnel_addr: config.tunnel_addr,
      port: default_device_listen_port,
      public_key: wireguard.new_key(keystr: config.private_key)?.public()?.str(),
    }
  }

  os.write_file("peer.json", json.encode(jc))?

  return jc
}

fn apply_config(c Config) ?wireguard.Device {
  // TODO: make declarative
  mut dev := wireguard.new_device(
    name: default_device_name,
    private_key: c.private_key,
    listen_port: default_device_listen_port,
    allow_exists: true,
  )?

  // TODO: address should be replace, not add
  netlink.set_interface_up(dev.get_index())?
  netlink.add_interface_addr(dev.get_index(), c.tunnel_addr, 32)?
  netlink.add_if_route("10.163.0.0", 16, dev.get_index(), true)?

  for peer in c.peers {
    p := wireguard.new_peer(key: peer.public_key, addr: peer.addr, port: peer.port, allowed_ip: peer.tunnel_addr)?
    dev.set_peer(p) or {
      println(err)
      continue
    }
  }

  return dev
}

fn do_serve() ? {
  mut config := open_config() or { init_config()?.save()? }
  println("loaded config:\n---\n${config}\n---")

  mut logger := log.Log{}
  logger.set_level(log.Level.debug)

  mut dev := apply_config(config)?
  self_id := generate_chord_id_from_pubkey(dev.get_public_key())
  mut store := TestStore{
    m: map[string]string{},
    dev: wireguard.open_device(dev.get_name())?,
    self_id: self_id,
  }

  // use connectable peer as chord existing successor id
  mut successor_id := ""
  connectable := config.peers.filter(it.addr != "")
  if connectable.len > 0 {
    successor_id = connectable[0].public_key
  }
  comm := WireguardComm{dev: &dev, logger: logger}
  mut node := chord.new_node(
    self_id,
    generate_chord_id_from_pubkey(successor_id),
    store,
    comm
  )
  mut server := &ChordServer{state: State{node: &node, logger: &logger}}

  threads := [
    go vweb.run(server, 8080)
    go stabilize_loop(mut &node)
  ]
  threads.wait()
}

fn stabilize_loop(mut node chord.Node) {
    for {
      node.stabilize() or {
        println("stabilize() failed: ${err}")
      }

      // TODO: log if changed
      println("${node.predecessor} <--  ${node.id}  --> ${node.successor}")
      time.sleep(5*time.second)
    }
}

/*
sudo ip netns exec siteA ip link del dev veth0
sudo ip netns del siteA
sudo ip netns del siteB
sudo ip netns add siteA
sudo ip netns add siteB
sudo ip link add veth0 type veth peer name veth1
sudo ip link set dev veth0 netns siteA
sudo ip link set dev veth1 netns siteB
sudo ip netns exec siteA ip addr add dev veth0 10.0.0.1/24
sudo ip netns exec siteB ip addr add dev veth1 10.0.0.2/24
sudo ip netns exec siteA ip link set dev veth0 up
sudo ip netns exec siteB ip link set dev veth1 up
sudo ip netns exec siteA ip link set dev lo up
sudo ip netns exec siteB ip link set dev lo up
*/

/*
sudo ip netns add siteA
sudo ip netns add siteB
sudo ip netns add siteC

sudo ip link add vethA type veth peer name veth0
sudo ip link set dev veth0 netns siteA
sudo ip link add vethB type veth peer name veth0
sudo ip link set dev veth0 netns siteB
sudo ip link add vethC type veth peer name veth0
sudo ip link set dev veth0 netns siteC

sudo ip link add inet0 type bridge
sudo ip link set dev inet0 up
sudo ip link set dev vethA master inet0 up
sudo ip link set dev vethB master inet0 up
sudo ip link set dev vethC master inet0 up

sudo ip netns exec siteA ip addr add dev veth0 10.0.0.1/24
sudo ip netns exec siteB ip addr add dev veth0 10.0.0.2/24
sudo ip netns exec siteC ip addr add dev veth0 10.0.0.3/24
sudo ip netns exec siteA ip link set dev veth0 up addr 5e:55:de:aa:e7:43
sudo ip netns exec siteB ip link set dev veth0 up addr 5e:55:de:bb:e7:43
sudo ip netns exec siteC ip link set dev veth0 up addr 5e:55:de:cc:e7:43
sudo ip netns exec siteA ip link set dev lo up
sudo ip netns exec siteB ip link set dev lo up
sudo ip netns exec siteC ip link set dev lo up
*/

/*
sudo ip netns add siteA
sudo ip netns add siteB
sudo ip netns add siteC
sudo ip netns add siteD
sudo ip netns add siteDl

sudo ip link add vethA type veth peer name veth0
sudo ip link set dev veth0 netns siteA
sudo ip link add vethB type veth peer name veth0
sudo ip link set dev veth0 netns siteB
sudo ip link add vethC type veth peer name veth0
sudo ip link set dev veth0 netns siteC
sudo ip link add vethD type veth peer name veth0
sudo ip link set dev veth0 netns siteD

sudo ip link add inet0 type bridge
sudo ip link set dev inet0 up
sudo ip link set dev vethA master inet0 up
sudo ip link set dev vethB master inet0 up
sudo ip link set dev vethC master inet0 up
sudo ip link set dev vethD master inet0 up

sudo ip netns exec siteA ip addr add dev veth0 10.0.0.1/24
sudo ip netns exec siteB ip addr add dev veth0 10.0.0.2/24
sudo ip netns exec siteC ip addr add dev veth0 10.0.0.3/24
sudo ip netns exec siteD ip addr add dev veth0 10.0.0.4/24
sudo ip netns exec siteA ip link set dev veth0 up addr 5e:55:de:aa:e7:43
sudo ip netns exec siteB ip link set dev veth0 up addr 5e:55:de:bb:e7:43
sudo ip netns exec siteC ip link set dev veth0 up addr 5e:55:de:cc:e7:43
sudo ip netns exec siteD ip link set dev veth0 up addr 5e:55:de:dd:e7:43
sudo ip netns exec siteA ip link set dev lo up
sudo ip netns exec siteB ip link set dev lo up
sudo ip netns exec siteC ip link set dev lo up
sudo ip netns exec siteD ip link set dev lo up
sudo ip netns exec siteDl ip link set dev lo up

sudo ip link add lanD0 type veth peer name veth0
sudo ip link set dev lanD0 netns siteD
sudo ip link set dev veth0 netns siteDl
sudo ip netns exec siteD ip link set dev lanD0 up
sudo ip netns exec siteD ip addr add dev lanD0 192.168.100.254/24
sudo ip netns exec siteDl ip link set dev veth0 up
sudo ip netns exec siteDl ip addr add dev veth0 192.168.100.1/24
sudo ip netns exec siteDl ip route add default via 192.168.100.254
sudo ip netns exec siteD iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -o veth0 -j MASQUERADE --random

*/
