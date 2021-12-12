import std/tables
import std/options
import chord
import wireguard

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


let rc = wg_add_device("testwg0")
echo rc

var dev = wg_device()
var devaddr = addr dev
let rc2 = wg_get_device(addr devaddr, "testwg0")
echo rc2
echo devaddr[]

var privateKey: wg_key
wg_generate_private_key(privateKey)
echo privateKey

devaddr.flags = WGDEVICE_HAS_PRIVATE_KEY
devaddr.private_key = privateKey
let rc3 = wg_set_device(devaddr)
echo rc3
