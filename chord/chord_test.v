module chord

/*
fn test_range() {
  r1 := Range<string>{from: "a", to: "c"}
  assert r1.contains("b")

  r2 := Range<string>{from: "a", to: "a"}
  assert r2.contains("b")

  r3 := Range<string>{from: "c", to: "a"}
  assert !r3.contains("b")
}

fn test_range_inclusive() {
  r1 := Range<string>{from: "a", to: "c", to_inclusive: true}
  assert r1.contains("c")
}
*/

struct StringNodeRef {
  id string
}

fn (r StringNodeRef) get_predecessor() ?Reference {
  return error('')
}

fn (r StringNodeRef) notify(other Reference) ? {
  return error('')
}

fn (r StringNodeRef) find_successor(other Reference) ?Reference {
  return error('')
}

fn (r StringNodeRef) query(other Reference) ?int {
  return error('')
}

fn (r StringNodeRef) set(other Reference, data int) ? {
  return error('')
}

fn (r StringNodeRef) equals(other Reference) bool {
  if other is StringNodeRef {
    return r.id == other.id
  }
  return false
}

fn (r StringNodeRef) greater(other Reference) bool {
  if other is StringNodeRef {
    return r.id < other.id
  }
  return false
}

fn test_a() {
  bootstrap(StringNodeRef{id: "a"})
}
/*
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

fn (c TestComm) find_successor(id TestID) ?TestID {
  return c.n.find_successor(id)
}

fn (mut c TestComm) notify(id TestID) {
  c.n.notify(id)
}

fn (c TestComm) query(id TestID) ?int {
  return c.n.query(id)
}

fn (mut c TestComm) set(id TestID, data int) ? {
  c.n.set(id, data)?
}

struct TestID {
  id string
  m &map[string]&Node<TestID>
}

fn (i TestID) get_communicator(to TestID) ?TestComm {
  // println("TestID{${i.id}}.get_communicator(${to.id})")
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

fn create_ring(ids []string) ?(map[string]&Node<TestID>) {
  mut m := map[string]&Node<TestID>{}
  mut first := bootstrap<TestID>(TestID{id: ids[0], m: &m})

  m[ids[0]] = &first

  for id_str in ids[1..] {
    // TODO: if TestID construct in function argument of join, crash occured when access to id.m
    id := TestID{id: id_str, m: &m}
    mut n := join<TestID>(id, first.id)?
    m[id_str] = &n
  }

  for i := 0; i < ids.len; i++ {
    for id in ids {
      m[id].stabilize()?
    }
  }

  return m
}


fn test_join_peers() ? {

  mut tt := [
    ["a"],
    ["b", "a"],
    ["b", "a", "c"],
    ["b", "a", "e", "d", "c"],
  ]

  for mut ids in tt {
    m := create_ring(ids)?

    ids.sort()
    for idx, id in ids {
      next := if idx < ids.len-1 { ids[idx+1] } else { ids[0] }
      prev := if idx > 0 { ids[idx-1] } else { ids[ids.len-1] }
      assert m[id].successor == m[next].id
      assert m[id].predecessor == m[prev].id
    }
  }
}

fn test_set_query() ? {
  mut m := create_ring(["b", "a", "e", "d", "c"])?

  id := TestID{id: "c", m: &m}
  m["a"].set(id, 12345)?
  assert m["c"].data == 12345

  println(m)
  data := m["e"].query(id)?
  assert data == 12345
}
*/
