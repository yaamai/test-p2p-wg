module chord

// currently(2021/12) vlang does not support multiple template variables
// and interface that referencing self are also not supported.
interface Store {
  get(string) ?string
  set(string, string) ?
}
  

struct Range<T> {
  from T
  to T
  to_inclusive bool
}

pub fn (r Range<T>) contains(value T) bool {
  if r.from == r.to {
    return true
  }

  if r.from < r.to {
    if r.to_inclusive {
      return r.from < value && value <= r.to
    }
    return r.from < value && value < r.to
  } else {
    return r.from < value || value < r.to
  }
}

// vlang generics does not allow multiple types?
struct Node<T> {
  id T
mut:
  store Store

  successor T
  // vlang cant assign optional values in struct currently. vlang/v: #11293
  predecessor T
  has_predecessor bool
}

fn bootstrap<T>(id T, store Store) Node<T> {
  return Node<T>{id: id, successor: id, store: store}
}

fn (mut n Node<T>) stabilize() ? {
  // println(">> ${n}.stabilize():")
  if pred := n.successor.get_predecessor() {
    range := Range<T>{from: n.id, to: n.successor}
    if range.contains(pred) {
      n.successor = pred
    }
  }

  n.successor.notify(n.id)
  // println("<< ${n}.stabilize():")
}

fn (mut n Node<T>) notify(id T) {
  // println(">> ${n}.notify(): ${id}")
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
  // println("<< Node.notify(): ${id}")
}

fn (n Node<T>) find_successor(id T) ?T {
  range := Range<T>{from: n.id, to: n.successor, to_inclusive: true}
  if range.contains(id) {
    return n.successor
  }
  return n.successor.find_successor(id)
}

fn (n Node<T>) query(id T) ?string {
  successor := n.find_successor(id)?
  if successor != n.id {
    return successor.query(id)
  }
  return n.store.get(id.str())
}

fn (mut n Node<T>) set(id T, data string) ? {
  mut successor := n.find_successor(id)?
  println("set: ${n.id} ${n.successor} ${successor.id}")
  if n.id == successor {
    n.store.set(id.str(), data)?
    return
  }

  return successor.set(id, data)
}

fn join<T>(newid T, to T, store Store) ?Node<T> {
  // comm := to.get_communicator(newid)?
  // below causes infinity loop or compile error...
  // succ := comm.find_successor<T>(newid)
  // succ := comm.find_successor(newid)
  return Node<T>{id: newid, successor: to, store: store}
}
