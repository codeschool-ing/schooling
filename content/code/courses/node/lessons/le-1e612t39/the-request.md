---
title: The request, as Node hands it over
version: 1
---

**The request object carries the request line and the headers, already parsed, and the body as a
stream.** A server that only reports what it received shows all of it:

```javascript
// echo.js: say what arrived.
import http from "node:http";

http
  .createServer((req, res) => {
    const url = new URL(req.url, "http://localhost");
    res.setHeader("content-type", "text/plain; charset=utf-8");
    res.end(
      [
        `method:  ${req.method}`,
        `url:     ${req.url}`,
        `path:    ${url.pathname}`,
        `query:   ${JSON.stringify(Object.fromEntries(url.searchParams))}`,
        `version: HTTP/${req.httpVersion}`,
        `headers: ${JSON.stringify(req.headers)}`,
        `raw:     ${JSON.stringify(req.rawHeaders)}`,
        "",
      ].join("\n"),
    );
  })
  .listen(3000, "127.0.0.1");
```

With it running in one terminal, ask it something from the other, with a header of your own in mixed
case:

```
ana@dev:~/server/native$ curl -s -H 'X-Request-Id: abc-123' 'http://127.0.0.1:3000/links/7ctxqn?visits=1&format=json'
method:  GET
url:     /links/7ctxqn?visits=1&format=json
path:    /links/7ctxqn
query:   {"visits":"1","format":"json"}
version: HTTP/1.1
headers: {"host":"127.0.0.1:3000","user-agent":"curl/8.5.0","accept":"*/*","x-request-id":"abc-123"}
raw:     ["Host","127.0.0.1:3000","User-Agent","curl/8.5.0","Accept","*/*","X-Request-Id","abc-123"]
```

Read it line by line, because each is a rule:

- **`req.url` is not a URL.** It is the path and the query exactly as the client sent them, with no
  host. `new URL(req.url, "http://localhost")` gives it a base so that the URL parser can split it;
  the base is never used for anything else.
- **The query string is the client's text.** `searchParams` decodes it into names and values, and
  every value is a string: `visits` is `"1"`, not `1`.
- **`req.headers` has every name in lower case**, whatever the client wrote: `X-Request-Id` arrived as
  `x-request-id`. HTTP header names are case-insensitive, so Node normalises them once, and
  `req.headers["content-type"]` is the only spelling that works. `req.rawHeaders` keeps the original
  text, in pairs, for the rare program that needs it.
- **`host` came from the client too.** It says which name the client used to reach you, and a client
  can put anything there; never use it to decide who somebody is.

`curl -v` prints the request it sent, which is the other half of the same picture: the lines starting
with `>` are what reached the server.

```
ana@dev:~/server/native$ curl -sv http://127.0.0.1:3000/ 2>&1 | grep '^>'
> GET / HTTP/1.1
> Host: 127.0.0.1:3000
> User-Agent: curl/8.5.0
> Accept: */*
> 
```
