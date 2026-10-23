---
title: Parameters in the path
version: 1
---

**`/links/7ctxqn` names one link, and the code in it is a parameter.** A table keyed by path cannot
hold one entry per code, so the router has to take the path apart and match its shape. Splitting it
on `/` is enough for this service:

```javascript
// params.js
import http from "node:http";

http
  .createServer((req, res) => {
    const { pathname } = new URL(req.url, "http://localhost");
    let parts;
    try {
      parts = pathname.split("/").filter(Boolean).map(decodeURIComponent);
    } catch {
      res.statusCode = 400;
      return res.end("the path is not valid percent-encoding\n");
    }
    if (parts.length === 2 && parts[0] === "links") return res.end(`the link ${JSON.stringify(parts[1])}\n`);
    res.statusCode = 404;
    res.end(`nothing at ${pathname}\n`);
  })
  .listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/7ctxqn
the link "7ctxqn"
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/caf%C3%A9
the link "café"
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/a%2Fb
the link "a/b"
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/links/%E0%A4%A
the path is not valid percent-encoding
```

**A path arrives percent-encoded**, so a space is `%20` and `é` is `%C3%A9`, and
`decodeURIComponent` turns it back. Two consequences:

- **decode each part after splitting, never the path before.** A code containing `%2F` decodes to
  `/`; decoded first, it would split into two parts and route somewhere else. The third request shows
  it arriving whole, slash included.
- **decoding can fail.** `%E0%A4%A` is not valid UTF-8, and `decodeURIComponent` throws a `URIError`.
  Uncaught, that is a crash on a request anybody can send, which the section on errors in handlers is
  about. Here it is a 400, a client's mistake answered as one.

A parameter is still the client's text. `"7ctxqn"` is a string that may or may not be a code, and
the service looks it up rather than trusting it; lesson 7 validates parameters before they are used.
