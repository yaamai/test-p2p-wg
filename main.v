module main
import os
import wireguard
import netlink

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

fn generate_peer_confg(mut dev wireguard.Device) ?wireguard.Device {
  public_key, private_key := wireguard.new_key()?.base64()

  peer1 := wireguard.new_peer(public_key, "127.0.0.1", 43618)?
  dev.set_peer(peer1)
  dev.apply()?

  peer2 := wireguard.new_peer(dev.get_public_key(), "127.0.0.1", 43617)?
  mut new_device:= wireguard.new_device("sss1", true)?
  new_device.set_private_key(private_key)
  new_device.set_listen_port(43618)
  new_device.set_peer(peer2)
  new_device.apply()?
  netlink.set_interface_up(new_device.get_index())?
  netlink.add_interface_addr(new_device.get_index(), "10.163.0.2", 32)?

  return new_device
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
  if os.args.len != 2 {
    println(error('insufficient command-line arguments'))
    return
  }
  action := os.args[1]

  if action == "bootstrap" {
    mut dev := bootstrap()?
  } else if action == "genpeer" {
    mut dev := wireguard.new_device("sss0", true)?
    node1 := generate_peer_confg(mut dev)?
  }

  // println(k.base64())
  // peer := wireguard.new_peer("CPDlnyk0H7dgYNtmIoa1AAuD8ulJ2QMITrbzQi3aoW0=", "2.3.4.5", 43617)?
  // dev.set_peer(peer)
}
