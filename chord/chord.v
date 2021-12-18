module chord

interface Reference {
  get_predecessor() ?Reference
  find_successor(Reference) ?Reference
  query(Reference) ?int
  set(Reference, int) ?
  notify(Reference) ?

  equals(Reference) bool
  greater(Reference) bool
}

struct Range<T> {
  from T
  to T
  to_inclusive bool
}

pub fn (r Range<T>) contains(value T) bool {
  if r.from.equals(r.to) {
    return true
  }

  if r.from.greater(r.to) {
    if r.to_inclusive {
      return r.from.greater(value) && (value.greater(r.to) || value.equals(r.to))
    }
    return r.from.greater(value) && value.greater(r.to)
  } else {
    return r.from.greater(value) || value.greater(r.to)
  }
}

// vlang generics does not allow multiple types?
struct Node {
  id Reference
mut:
  data int
  successor Reference
  // vlang cant assign optional values in struct currently. vlang/v: #11293
  predecessor Reference
  has_predecessor bool
}

fn bootstrap(id Reference) Node {
  return Node{id: id, successor: id}
}

fn (mut n Node) stabilize() ? {
  // println(">> ${n}.stabilize():")
  if pred := n.successor.get_predecessor() {
    range := Range<Reference>{from: n.id, to: n.successor}
    if range.contains(pred) {
      n.successor = pred
    }
  }

  n.successor.notify(n.id)?
  // println("<< ${n}.stabilize():")
}

fn (mut n Node) notify(id Reference) {
  // println(">> ${n}.notify(): ${id}")
  if n.has_predecessor {
    range := Range<Reference>{from: n.predecessor, to: n.id}
    if range.contains(id) {
      n.predecessor = id
      n.has_predecessor = true
    }
  } else {
    n.predecessor = id
    n.has_predecessor = true
  }
  // println("<< Node.notify(): ${id}")
}

fn (n Node) find_successor(id Reference) ?Reference {
  range := Range<Reference>{from: n.id, to: n.successor, to_inclusive: true}
  if range.contains(id) {
    return n.successor
  }
  return n.successor.find_successor(id)
}

fn (n Node) query(id Reference) ?int {
  successor := n.find_successor(id)?
  if ! successor.equals(n.id) {
    return successor.query(id)
  }
  return n.data
}

fn (mut n Node) set(id Reference, data int) ? {
  successor := n.find_successor(id)?
  println("set: ${n.id} ${n.successor} ${successor}")
  if n.id.equals(successor) {
    n.data = data
    return
  }

  return successor.set(id, data)
}

fn join(newid Reference, to Reference) ?Node {
  // comm := to.get_communicator(newid)?
  // below causes infinity loop or compile error...
  // succ := comm.find_successor<T>(newid)
  // succ := comm.find_successor(newid)
  return Node{id: newid, successor: to}
}
