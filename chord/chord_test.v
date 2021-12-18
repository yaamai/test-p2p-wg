module chord

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

struct TestID {
  id string
mut:
  m &map[string]&Node<TestID>
}

fn (a TestID) < (b TestID) bool {
	return a.id < b.id
}

fn (a TestID) str () string {
	return a.id
}

fn (a TestID) get_predecessor() ?TestID {
  if !a.m[a.id].has_predecessor {
    return error('')
  }
  return a.m[a.id].predecessor
}

fn (a TestID) find_successor(id TestID) ?TestID {
  return a.m[a.id].find_successor(id)
}

fn (mut a TestID) notify(id TestID) {
  a.m[a.id].notify(id)
}

fn (a TestID) query(id TestID) ?string {
  return a.m[a.id].query(id)
}

fn (mut a TestID) set(id TestID, data string) ? {
  a.m[a.id].set(id, data)?
}

struct TestStore {
mut:
  m map[string]string
}

fn (s TestStore) get(key string) ?string {
  return s.m[key]
}

fn (mut s TestStore) set(key string, val string) ? {
  s.m[key] = val
}
  
  

fn test_bootstrap() {
  mut s := TestStore{}
  mut m := map[string]&Node<TestID>{}
  mut n := bootstrap<TestID>(TestID{id: "a", m: &m}, s)
  m["a"] = &n
}

fn test_stabilize() ? {
  mut s := TestStore{}
  mut m := map[string]&Node<TestID>{}
  mut n := bootstrap<TestID>(TestID{id: "a", m: &m}, s)
  m["a"] = &n
  n.stabilize()?
}

fn create_ring(ids []string) ?(map[string]&Node<TestID>) {
  mut s := TestStore{}
  mut m := map[string]&Node<TestID>{}
  mut first := bootstrap<TestID>(TestID{id: ids[0], m: &m}, s)

  m[ids[0]] = &first

  for id_str in ids[1..] {
    // TODO: if TestID construct in function argument of join, crash occured when access to id.m
    id := TestID{id: id_str, m: &m}
    mut n := join<TestID>(id, first.id, s)?
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
  m["a"].set(id, "12345")?

  println(m)
  data := m["e"].query(id)?
  assert data == "12345"
}
