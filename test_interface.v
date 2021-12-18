interface AAA {
  foo(AAA) bool
}

struct BBB {
  a int
}

fn (b BBB) foo(other AAA) bool {
  return b.a == other.a
}

struct CCC {
  a AAA
}

fn main() {
  b := BBB{a: 1}
  c := CCC{a: b}
}
