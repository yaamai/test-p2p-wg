module chord

struct TestRingPositional {
  id u8
}

fn (r TestRingPositional) is_predecessor(other TestRingPositional) bool {
  //   13 14 15 0 1 2 3
  //   1 is_predecessor 2 -> false
  //   0 is_predecessor 3 -> false
  //   3 is_predecessor 0 -> true
  //   3 is_predecessor 15 -> true
  assert r.id != other.id
  if r.id > other.id {
    return false
  }
  return true
}

fn (r TestRingPositional) is_successor(other TestRingPositional) bool {
  return true
}

fn (r TestRingPositional) equal(other TestRingPositional) bool {
  return true
}

fn test_bootstrap() {
  id := TestRingPositional{id: 0}
  bootstrap(id)
}
