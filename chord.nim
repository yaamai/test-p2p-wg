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
  Route*[T] = tuple
    id: T
    
  Node*[T] = ref object
    id: T
    successor: Route[T]
    predecessor: Option[Route[T]]

proc stabilize*[T](self: var Node[T]) =
  echo ">>> stabilize", self[]
  let comm = self.id.get_communicator(self.successor.id)
  if comm.isSome():
    let pred = comm.get().get_predecessor()
    if pred.isSome():
      let range = (fr: self.id, to: self.successor.id)
      if range.contains(pred.get().id):
        self.successor = pred.get()
    comm.get().notify(self.id)
  echo "<<< stabilize", self[]

proc notify*[T](self: Node[T], id: T) =
  echo ">>> notify", self[]
  if self.predecessor.isNone():
    self.predecessor = some((id, ))
  else:
    let range = (fr: self.predecessor.get().id, to: self.id)
    if range.contains(id):
      self.predecessor = some((id, ))
  echo "<<< notify", self[]

proc find_successor*[T](node: Node[T], id: T): T =
  let range = (fr: node.id, to: node.successor.id)
  if range.contains(id):
    return node.successor.id
  # if id.is_element_of(node.id, node.successor.id, true, false):
  #   return node.successor.id

proc predecessor*[T](self: Node[T]): Option[Route[T]] =
  self.predecessor

proc bootstrap*[T](id: T): Node[T] =
  Node[T](id: id, successor: (id, ), predecessor: none((T,)))

proc join*[T](newid: T, id: T): Node[T] =
  mixin find_successor
  mixin get_communicator

  let comm = get_communicator(newid, id)
  if comm.isSome():
    let successor = comm.get().find_successor(newid)
    return Node[T](id: newid, successor: (successor,), predecessor: none((T,)))
