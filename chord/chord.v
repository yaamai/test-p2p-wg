module chord

// currently(2021/12) vlang does not support multiple template variables
// and interface that referencing self are also not supported.
interface Store {
  get(string) ?string
  set(string, string) ?
}

interface Communicator {
  get_predecessor(string) ?string
  find_successor(string, string) ?string
  notify(string, string) ?
  query(string, string) ?string
  store(string, string, string) ?
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
struct Node {
  id string
  store Store
  comm Communicator
mut:
  successor string
  // vlang cant assign optional values in struct currently. vlang/v: #11293
  predecessor string
  has_predecessor bool
}

fn bootstrap(id string, store Store, comm Communicator) Node {
  return Node{id: id, successor: id, store: store, comm: comm}
}

fn (mut n Node) stabilize() ? {
  // println(">> ${n}.stabilize():")
  if pred := n.comm.get_predecessor(n.successor) {
    range := Range<string>{from: n.id, to: n.successor}
    if range.contains(pred) {
      n.successor = pred
    }
  }

  n.comm.notify(n.successor, n.id)?
  // println("<< ${n}.stabilize():")
}

fn (mut n Node) notify(id string) {
  // println(">> ${n}.notify(): ${id}")
  if n.has_predecessor {
    range := Range<string>{from: n.predecessor, to: n.id}
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

fn (n Node) find_successor(id string) ?string {
  range := Range<string>{from: n.id, to: n.successor, to_inclusive: true}
  if range.contains(id) {
    return n.successor
  }
  return n.comm.find_successor(n.successor, id)
}

fn (n Node) query(id string) ?string {
  successor := n.find_successor(id)?
  if successor != n.id {
    return n.comm.query(n.successor, id)
  }
  return n.store.get(id.str())
}

fn (mut n Node) set(id string, data string) ? {
  mut successor := n.find_successor(id)?
  // println("set: ${n.id} ${n.successor} ${successor}")
  if successor == n.id {
    n.store.set(id.str(), data)?
    return
  }

  return n.comm.store(n.successor, id, data)
}

fn join(newid string, to string, store Store, comm Communicator) ?Node {
  // comm := to.get_communicator(newid)?
  // below causes infinity loop or compile error...
  // succ := comm.find_successor<T>(newid)
  // succ := comm.find_successor(newid)
  return Node{id: newid, successor: to, store: store, comm: comm}
}
