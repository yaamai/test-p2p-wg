module main
import picoev
import picohttpparser
import chord
import log

[heap]
struct Server {
mut:
  pico &picoev.Picoev = 0
  node &chord.Node = 0
  logger log.Logger
}

fn new_chord_server(mut node &chord.Node, logger log.Logger) Server {
  mut s := Server{logger: logger}
  c := picoev.Config {cb: chord_handler, user_data: unsafe { &s }}
  s.pico = picoev.new(c)
  s.node = unsafe { node }

  return s
}

fn (s Server) serve() {
  s.pico.serve()
}

fn chord_handler(node_ptr voidptr, req picohttpparser.Request, mut resp picohttpparser.Response) {
  mut s := &Server(node_ptr)
  s.logger.debug("chord_handler(): ${req.path}")
  s.chord_handler_routing(req, mut resp) or {
	resp.raw('HTTP/1.1 500 Internal Server Error\r\n')
    resp.body(err.msg)
    resp.end()
    return
  }
}

fn http_ok(mut resp picohttpparser.Response, data string) {
  println("response(): ${data}")
  resp.http_ok()
  resp.plain()
  resp.body(data)
  resp.end()
}

// wrap optional
fn (mut s Server) chord_handler_routing(req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  if req.path.starts_with("/predecessor") { return s.handle_get_predecessor(req, mut resp) }
  if req.path.starts_with("/successor") { return s.handle_get_successor(req, mut resp) }
  if req.path.starts_with("/notify") { return s.handle_notify(req, mut resp) }
  if req.path.starts_with("/kvs") {
    if req.method == "GET" { return s.handle_query(req, mut resp) }
    if req.method == "POST" { return s.handle_store(req, mut resp) }
  }
  return error("no route found")
}

fn (mut s Server) handle_get_predecessor(req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  s.logger.debug("handle_get_predecessor(): ${s.node.predecessor}")
  if !s.node.has_predecessor {
    http_ok(mut resp, "")
    return
  }

  http_ok(mut resp, s.node.predecessor)
}

fn (mut s Server) handle_get_successor(req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  ss := req.path.split("?target=")
  if ss.len != 2 {
    return error("invalid target argument")
  }
  succ := s.node.find_successor(ss[1])?

  http_ok(mut resp, succ)
}

fn (mut s Server) handle_notify(req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  s.logger.debug("handle_notify(): ${req.body}")
  s.node.notify(req.body)
  http_ok(mut resp, "")
}

fn (mut s Server) handle_query(req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  names := req.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return error("invalid path")
  }

  val := s.node.query(names[2])?
  http_ok(mut resp, val)
}

fn (mut s Server) handle_store(req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  s.logger.debug("handle_store(): ")
  names := req.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return error("invalid path")
  }
  s.node.set(names[2], req.body)?
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

