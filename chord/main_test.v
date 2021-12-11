module chord

struct TestID {
  id u8
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
  a u8
}

fn (c TestComm) find_successor(id ID) (ID) {
  return TestID{id: 0}
}

fn test_bootstrap() {
  comm := TestComm{}
  node := bootstrap(TestID{id: 0})
  node.find_closest_node(TestID{id: 0})
}

fn test_join() {
  comm := TestComm{}
  n1 := bootstrap(TestID{id: 0})
  println(n1)

  n2 := join(TestID{id: 1})
  println(n2)

}
