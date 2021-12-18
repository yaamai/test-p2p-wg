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

struct TestComm {
pub mut:
  m map[string]&Node
}

fn (c TestComm) get_predecessor(id string) ?string {
  if !c.m[id].has_predecessor {
    return error('')
  }
  return c.m[id].predecessor
}

fn (c TestComm) find_successor(id string, target string) ?string {
  return c.m[id].find_successor(target)
}

fn (mut c TestComm) notify(id string, target string) ? {
  c.m[id].notify(target)
}

fn (c TestComm) query(id string, key string) ?string {
  return c.m[id].query(key)
}

fn (mut c TestComm) store(id string, key string, data string) ? {
  c.m[id].set(key, data)?
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
  mut c := TestComm{m: map[string]&Node{}}
  mut n := bootstrap("a", s, c)
  c.m["a"] = &n
}

fn test_stabilize() ? {
  mut s := TestStore{}
  mut c := TestComm{m: map[string]&Node{}}
  mut n := bootstrap("a", s, c)
  c.m["a"] = &n
  n.stabilize()?
}

fn create_ring(ids []string) ?(TestComm) {
  mut s := TestStore{}
  mut c := TestComm{m: map[string]&Node{}}
  mut first := bootstrap(ids[0], s, c)

  c.m[ids[0]] = &first

  for id in ids[1..] {
    // TODO: if TestID construct in function argument of join, crash occured when access to id.m
    mut n := join(id, first.id, s, c)?
    c.m[id] = &n
  }

  for i := 0; i < ids.len; i++ {
    for id in ids {
      c.m[id].stabilize()?
    }
  }

  return c
}


fn test_join_peers() ? {

  mut tt := [
    ["a"],
    ["b", "a"],
    ["b", "a", "c"],
    ["b", "a", "e", "d", "c"],
  ]

  for mut ids in tt {
    c := create_ring(ids)?

    ids.sort()
    for idx, id in ids {
      next := if idx < ids.len-1 { ids[idx+1] } else { ids[0] }
      prev := if idx > 0 { ids[idx-1] } else { ids[ids.len-1] }
      assert c.m[id].successor == c.m[next].id
      assert c.m[id].predecessor == c.m[prev].id
    }
  }
}

fn test_set_query() ? {
  mut c := create_ring(["b", "a", "e", "d", "c"])?

  c.m["a"].set("c", "12345")?
  data := c.m["e"].query("c")?
  assert data == "12345"
}
