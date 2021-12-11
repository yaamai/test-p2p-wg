module chord

// BUG: W.A. for recursive interface argument
interface ID_ {
  is_element_of(from ID, to ID, from_is_exclusive bool, to_is_exclusive bool) bool
}

interface ID {
  ID_
}

struct Node {
  id ID
  successors []Route
  // predecessor Route
  fingers []Route
}

fn (n Node) find_successor(id ID) ID {
  if id.is_element_of(n.id, n.successors[0].id, true, false) {
    return n.successors[0].id
  } else {
    // n0 := closest_preceding_node(id)
    return n.id
  }
}

fn (n Node) find_closest_node(id ID) ID {
  for f in n.fingers {
    // check f.id ∈ (n.id, id)
    if f.id.is_element_of(n.id, id, false, false) {
      return f.id
    }
  }
  return n.id
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

fn join(id ID, comm Communicatable) Node {
  return Node{
    id: id,
    successors: [Route{id: id, comm: comm}],
  }
}

fn (n Node) stablize() {
/*
  id := n.successors[0].comm.get_predecessor()
  if id == n.id {
    return
  }

  n.successors[0].comm.check_predecessor(n.id)
*/
}

