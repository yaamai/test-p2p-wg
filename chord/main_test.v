module chord

struct TestID {
  id u8
}

fn (i TestID) equal(other TestID) bool {
  return i.id == other.id
}

struct TestComm {
}

fn (c TestComm) get_predecessor() ID {
  return TestID{id: 0}
}

fn (c TestComm) check_predecessor(id ID) ID {
  return TestID{id: 0}
}

fn test_bootstrap() {
  comm := TestComm{}
  bootstrap(TestID{id: 0}, comm)
}

fn test_join() {
  comm := TestComm{}
  n1 := bootstrap(TestID{id: 0}, comm)

  join(TestID{id: 1}, comm)
}
