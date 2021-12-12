import std/tables
import std/options
import chord

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


{.compile: "wireguard.c".}
type wg_device {.header: "wireguard.h", importc: "wg_device"} = object
proc wg_add_device(device_name: cstring): cint {.header: "wireguard.h", importc: "wg_add_device"}
proc wg_del_device(device_name: cstring): cint {.header: "wireguard.h", importc: "wg_del_device"}
proc wg_get_device(device: ptr ptr wg_device, device_name: cstring): cint {.header: "wireguard.h", importc: "wg_get_device"}

let rc = wg_add_device("testwg0")
echo rc

var dev = cast[ptr wg_device](wg_device())
let rc2 = wg_get_device(addr dev, "testwg0")
echo rc2
echo dev[]
