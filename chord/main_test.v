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
  return TestComm{}
}

struct TestComm {
mut:
  nodes map[u16]&Node
}

fn (mut c TestComm) add(n Node) {
  println('TestComm.add()')
  if n.id is TestID {
    c.nodes[n.id.id] = &n
  }
}

fn (c TestComm) find_successor(id ID) (ID) {
  if id is TestID {
    return c.nodes[id.id].find_successor(id)
  }
  return TestID{id: 0}
}

fn test_bootstrap() {
  mut comm := TestComm{}
  node := bootstrap(TestID{id: 0})
  comm.add(node)

  node.find_closest_node(TestID{id: 0})
}

fn test_join() {
  comm := TestComm{}
  n1 := bootstrap(TestID{id: 0})
  println(n1)

  n2 := join(TestID{id: 1})
  println(n2)

}
