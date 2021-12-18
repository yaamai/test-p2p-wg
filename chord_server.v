module main
import net.http
import net.urllib
import chord

struct ChordHandler {
mut:
  node &chord.Node
}

fn (mut h ChordHandler) handle(req http.Request) http.Response {
  url := urllib.parse(req.url) or { return http.Response{} }
  return match url.path {
    "/predecessor" { h.handle_get_predecessor(req, url) }
    "/successor" { h.handle_get_successor(req, url) }
    "/notify" { h.handle_notify(req, url) }
    "/kvs/" { h.handle_query(req, url) }
    "/kvs" { h.handle_store(req, url) }
    else { http.Response{} }
  }
}

fn (h ChordHandler) handle_get_predecessor(req http.Request, url urllib.URL) http.Response {
  if !h.node.has_predecessor {
    return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
  }
  return http.new_response(text: h.node.predecessor)
}

fn (h ChordHandler) handle_get_successor(req http.Request, url urllib.URL) http.Response {
  target := url.query().get("target")
  if succ := h.node.find_successor(target) {
    return http.new_response(text: succ)
  }
  return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
}

fn (mut h ChordHandler) handle_notify(req http.Request, url urllib.URL) http.Response {
  println("receive notify ${req.data}")
  h.node.notify(req.data)
  return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
}

fn (h ChordHandler) handle_query(req http.Request, url urllib.URL) http.Response {
  names := url.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return http.new_response(text: "invalid path")
  }
  if val := h.node.query(names[2]) {
    return http.new_response(text: val)
  }
  return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
}

fn (mut h ChordHandler) handle_store(req http.Request, url urllib.URL) http.Response {
  names := url.path.split("/")
  if names.len != 3 || names[1] != "kvs" {
    return http.new_response(text: "invalid path")
  }
  h.node.set(names[2], req.data) or {
    return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
  }
  return http.new_response(text: "", header: http.new_header(key: http.CommonHeader.content_length, value: "0"))
}

