# a

type
  Route[T] = tuple
    id: T
    
  Node[T] = tuple
    id: T
    successor: Route[T]

proc bootstrap[T](id: T): Node[T] =
  (id: id, successor: (id, ))

proc join[T](newid: T, id: T): Node[T] =
  let successor = id.get_communicator().find_successor()
  (id: newid, successor: (successor,))

proc get_communicator(id: uint8): uint8 =
  0

proc find_successor(id: uint8): uint8 =
  0

let n0 = bootstrap[uint8](0)
echo n0

let n1 = join[uint8](1, 0)
echo n1
