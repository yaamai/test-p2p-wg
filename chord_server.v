module main
import vweb
import log
import chord

const (
  port = 8088
)

struct ChordServer {
  vweb.Context
mut:
  state shared State
}

struct State {
mut:
  logger log.Logger
  node &chord.Node = 0
}

['/predecessor']
pub fn (mut server ChordServer) handle_predecessor() vweb.Result {
  lock server.state { server.state.logger.debug("handle_get_predecessor():") }
  rlock server.state {
    if server.state.node.has_predecessor {
      return server.text(server.state.node.predecessor)
    }
  }
  return server.text("")
}

['/successor']
pub fn (mut server ChordServer) handle_get_successor() vweb.Result {
  rlock server.state {
    t := server.Context.query["target"]
    server.state.logger.debug("handle_get_successor(): ${t}")
  }
  rlock server.state {
    target := server.Context.query["target"]
    if target != "" {
      succ := server.state.node.find_successor(target) or { "" }
      return server.text(succ)
    }
  }
  return server.text("")
}

[post]
['/notify']
pub fn (mut server ChordServer) handle_notify() vweb.Result {
  lock server.state { server.state.logger.debug("handle_notify(): ${server.req.data}") }
  lock server.state {
    server.state.node.notify(server.req.data)
  }
  return server.text("")
}

['/kvs/:id']
pub fn (mut server ChordServer) handle_query(id string) vweb.Result {
  lock server.state { server.state.logger.debug("handle_query(): ${id}") }
  rlock server.state {
    val := server.state.node.query(id) or { "" }
    return server.text(val)
  }
  return server.text("")
}

[post]
['/kvs/:id']
pub fn (mut server ChordServer) handle_store(id string) vweb.Result {
  lock server.state { server.state.logger.debug("handle_store(): ${id} <= ${server.req.data}") }
  lock server.state {
    server.state.node.set(id, server.req.data) or {
      return server.text("")
    }
  }
  return server.text("")
}

/*


import picoev
import picohttpparser

const empty = ""

[heap]
struct Server {
mut:
  pico &picoev.Picoev = 0
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
    resp.body(err.msg.clone())
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
    http_ok(mut resp, empty)
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
  s.node.notify(req.body.clone())
  http_ok(mut resp, empty)
}

fn (mut s Server) handle_query(req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  s.logger.debug("handle_query():")
  names := req.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return error("invalid path")
  }

  val := s.node.query(names[2])?
  s.logger.debug("    -> ${val}")
  http_ok(mut resp, val)
}

fn (mut s Server) handle_store(req picohttpparser.Request, mut resp picohttpparser.Response) ? {
  s.logger.debug("handle_store(): ${req.body}")
  names := req.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return error("invalid path")
  }
  s.node.set(names[2], req.body.clone())?
  http_ok(mut resp, empty)
}
*/

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


