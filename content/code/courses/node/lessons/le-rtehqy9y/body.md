---
title: The body, and what express.json decides
version: 1
---

**`express.json()` has four options, and each one is a decision about what the service accepts.**
The defaults are reasonable for a general server and wrong for most particular ones:

| option | default | what it decides |
|---|---|---|
| `limit` | `"100kb"` | the largest body read before answering 413 |
| `strict` | `true` | only objects and arrays at the top; a bare `"text"` or `42` is refused |
| `type` | `"application/json"` | which `content-type` makes it read the body at all |
| `inflate` | `true` | whether a gzip-compressed body is decompressed |

The links service takes one small object, so it set `limit: "1kb"` in lesson 6. `strict` is worth
seeing, because the error it raises is one the service has to answer well:

```javascript
// demo/body.js
import express from "express";

const app = express();
app.use(express.json({ limit: "1kb" }));
app.post("/links", (req, res) => res.json({ body: req.body ?? "nothing" }));
app.use((err, req, res, next) => res.status(err.status ?? 500).json({ error: err.type ?? "internal" }));
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '"https://example.com/"' http://127.0.0.1:3000/links
{"error":"entity.parse.failed"}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "https://example.com/"}' http://127.0.0.1:3000/links
{"body":{"url":"https://example.com/"}}
ana@dev:~/server/links$ curl -s -X POST http://127.0.0.1:3000/links
{"body":"nothing"}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "https://example.com/", }' http://127.0.0.1:3000/links
{"error":"entity.parse.failed"}
```

**`err.type` names what went wrong in a word a program can test**: `entity.parse.failed` for JSON
that is refused or malformed, `entity.too.large` for a body over the limit. The handler sends the
word rather than the message, which for a parse error quotes the client's own body back at it.

The third request sent no body at all, and `req.body` was `undefined`: Express 5 leaves it unset when
nothing was parsed, where Express 4 set an empty object. **A route reads `req.body?.url`, with the
question mark**, or it throws a `TypeError` on the first request that forgot its body, which was lesson
6's choice and the reason for it.
