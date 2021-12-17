module main
import os
import wireguard
import netlink
import json

fn bootstrap() ?wireguard.Device {
  public_key, private_key := wireguard.new_key()?.base64()
  mut dev := wireguard.new_device("sss0", true)?

  dev.set_private_key(private_key)
  dev.set_public_key(public_key)
  dev.set_listen_port(43617)
  dev.apply()?

  netlink.set_interface_up(dev.get_index())?
  netlink.add_interface_addr(dev.get_index(), "10.163.0.1", 32)?

  return dev
}

fn generate_peer_confg(mut dev wireguard.Device) ?JoinConfig {
  // should be random or network unique
  peer_addr := "10.163.0.2"
  public_key, private_key := wireguard.new_key()?.base64()

  peer := wireguard.new_peer(key: public_key, allowed_ip: peer_addr)?
  dev.set_peer(peer)
  dev.apply()?
  netlink.add_if_route(peer_addr, 32, dev.get_index())?

  return JoinConfig {
    private_key: private_key,
    tunnel_addr: peer_addr,
    // TODO: query to netlink? or hold wireguard.Device or generate ip from id
    remote_tunnel_addr: "10.163.0.1",
    remote_port: 43617,
    remote_public_key: dev.get_public_key(),
  }
}

[params]
struct JoinConfig {
mut:
  private_key string
  tunnel_addr string
  remote_tunnel_addr string
  remote_addr string
  remote_port int
  remote_public_key string
}

fn do_join(p JoinConfig) ?wireguard.Device {
  mut dev := wireguard.new_device("sss0", true)?
  dev.set_private_key(p.private_key)
  dev.set_listen_port(43617)
  dev.set_peer(wireguard.new_peer(key: p.remote_public_key, addr: p.remote_addr, port: p.remote_port, allowed_ip: p.remote_tunnel_addr)?)
  dev.apply()?
  netlink.set_interface_up(dev.get_index())?
  netlink.add_interface_addr(dev.get_index(), p.tunnel_addr, 32)?
  netlink.add_if_route(p.remote_tunnel_addr, 32, dev.get_index())?

  return dev
}

/*
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

fn main() {

  if os.args.len < 2 {
    println(error('insufficient command-line arguments'))
    return
  }
  action := os.args[1]

  if action == "bootstrap" {
    mut dev := bootstrap()?
  } else if action == "genpeer" {
    mut dev := wireguard.new_device("sss0", true)?
    mut config := generate_peer_confg(mut dev)?
    config.remote_addr = "10.0.0.1"
    println(json.encode(config))
  } else if action == "join" {
    config := json.decode(JoinConfig, os.args[2])?
    do_join(config)?
  }

  // println(k.base64())
  // peer := wireguard.new_peer("CPDlnyk0H7dgYNtmIoa1AAuD8ulJ2QMITrbzQi3aoW0=", "2.3.4.5", 43617)?
  // dev.set_peer(peer)
}
