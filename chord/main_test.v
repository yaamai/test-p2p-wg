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

fn (i TestID) equal(other TestID) bool {
  return i.id == other.id
}

fn (i TestID) get_communicator() Communicator {
  return i
}

fn (i TestID) find_successor(id ID) (ID) {
  return i.node.find_successor(id)
}


fn test_bootstrap() {
  mut id := TestID{id: 0}
  node := bootstrap(id)
  id.node = &node
   
  node.find_closest_node(TestID{id: 0})
}

fn test_join() {
  mut id0 := TestID{id: 0}
  n0 := bootstrap(id0)
  id0.node = &n0
  println(n0)

  mut id1 := TestID{id: 1}
  n1 := join(id1)
  println(n1)

}
