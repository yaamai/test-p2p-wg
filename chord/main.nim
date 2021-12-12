import std/tables
import std/options

type
  RingRange[T] = tuple
    fr: T
    to: T

proc contains[T](range: RingRange[T], value: T): bool =
  echo "contains ", value, " in ", range
  if range.fr == range.to:
    return true
  if range.fr < range.to:
    return range.fr < value and value < range.to
  else:
    return range.fr < value or value < range.to

type
  Route[T] = tuple
    id: T
    
  Node[T] = ref object
    id: T
    successor: Route[T]
    predecessor: Option[Route[T]]

proc bootstrap[T](id: T): Node[T] =
  Node[T](id: id, successor: (id, ), predecessor: none((T,)))

proc join[T](newid: T, id: T): Node[T] =
  let successor = id.get_communicator().find_successor(newid)
  Node[T](id: newid, successor: (successor,), predecessor: none((T,)))

proc stabilize[T](self: var Node[T]) =
  echo ">>> stabilize", self[]
  let pred = self.successor.id.get_communicator().get_predecessor()
  if pred.isSome():
    let range = (fr: self.id, to: self.successor.id)
    if range.contains(pred.get().id):
      self.successor = pred.get()
  self.successor.id.get_communicator().notify(self.id)
  echo "<<< stabilize", self[]

proc notify[T](self: Node[T], id: T) =
  echo ">>> notify", self[]
  if self.predecessor.isNone():
    self.predecessor = some((id, ))
  else:
    let range = (fr: self.predecessor.get().id, to: self.id)
    if range.contains(id):
      self.predecessor = some((id, ))
  echo "<<< notify", self[]

proc find_successor[T](node: Node[T], id: T): T =
  let range = (fr: node.id, to: node.successor.id)
  if range.contains(id):
    return node.successor.id
  # if id.is_element_of(node.id, node.successor.id, true, false):
  #   return node.successor.id

discard """
fn (n Node) find_successor(id ID) ID {
  if id.is_element_of(n.id, n.successors[0].id, true, false) {
    return n.successors[0].id
  }

  n1 := n.find_closest_node(id)
  if n1 == n.id {
    return n.id
  }
  comm := n1.get_communicator()
  return comm.find_successor(id)
}
"""

####################################################################

type
  Comm[T] = tuple
    n: Node[T]

var
  m: Table[uint8, Node[uint8]]

proc get_communicator(id: uint8): Comm[uint8] =
  (n: m[id], )

proc is_element_of(id: uint8, f: uint8, t: uint8, fb: bool, tb: bool): bool = 
  true

proc find_successor(comm: Comm[uint8], id: uint8): uint8 =
  comm.n.find_successor(id)

proc get_predecessor(comm: Comm[uint8]): Option[Route[uint8]] =
  comm.n.predecessor

proc notify(comm: Comm[uint8], id: uint8) =
  var n = comm.n
  n.notify(id)

discard """
fn (i TestID) is_element_of(from TestID, to TestID, from_is_exclusive bool, to_is_exclusive bool) bool {
  if from_is_exclusive {
    if to_is_exclusive {
      return from.id < i.id && i.id < to.id
    } else {
      return from.id < i.id && i.id <= to.id
    }
  } else {
    if to_is_exclusive {
      return from.id <= i.id && i.id < to.id
    } else {
      return from.id <= i.id && i.id <= to.id
    }
  }
}
"""

m[0] = bootstrap[uint8](0)
# echo m[0]
# m[0] = n0
m[0].stabilize()

m[2] = join[uint8](2, 0)
# echo m[2]
m[0].stabilize()
m[0].stabilize()
m[2].stabilize()
m[2].stabilize()

m[1] = join[uint8](1, 0)

echo "---"
echo m[0][]
echo m[1][]
echo m[2][]
