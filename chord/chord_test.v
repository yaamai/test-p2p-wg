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

fn test_join_peers() ? {
  mut m := map[string]&Node<TestID>{}

  mut tt := [
    ["a"],
    ["b", "a"],
    ["b", "a", "c"],
    ["b", "a", "e", "d", "c"],
  ]

  for mut ids in tt {

    mut first := bootstrap<TestID>(TestID{id: ids[0], m: &m})
    m[ids[0]] = &first

    for id in ids[1..] {
      mut n := join<TestID>(TestID{id: id, m: &m}, first.id)?
      m[id] = &n
    }

    for i := 0; i < ids.len; i++ {
      for id in ids {
        m[id].stabilize()?
      }
    }

    ids.sort()
    for idx, id in ids {
      next := if idx < ids.len-1 { ids[idx+1] } else { ids[0] }
      prev := if idx > 0 { ids[idx-1] } else { ids[ids.len-1] }
      assert m[id].successor == m[next].id
      assert m[id].predecessor == m[prev].id
    }
  }
}
