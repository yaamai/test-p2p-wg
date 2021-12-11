module chord

struct TestID {
  id u8

mut:
  // emulate node to node communication within memory reference
  node &Node = 0
}

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

fn (i TestID) str() string {
  return "TestID(${i.id})"
}

fn (i TestID) equal(other TestID) bool {
  return i.id == other.id
}

fn (i TestID) get_communicator() Communicator {
  return i
}

fn (i TestID) find_successor(id ID) (ID) {
  return i.node.find_successor(id)
}

fn (i TestID) get_predecessor() ?ID {
  if p := i.node.predecessor {
    return p
  }
  return none
}

fn (i TestID) notify(id ID) {
  i.node.notify(id)
}


fn test_bootstrap() {
  mut id := TestID{id: 0}
  node := bootstrap(id)
  id.node = &node
   
  node.find_closest_node(TestID{id: 0})
}

fn test_join() {
  mut id0 := TestID{id: 0}
  mut n0 := bootstrap(id0)
  id0.node = &n0
  println(n0)

  mut id1 := TestID{id: 1}
  mut n1 := join(id1, id0)
  id1.node = &n1
  println(n1)

  n0.stabilize()
  n1.stabilize()

  println(n0)
  println(n1)
}
