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

  return new_device
}

fn main() {
  mut dev := bootstrap()?
  node1 := generate_peer_confg(mut dev)?

  // println(k.base64())
  // peer := wireguard.new_peer("CPDlnyk0H7dgYNtmIoa1AAuD8ulJ2QMITrbzQi3aoW0=", "2.3.4.5", 43617)?
  // dev.set_peer(peer)
}
