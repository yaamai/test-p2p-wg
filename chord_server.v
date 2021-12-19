module main
import net.http
import net.urllib
import chord

const empty = http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
const path_not_found = http.new_response(text: "path not found")

struct ChordHandler {
mut:
  node &chord.Node
}

fn (mut h ChordHandler) handle(req http.Request) http.Response {
  url := urllib.parse(req.url) or { return http.Response{} }
  resp := h.routing(req, url, url.path) or {
    http.new_response(text: err.msg)
  }
  return resp
}

fn (mut h ChordHandler) routing(req http.Request, url urllib.URL, path string) ?http.Response {
  if path.starts_with("/predecessor") { return h.handle_get_predecessor(req, url) }
  if path.starts_with("/successor") { return h.handle_get_successor(req, url) }
  if path.starts_with("/notify") { return h.handle_notify(req, url) }
  if path.starts_with("/kvs/") { return h.handle_query(req, url) }
  if path.starts_with("/kvs") { return h.handle_store(req, url) }
  return path_not_found
}

fn (h ChordHandler) handle_get_predecessor(req http.Request, url urllib.URL) ?http.Response {
  if !h.node.has_predecessor {
    return empty
  }
  return http.new_response(text: h.node.predecessor)
}

fn (h ChordHandler) handle_get_successor(req http.Request, url urllib.URL) ?http.Response {
  target := url.query().get("target")
  if succ := h.node.find_successor(target) {
    return http.new_response(text: succ)
  }
  return empty
}

fn (mut h ChordHandler) handle_notify(req http.Request, url urllib.URL) ?http.Response {
  h.node.notify(req.data)
  return empty
}

fn (h ChordHandler) handle_query(req http.Request, url urllib.URL) ?http.Response {
  names := url.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return http.new_response(text: "invalid path")
  }
  if val := h.node.query(names[2]) {
    return http.new_response(text: val)
  }
  return empty
}

fn (mut h ChordHandler) handle_store(req http.Request, url urllib.URL) ?http.Response {
  names := url.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return http.new_response(text: "invalid path")
  }
  h.node.set(names[2], req.data) or {
    return empty
  }
  return empty
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

