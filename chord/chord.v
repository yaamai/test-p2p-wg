module chord

struct Range<T> {
  from T
  to T
}

pub fn (r Range<T>) contains(value T) bool {
  if r.from == r.to {
    return true
  }

  if r.from < r.to {
    return r.from < value && value < r.to
  } else {
    return r.from < value || value < r.to
  }
}

struct Node<T> {
  id T
mut:
  successor T
  predecessor ?T
}

fn bootstrap<T>(id T) Node<T> {
  return Node<T>{id: id, successor: id}
}

fn (mut n Node<T>) stabilize() {
  println(">>> stabilize" + n.id.str())
  if comm := n.id.get_communicator(n.successor) {
    if pred := comm.get_predecessor() {
      range := Range<T>{from: n.id, to: n.successor}
      if range.contains(pred) {
        n.successor = pred
      }
    }
    comm.notify(n.id)
  }
  println("<<< stabilize" + n.id.str())
}
