---
title: When no route matches
version: 1
---

**When no route matches, the request falls off the end of the chain, and Express answers 404 with
`Cannot GET /path` in HTML.** To answer in the service's own shape, add one middleware after every
route, with the ordinary three parameters: anything that reaches it matched nothing.

```javascript
// demo/notfound.js
import express from "express";

const app = express();

const links = express.Router();
links.get("/", (req, res) => res.json([]));
links.post("/", (req, res) => res.status(201).json({ code: "7ctxqn" }));
links.all("/", (req, res) => res.set("allow", "GET, POST").status(405).json({ error: "method not allowed" }));
app.use("/links", links);

app.use((req, res) => res.status(404).json({ error: `nothing at ${req.path}` }));

app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/nothing
{"error":"nothing at /nothing"}
ana@dev:~/server/links$ curl -si -X DELETE http://127.0.0.1:3000/links | grep -iE "^HTTP|^allow|error"
HTTP/1.1 405 Method Not Allowed
allow: GET, POST
{"error":"method not allowed"}
```

**The 405 is back**, written the way Express allows: `all` matches every method, and placed after the
real ones it catches only the methods they did not. The `Allow` header is written by hand, and it has
to be kept in step with the routes above it, which is the cost of Express not knowing about methods it
was never told.

The 404 handler comes after everything, and **before the error handler**: a 404 is not an error,
only an answer. In the chain of the section on middleware, the links service ends with these two, in
that order.
