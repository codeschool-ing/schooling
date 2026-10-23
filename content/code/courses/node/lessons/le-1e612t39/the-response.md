---
title: The response, and the headers Node writes for you
version: 1
---

**A response is a status line, headers, and a body, in that order, and Node enforces the order.**
Until the first byte of the body is written, the status and headers can still change; after it, they
have gone to the client and cannot. Three routes show the three ways to write one:

```schooling-example
{"language": "javascript", "file": "respond.js", "parts": [
 {"code": "import http from \"node:http\";\n\nhttp\n  .createServer((req, res) => {\n    if (req.url === \"/whole\") return res.end(\"all at once\\n\");", "note": "The short way: `end` with the whole body. Node adds the status 200, a `Date`, the connection headers, and **a `Content-Length` it counts itself**, because it has the whole body in hand."},
 {"code": "    if (req.url === \"/json\") {\n      const body = JSON.stringify({ ok: true }) + \"\\n\";\n      res.writeHead(201, {\n        \"content-type\": \"application/json; charset=utf-8\",\n        \"content-length\": Buffer.byteLength(body),\n      });\n      return res.end(body);\n    }", "note": "The explicit way: `writeHead` sets the status and the headers in one call. A JSON body needs its own `content-type`; without it, a client is left to guess what the bytes are."},
 {"code": "    if (req.url === \"/pieces\") {\n      res.write(\"first piece\\n\");\n      setTimeout(() => res.end(\"last piece\\n\"), 500);\n      return;\n    }", "note": "**The body in pieces.** After the first `write` Node cannot know the final length, so it switches to `Transfer-Encoding: chunked`: each piece is sent with its own length in front."},
 {"code": "    res.write(\"too late for headers\\n\");\n    try {\n      res.setHeader(\"x-late\", \"yes\");\n    } catch (err) {\n      console.log(err.code);\n    }\n    res.end();\n  })\n  .listen(3000, \"127.0.0.1\");", "note": "A header set after the body has started is too late, and Node throws rather than send it nowhere."}
]}
```

```
ana@dev:~/server/native$ curl -si http://127.0.0.1:3000/whole
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 23:08:41 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Content-Length: 12

all at once
ana@dev:~/server/native$ curl -si http://127.0.0.1:3000/json
HTTP/1.1 201 Created
content-type: application/json; charset=utf-8
content-length: 12
Date: Fri, 16 Oct 2026 23:08:41 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"ok":true}
ana@dev:~/server/native$ curl -si http://127.0.0.1:3000/pieces
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 23:08:41 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

first piece
last piece
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/late
too late for headers
```

**`Content-Length` and `Transfer-Encoding: chunked` are the two ways a client learns where a body
ends**, and a reply always has one of them. Node chose for you each time. Two details in the headers are worth knowing. The length is `Buffer.byteLength(body)` and not
`body.length`, because the header counts bytes and lesson 1's `"olá"` is three characters and four
bytes. And the names you wrote in lower case went out in lower case, while Node's own `Date` and
`Connection` went out capitalised. Both are
fine, because header names are case-insensitive.

The fourth route, in the server's terminal:

```
ana@dev:~/server/native$ node respond.js
ERR_HTTP_HEADERS_SENT
^C
```

**`ERR_HTTP_HEADERS_SENT` is the error of a handler that answers twice**: a `res.end` in an `if`
followed by another at the bottom, or a reply sent from a callback after the main path already sent
one. The fix is a `return` before every reply, which is why every route above starts with
`return res.end` or ends with a `return`.
