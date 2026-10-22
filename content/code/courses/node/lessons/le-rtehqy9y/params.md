---
title: Route parameters, checked once
version: 1
---

**A route parameter is text the client chose**, and lesson 6's routes handed `req.params.code`
straight to the store. That worked because the store only looks things up, and a code that is not
there is simply not found. It stops working the day a parameter is used for anything else — a file
name, a database query, a line in a log — so the habit is worth having from the first route.

The links service already knows what a code is: lesson 4's `isCode`, six characters from the
alphabet. Express can run a check whenever a route with a given parameter matches, with
`router.param`:

```javascript
// demo/param.js
import express from "express";
import { isCode } from "../src/code.js";

const links = express.Router();

links.param("code", (req, res, next, code) => {
  if (!isCode(code)) return res.status(400).json({ error: `${JSON.stringify(code)} is not a link code` });
  next();
});

links.get("/:code", (req, res) => res.json({ code: req.params.code }));
links.delete("/:code", (req, res) => res.status(204).end());

const app = express();
app.use("/links", links);
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxqn
{"code":"7ctxqn"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxq1
{"error":"\"7ctxq1\" is not a link code"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxqnabc
{"error":"\"7ctxqnabc\" is not a link code"}
ana@dev:~/server/links$ curl -s -X DELETE http://127.0.0.1:3000/links/a%20b
{"error":"\"a b\" is not a link code"}
```

**The check is written once and guards every route under the router that names `:code`**, both of
them here, and any added later. A code with a `1` in it, a code of nine characters and a path with a
space are refused before any route runs, and the message quotes the value with `JSON.stringify`, so
that whatever strange characters it holds arrive visibly as text.

**400 and 404 say different things.** `7ctxqn` is a well-formed code that may or may not exist,
which is a question for the store and a 404 if it does not. `seven` could never be a code, so asking
the store is pointless and the answer is the client's mistake, a 400.
