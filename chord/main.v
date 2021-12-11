module chord

interface Communicator {
  find_successor(id ID) (ID)
}

// BUG: W.A. for recursive interface argument
interface ID_ {
  is_element_of(from ID, to ID, from_is_exclusive bool, to_is_exclusive bool) bool
  get_communicator() Communicator
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
  }

  n1 := n.find_closest_node(id)
  if n1 == n.id {
    return n.id
  }
  comm := n1.get_communicator()
  return comm.find_successor(id)
}

fn (n Node) find_closest_node(id ID) ID {
  for f in n.fingers {
    // check f.id ∈ (n.id, id)
    if f.id.is_element_of(n.id, id, true, true) {
      return f.id
    }
  }
  return n.id
}

struct Route {
  id ID
}

interface Communicatable {
  find_successor(id ID) (ID, Communicatable)
  get_predecessor() ID
  check_predecessor(id ID) ID
}

fn bootstrap(id ID) Node {
  return Node{
    id: id,
    successors: [Route{id: id}],
  }
}

fn join(newid ID, id ID) Node {
  comm := id.get_communicator()
  successor := comm.find_successor(newid)

  return Node{
    id: newid,
    successors: [Route{id: successor}],
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

