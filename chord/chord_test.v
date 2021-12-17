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
mut:
  n &Node<TestID>
}

fn (c TestComm) get_predecessor() ?TestID {
  return error("")
}

fn (mut c TestComm) notify(id TestID) {
  c.n.notify(id)
}

struct TestID {
  id string
  m &map[string]&Node<TestID>
}

fn (i TestID) get_communicator(to TestID) ?TestComm {
  return TestComm{n: i.m[to.id]}
}

fn (a TestID) < (b TestID) bool {
	return true
}

fn (a TestID) str () string {
	return a.id
}

fn test_bootstrap() {
  mut m := map[string]&Node<TestID>{}
  mut n := bootstrap<TestID>(TestID{id: "a", m: &m})
  m["a"] = &n
}

fn test_stabilize() ? {
  mut m := map[string]&Node<TestID>{}
  mut n := bootstrap<TestID>(TestID{id: "a", m: &m})
  m["a"] = &n
  n.stabilize()?
}
