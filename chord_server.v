module main
import picoev
import picohttpparser
import chord

fn new_chord_server(mut node chord.Node) &picoev.Picoev {
  c := picoev.Config {cb: chord_handler, user_data: unsafe { &node }}
  return picoev.new(c)
}

fn chord_handler(node_ptr voidptr, req picohttpparser.Request, mut resp picohttpparser.Response) {
  chord_handler_routing(node_ptr, req, mut resp) or {
	resp.raw('HTTP/1.1 500 Internal Server Error\r\n')
    resp.body(err.msg)
    resp.end()
    return
  }
}

fn http_ok(mut resp picohttpparser.Response, data string) {
  resp.http_ok()
  resp.plain()
  resp.body(data)
  resp.end()
}

// wrap optional
fn chord_handler_routing(node_ptr voidptr, req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  if req.path.starts_with("/predecessor") { return handle_get_predecessor(node_ptr, req, mut resp) }
  if req.path.starts_with("/successor") { return handle_get_successor(node_ptr, req, mut resp) }
  if req.path.starts_with("/notify") { return handle_notify(node_ptr, req, mut resp) }
  if req.path.starts_with("/kvs/") { return handle_query(node_ptr, req, mut resp) }
  if req.path.starts_with("/kvs") { return handle_store(node_ptr, req, mut resp) }
  return error("no route found")
}

fn handle_get_predecessor(node_ptr voidptr, req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  node := unsafe { &chord.Node(node_ptr) }
  if !node.has_predecessor {
    http_ok(mut resp, "")
    return
  }

  http_ok(mut resp, node.predecessor)
}

fn handle_get_successor(node_ptr voidptr, req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  node := unsafe { &chord.Node(node_ptr) }
  s := req.path.split("?target=")
  if s.len != 2 {
    return error("invalid target argument")
  }
  succ := node.find_successor(s[1])?

  http_ok(mut resp, succ)
}

fn handle_notify(node_ptr voidptr, req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  mut node := unsafe { &chord.Node(node_ptr) }
  node.notify(req.body)
  http_ok(mut resp, "")
}

fn handle_query(node_ptr voidptr, req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  node := unsafe { &chord.Node(node_ptr) }
  names := req.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return error("invalid path")
  }

  val := node.query(names[2])?
  http_ok(mut resp, val)
}

fn handle_store(node_ptr voidptr, req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  mut node := unsafe { &chord.Node(node_ptr) }

  names := req.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return error("invalid path")
  }
  node.set(names[2], req.body)?
  http_ok(mut resp, "")
}

struct TestStore {
mut:
  m map[string]string
}

fn (s TestStore) get(key string) ?string {
  return s.m[key]
}

fn (mut s TestStore) set(key string, val string) ? {
  s.m[key] = val
}

