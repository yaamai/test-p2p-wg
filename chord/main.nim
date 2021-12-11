import std/tables

type
  Route[T] = tuple
    id: T
    
  Node[T] = tuple
    id: T
    successor: Route[T]

  RingRange[T] = tuple
    fr: T
    to: T

proc bootstrap[T](id: T): Node[T] =
  (id: id, successor: (id, ))

proc join[T](newid: T, id: T): Node[T] =
  let successor = id.get_communicator().find_successor(newid)
  (id: newid, successor: (successor,))

proc contains[T](range: RingRange[T], value: T): bool =
  if range.fr == range.to:
    return true
  if range.fr < range.to:
    return range.fr < value and value < range.to
  else:
    return range.fr < value or value < range.to

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

let n0 = bootstrap[uint8](0)
echo n0
m[0] = n0

let n2 = join[uint8](2, 0)
echo n2

let n1 = join[uint8](1, 0)
echo n1
