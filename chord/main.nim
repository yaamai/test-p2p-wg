# a

type
  Route[T, S] = tuple
    id: T
    meta: S
    
  Node[T, S] = tuple
    id: T
    successor: Route[T, S]

proc bootstrap*[T, S](id: T, meta: S): Node[T, S] =
  (id: id, successor: (id, meta))

type
  MyID = uint8

let n = bootstrap(0, 0)
echo "a"
echo n
