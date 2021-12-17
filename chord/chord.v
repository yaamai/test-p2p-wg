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
  // vlang cant assign optional values in struct currently. vlang/v: #11293
  predecessor T
  has_predecessor bool
}

fn bootstrap<T>(id T) Node<T> {
  return Node<T>{id: id, successor: id}
}

fn (mut n Node<T>) stabilize() ? {
  println(">> ${n}.stabilize():")
  mut comm := n.id.get_communicator(n.successor)?
  if pred := comm.get_predecessor() {
    range := Range<T>{from: n.id, to: n.successor}
    if range.contains(pred) {
      n.successor = pred
    }
  }
  comm.notify(n.id)
  println("<< ${n}.stabilize():")
}

fn (mut n Node<T>) notify(id T) {
  println(">> ${n}.notify(): ${id}")
  if n.has_predecessor {
    range := Range<T>{from: n.predecessor, to: n.id}
    if range.contains(id) {
      n.predecessor = id
      n.has_predecessor = true
    }
  } else {
    n.predecessor = id
    n.has_predecessor = true
  }
  println("<< Node.notify(): ${id}")
}

