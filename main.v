module main
import os
import wireguard

fn main() {
  println("run")
  println(wireguard.new_device("sss0")?)
}
