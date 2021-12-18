module main
import json

struct Test {
  aa ?string
}

fn main() {
  t := json.decode(Test, '{"aa": "a"}')?
  println(t)
}
