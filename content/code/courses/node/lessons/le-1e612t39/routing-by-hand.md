---
title: Routing by hand
version: 1
---

**Routing is choosing what to do from the method and the path, and with `node:http` it is an `if`
you write.** Every request arrives at one function. The method and the path together name an action:
`GET /links` lists, `POST /links` creates, and the same path with an unknown method is not a missing
page but a method the resource does not support.

```javascript
// routes.js
import http from "node:http";

const routes = {
  "/links": {
    GET: (req, res) => res.end("the list of links\n"),
    POST: (req, res) => res.end("a new link\n"),
  },
  "/health": {
    GET: (req, res) => res.end("ok\n"),
  },
};

http
  .createServer((req, res) => {
    const { pathname } = new URL(req.url, "http://localhost");
    const route = routes[pathname];
    if (!route) {
      res.statusCode = 404;
      return res.end(`nothing at ${pathname}\n`);
    }
    const handler = route[req.method];
    if (!handler) {
      res.writeHead(405, { allow: Object.keys(route).join(", ") });
      return res.end(`${req.method} is not allowed on ${pathname}\n`);
    }
    handler(req, res);
  })
  .listen(3000, "127.0.0.1");
```

A table of paths, each with a table of methods, is the whole router. Ask it four things:

```
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links
the list of links
ana@dev:~/server/native$ curl -s -X POST http://127.0.0.1:3000/links
a new link
ana@dev:~/server/native$ curl -si -X DELETE http://127.0.0.1:3000/links
HTTP/1.1 405 Method Not Allowed
allow: GET, POST
Date: Fri, 16 Oct 2026 23:08:43 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

DELETE is not allowed on /links
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/nothing
nothing at /nothing
ana@dev:~/server/native$ curl -s 'http://127.0.0.1:3000/health?verbose=1'
ok
```

**404 and 405 are different answers, and the difference matters to a client.** A 404 says the
resource does not exist, so asking again is pointless. A 405 says it exists and does not do that,
and the `Allow` header, which HTTP requires on a 405, says what it does do. A router that answers 404
for everything it does not handle is telling a client that `/links` does not exist on the day its
`DELETE` was not written yet.

The routing is on `pathname`, not `req.url`, so a query string does not make a route miss:
`/health?verbose=1` reached the `/health` handler. A trailing slash does make one miss here —
`/links/` is a different path — and whether it should is a decision each router makes; Express makes
it in lesson 6.
