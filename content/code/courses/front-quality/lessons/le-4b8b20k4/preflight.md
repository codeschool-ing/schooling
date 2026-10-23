---
title: Simple requests, and the preflight
version: 1
---

**Some cross-origin requests are sent as they are, and the rest are announced first, with a request the
browser sends on its own: the preflight.** The dividing line is what a plain HTML form could already
send before CORS existed, because a server built back then had to cope with those anyway.

A request is **simple** when its method is `GET`, `HEAD` or `POST`, its headers are only the ones a
browser sets plus a few harmless ones, and its `Content-Type`, if any, is one a form can send:
`application/x-www-form-urlencoded`, `multipart/form-data` or `text/plain`. Everything else is
**preflighted**: a `PUT` or a `DELETE`, a custom header such as `Authorization`, or, the case the planner
meets first, a `POST` with `Content-Type: application/json`.

For those, the browser first sends `OPTIONS` to the same address, with two headers saying what is
coming: `Access-Control-Request-Method: POST` and `Access-Control-Request-Headers: content-type`. Only if
the answer allows both does it send the real request. Here is the sign-in, from the page, to the API's
own port:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ 'fetch("http://localhost:3000/api/login", { method: "POST", headers: { "content-type": "application/json" }, body: "{}" }).then((r) => r.status, (e) => String(e))'
request:  POST http://localhost:3000/api/login
console:  Access to fetch at 'http://localhost:3000/api/login' from origin 'http://localhost:5173' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource.
console:  Failed to load resource: net::ERR_FAILED
result:   TypeError: Failed to fetch
```

The console names it: **`Response to preflight request doesn't pass access control check`.** The
request line is the `POST` the page asked for; the `OPTIONS` before it is the browser's own and
Playwright does not list it. Its answer refused, so the `POST` itself never left the browser. That is the preflight doing its job: a server that never
heard of CORS gets an `OPTIONS` it does not understand, not a `POST` it might act on.

`curl` can send the same preflight, to see what the server says:

```
ana@dev:~/planner$ curl -s -i -X OPTIONS -H 'Origin: http://localhost:5173' -H 'Access-Control-Request-Method: POST' -H 'Access-Control-Request-Headers: content-type' http://localhost:3000/api/login
HTTP/1.1 404 Not Found
content-type: application/json
Date: Fri, 23 Oct 2026 23:20:58 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"error":"no such address"}
```

**404, with no CORS headers**, because the planner's server knows nothing about `OPTIONS`. Two fixes
remain: teach the server to answer, which is the next section but one, or never ask a question across
origins at all, which is the section after that.
