import wireguard
import netlink
import std/net
import std/strutils

type
  Config = object
    privateKey: string
    publicKey: string
    listenPort: uint16
    tunnelIp: string
    deviceName: string

type
  WireguardDevice = object
    dev: ptr wg_device

proc newWireguardDevice(config: Config): WireguardDevice =
  var rc = 0

  rc = wg_add_device(config.deviceName)
  echo "wg_add_device: ", rc
  rc = wg_get_device(addr result.dev, config.deviceName)
  echo "wg_get_device: ", rc
  echo result.dev[]

  result.dev.flags = {WGDEVICE_HAS_PRIVATE_KEY, WGDEVICE_HAS_LISTEN_PORT}
  rc = wg_key_from_base64(result.dev.private_key, cast[array[45, char]](config.privateKey))
  echo "wg_key_from_base64: ", rc
  echo config.privateKey
  echo result.dev.private_key
  result.dev.listen_port = config.listenPort
  rc = wg_set_device(result.dev)
  echo "wg_set_device: ", rc

  echo cast[cint](result.dev.flags)


proc up(self: WireguardDevice) =
  let rc = nl_set_interface_up(self.dev.ifindex)
  echo rc

proc addAddress(self: WireguardDevice, address: string) =
  let al = address.split("/")
  let rc = nl_add_address(self.dev.ifindex, parseIpAddress(al[0]), parseInt(al[1]))
  echo rc

proc generatePeerConfig(self: WireguardDevice): Config =
  var
    publicKey, privateKey: wg_key
    publicKeyB64, privateKeyB64: wg_key_b64_string
    rc = 0

  wg_generate_private_key(privateKey)
  wg_generate_public_key(publicKey, privateKey)
  echo "wg_generate_private_key: ", privateKey
  echo publicKey
  wg_key_to_base64(publicKeyB64, publicKey)
  wg_key_to_base64(privateKeyB64, privateKey)
  echo cast[string](@privateKeyB64)
  echo cast[string](@publicKeyB64)

  rc = wg_get_device(unsafeAddr self.dev, cast[string](@(self.dev.name)))
  echo rc

  var peer = wg_peer(public_key: publicKey)
  echo peer

  self.dev.flags = {WGDEVICE_REPLACE_PEERS}
  let oldLast = self.dev.last_peer
  self.dev.last_peer = addr peer
  self.dev.first_peer = addr peer

  rc = wg_set_device(self.dev)
  echo rc


  Config(privateKey: cast[string](@privateKeyB64), tunnelIp: "10.163.0.2/32")


var n0Config = Config(
  privateKey: "CPDlnyk0H7dgYNtmIoa1AAuD8ulJ2QMITrbzQi3aoW0=",
  listenPort: 43617,
  tunnelIp: "10.163.0.1/32",
  deviceName: "testwg0")
var n0Device = newWireguardDevice(n0Config)
var n1Config = n0Device.generatePeerConfig()
n1Config.deviceName = "testwg1"
var n1Device = newWireguardDevice(n1Config)


#[
import std/tables
import std/options
import chord

import std/asynchttpserver
import std/asyncdispatch

####################################################################

type
  Comm[T] = tuple
    n: chord.Node[T]

var
  m: Table[uint8, chord.Node[uint8]]

proc get_communicator(fr, to: uint8): Option[Comm[uint8]] =
  if (fr == 1 and to == 2) or (fr == 2 and to == 1):
    return none(Comm[uint8])
  some((n: m[to], ))

proc is_element_of(id: uint8, f: uint8, t: uint8, fb: bool, tb: bool): bool = 
  true

proc find_successor(comm: Comm[uint8], id: uint8): uint8 =
  comm.n.find_successor(id)

proc get_predecessor(comm: Comm[uint8]): Option[Route[uint8]] =
  comm.n.predecessor

proc notify(comm: Comm[uint8], id: uint8) =
  var n = comm.n
  n.notify(id)

m[0] = bootstrap[uint8](0)
# echo m[0]
# m[0] = n0

m[2] = join[uint8](2, 0)
# echo m[2]

m[1] = join[uint8](1, 0)
for i in [1,2,3,4,5,6,7,8,9,10]:
  m[0].stabilize()
  m[1].stabilize()
  m[2].stabilize()

echo "---"
echo m[0][]
echo m[1][]
echo m[2][]


# let rc = wg_add_device("testwg0")
# echo rc
# 
# var dev: ptr wg_device
# let rc2 = wg_get_device(addr dev, "testwg0")
# echo rc2
# echo dev[]

# var privateKey: wg_key
# wg_generate_private_key(privateKey)
# echo privateKey
# 
# devaddr.flags = WGDEVICE_HAS_PRIVATE_KEY
# devaddr.private_key = privateKey
# let rc3 = wg_set_device(devaddr)
# echo rc3

proc main {.async.} =
  var server = newAsyncHttpServer()
  proc cb(req: Request) {.async.} =
    echo (req.reqMethod, req.url, req.headers)
    let headers = {"Content-type": "text/plain; charset=utf-8"}
    await req.respond(Http200, "Hello World", headers.newHttpHeaders())

  server.listen(Port(8000)) # or Port(8080) to hardcode the standard HTTP port.
  # echo "test this with: curl localhost:" & $port.uint16 & "/"
  while true:
    if server.shouldAcceptRequest():
      await server.acceptRequest(cb)
    else:
      # too many concurrent connections, `maxFDs` exceeded
      # wait 500ms for FDs to be closed
      await sleepAsync(500)

waitFor main()
]#
