

interface AAA<T> {
  foo() T
}

struct BBB<T> {
  a AAA<T>
}

struct CCC {}
fn (c CCC) foo() string {
  return ""
}

fn main() {
  s := BBB<string>{a: AAA<string>(CCC{})}
}
