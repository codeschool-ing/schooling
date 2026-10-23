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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A request split into the parts Express hands a route. The method GET and the path /links/7ctxqn are matched against the route links.get(&#x27;/:code&#x27;), mounted at /links; the part that matched :code becomes req.params.code. What follows the question mark, limit=2, becomes req.query.limit. Both arrive as strings.\"><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">GET /links/7ctxqn?limit=2</text><line x1=\"218\" y1=\"54\" x2=\"300\" y2=\"54\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"305\" y1=\"54\" x2=\"360\" y2=\"54\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"372\" y1=\"54\" x2=\"448\" y2=\"54\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><rect x=\"150\" y=\"90\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">links.get(\"/:code\")</text><text x=\"250\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mounted at /links</text><line x1=\"258\" y1=\"58\" x2=\"250\" y2=\"88\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"380\" y=\"90\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">req.params.code</text><text x=\"460\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"7ctxqn\"</text><line x1=\"332\" y1=\"58\" x2=\"440\" y2=\"88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><rect x=\"560\" y=\"90\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">req.query.limit</text><text x=\"630\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"2\"</text><line x1=\"410\" y1=\"58\" x2=\"610\" y2=\"88\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"360\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">both are strings, and both were typed by the client</text></svg>", "caption": "The path picks the route and fills params; the query string is a separate object beside it."}
```

**The check is written once and guards every route under the router that names `:code`**, both of
them here, and any added later. A code with a `1` in it, a code of nine characters and a path with a
space are refused before any route runs, and the message quotes the value with `JSON.stringify`, so
that whatever strange characters it holds arrive visibly as text.

**400 and 404 say different things.** `7ctxqn` is a well-formed code that may or may not exist,
which is a question for the store and a 404 if it does not. `seven` could never be a code, so asking
the store is pointless and the answer is the client's mistake, a 400.
