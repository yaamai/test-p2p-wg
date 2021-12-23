module wireguard
import json

fn test_repr() ? {
  devstr := '{"name":"sss0","flags":6,"public_key":{"keystr":"tV7ss7hMkkrlFEl/jjN+G8gM3lYz2n3emIavI8z/zlM="},"private_key":{"keystr":"YAD6r0bS0WaVfhCupsTsHPcKGeH3Mph0No8aaib81lQ="},"listen_port":43617,"peers":[{"flags":4,"public_key":{"keystr":"whxn4RBTFqNj2F01Hb8BRFGSdovbSlJxJ7CcVmSLMVM="},"addr":{"IpAddress":{"family":2,"addr":"10.0.0.2"},"port":43617},"allowed_ips":[{"IpAddress":{"family":2,"addr":"10.163.194.28"},"length":32}]},{"flags":4,"public_key":{"keystr":"QXNrRuLZxMp7W5Q+jTUk5gdrABahBksLEd0IeLEubFw="},"addr":{"IpAddress":{"family":2,"addr":"10.0.0.3"},"port":43617},"allowed_ips":[{"IpAddress":{"family":2,"addr":"10.163.65.115"},"length":32}]}]}'

  dev := json.decode(DeviceRepr, devstr)?
  mut wgdev := C.wg_device{}
  dev.as_wg_device(mut &wgdev)?
  assert wgdev.first_peer.flags == 4
  assert wgdev.first_peer.public_key == [byte(194), 28, 103, 225, 16, 83, 22, 163, 99, 216, 93, 53, 29, 191, 1, 68, 81, 146, 118, 139, 219, 74, 82, 113, 39, 176, 156, 86, 100, 139, 49, 83]!
  assert wgdev.first_peer.addr4.sin_family == 2
  assert wgdev.first_peer.addr4.sin_port == 43617
  assert wgdev.first_peer.addr4.sin_addr.s_addr == 33554442
  assert wgdev.first_peer.first_allowedip.family  == 2
  assert wgdev.first_peer.first_allowedip.ip4.s_addr == 482517770
  assert wgdev.first_peer.first_allowedip.cidr == 32
}
