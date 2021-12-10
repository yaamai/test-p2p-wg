module chord

struct ID {
}

fn (i ID) distance() int {
  return 0
}

interface RingPositional {
  is_predecessor(other RingPositional) bool
  is_successor(other RingPositional) bool
  equal(other RingPositional) bool
}

struct Node {
  id ID
  routes Routes
}

struct Routes {
  successor []SuccessorRoute
  finger []FingerRoute
}

struct SuccessorRoute {
  id ID
  comm Communicatable
}

struct FingerRoute {
  id ID
  comm Communicatable
}

interface Communicatable {
  get_predecessor() ID
  check_predecessor(id ID) ID
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

