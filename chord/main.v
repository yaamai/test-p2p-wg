module chord

// BUG: W.A. for recursive interface argument
interface ID_ {
  is_element_of(from ID, to ID, from_is_exclusive bool, to_is_exclusive bool) bool
  equal(other ID) bool
}

interface ID {
  ID_
}

struct Node<T> {
  id T
  successors []Route<T>
  // predecessor Route
  fingers []Route<T>
}

fn (n Node<T>) find_successor(id T) T {
  if id.is_element_of(n.id, n.successors[0].id, true, false) {
    return n.successors[0].id
  } else {
    // n0 := closest_preceding_node(id)
    return n.id
  }
}

fn (n Node<T>) find_closest_node(id T) T {
  for f in n.fingers {
    // check f.id ∈ (n.id, id)
    if f.id.is_element_of(n.id, id, false, false) {
      return f.id
    }
  }
  return n.id
}

struct Route<T> {
  id T
  comm Communicatable
}

interface Communicatable<T> {
  find_successor(id T) (T, Communicatable)
}

fn bootstrap<T>(id T, comm Communicatable) Node<T> {
  return Node<T>{
    id: id,
    successors: [Route<T>{id: id, comm: comm}],
  }
}

fn join<T>(id T, comm Communicatable) Node<T> {
  successor, successor_comm := comm.find_successor(id)
  return Node<T> {
    id: id,
    successors: [Route<T>{id: successor, comm: successor_comm}],
  }
}
