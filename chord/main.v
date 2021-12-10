module chord

interface ID {
  equal(id ID) bool
}

struct Node {
  id ID
  successors []Route
  predecessor ?Route
}

struct Route {
  id ID
  comm Communicatable
}

interface Communicatable {
  get_predecessor() ID
  check_predecessor(id ID) ID
}

fn bootstrap(id ID, comm Communicatable) Node {
  return Node{
    id: id,
    successors: [Route{id: id, comm: comm}],
  }
}

fn join(id ID, comm Communicatable) {
}

fn (n Node) stablize() {
  id := n.successors[0].comm.get_predecessor()
  if id == n.id {
    return
  }

  n.successors[0].comm.check_predecessor(n.id)
}

