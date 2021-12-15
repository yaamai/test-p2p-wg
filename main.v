module main
import os
import wireguard

fn main() {
  println("run")
  mut dev := wireguard.new_device("sss0", true)?
  dev.set_private_key("CPDlnyk0H7dgYNtmIoa1AAuD8ulJ2QMITrbzQi3aoW0=")
  dev.apply()?
  peer := wireguard.new_peer("CPDlnyk0H7dgYNtmIoa1AAuD8ulJ2QMITrbzQi3aoW0=")?
  dev.set_peer(peer)
  dev.apply()?
}
