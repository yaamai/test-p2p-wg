module chord

interface ID {
  RingPositional
}

interface RingPositional {
  // BUG: why can't use RingPositional in other's type?
  is_predecessor(other ID) bool
  is_successor(other ID) bool
  equal(other ID) bool
}

struct Node {
  id RingPositional
  routes Routes
}

struct Routes {
  successor []SuccessorRoute
  finger []FingerRoute
}

struct SuccessorRoute {
  id RingPositional
  comm Communicatable
}

struct FingerRoute {
  id RingPositional
  comm Communicatable
}

interface Communicatable {
  get_predecessor() RingPositional
  check_predecessor(id RingPositional) RingPositional
}

fn bootstrap(id ID) Node {
  return Node{}
}

fn join(id ID, comm Communicatable) {
}

fn (n Node) stablize() {
  id := n.routes.successor[0].comm.get_predecessor()
  if id == n.id {
    return
  }

  n.routes.successor[0].comm.check_predecessor(n.id)
}

