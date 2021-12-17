module chord

fn test_range() {
  r1 := Range<string>{from: "a", to: "c"}
  assert r1.contains("b")

  r2 := Range<string>{from: "a", to: "a"}
  assert r2.contains("b")

  r3 := Range<string>{from: "c", to: "a"}
  assert !r3.contains("b")
}

struct TestComm {
}

fn (c TestComm) get_predecessor() ?TestID {
  return TestID{}
}

fn (c TestComm) notify(id TestID) {
}

struct TestID {
  id string
}

fn (i TestID) get_communicator(to TestID) ?TestComm {
  return error("")
}

fn (a TestID) < (b TestID) bool {
	return true
}

fn (a TestID) str () string {
	return ""
}

fn test_bootstrap() {
  bootstrap<TestID>(TestID{id: "a"})
}

fn test_stabilize() {
  mut n := bootstrap<TestID>(TestID{id: "a"})
  n.stabilize()
}
