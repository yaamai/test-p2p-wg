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
  if !c.n.has_predecessor {
    return error('')
  }
  return c.n.predecessor
}

fn (c TestComm) find_successor(id TestID) TestID {
  return c.n.find_successor(id)
}

fn (mut c TestComm) notify(id TestID) {
  c.n.notify(id)
}

struct TestID {
  id string
  m &map[string]&Node<TestID>
}

fn (i TestID) get_communicator(to TestID) ?TestComm {
  unsafe {
    return TestComm{n: i.m[to.id]}
  }
}

fn (a TestID) < (b TestID) bool {
	return a.id < b.id
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

fn test_join_two_peer() ? {
  mut m := map[string]&Node<TestID>{}

  mut n1 := bootstrap<TestID>(TestID{id: "a", m: &m})
  m["a"] = &n1
  println("boostrap a: ${m}")

  mut n2 := join<TestID>(TestID{id: "b", m: &m}, n1.id)?
  m["b"] = &n2
  println("boostrap b: ${m}")

  for i := 0; i < 10; i++ {
    n1.stabilize()?
    n2.stabilize()?
  }

  assert n1.successor == n2.id
  assert n1.predecessor == n2.id
  assert n2.successor == n1.id
  assert n2.predecessor == n1.id
}

fn test_join_three_peer() ? {
  mut m := map[string]&Node<TestID>{}

  mut n1 := bootstrap<TestID>(TestID{id: "a", m: &m})
  m["a"] = &n1

  mut n2 := join<TestID>(TestID{id: "b", m: &m}, n1.id)?
  m["b"] = &n2

  mut n3 := join<TestID>(TestID{id: "c", m: &m}, n1.id)?
  m["c"] = &n3

  for i := 0; i < 10; i++ {
    n1.stabilize()?
    n2.stabilize()?
    n3.stabilize()?
  }

  println(m)
  assert n1.successor == n2.id
  assert n1.predecessor == n3.id
  assert n2.successor == n3.id
  assert n2.predecessor == n1.id
  assert n3.successor == n1.id
  assert n3.predecessor == n2.id
}
