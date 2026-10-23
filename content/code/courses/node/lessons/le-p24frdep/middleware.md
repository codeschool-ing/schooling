---
title: Middleware
version: 1
---

**A middleware is a function that sees a request on its way to a route, and decides whether to pass
it on.** It has the signature `(req, res, next)`. It can read and change `req` and `res`, answer the
request itself, or call `next()` to hand it to whatever was added after it. Routes are the last
middleware in the chain, and the only difference is that they usually answer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The links application as a chain. A request enters on the left and passes through a logger, the JSON parser, the router for /links, the short-link route and the 404 handler, each calling next() to pass it on. Any of the last four can answer instead. An error anywhere jumps along a dashed path to the error handler at the end.\"><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">request</text><rect x=\"20\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">logger</text><text x=\"70\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">logs at finish</text><line x1=\"120\" y1=\"68\" x2=\"156\" y2=\"68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"156.0,68.0 148.6,71.1 148.6,64.9\" fill=\"var(--phosphor)\"></polygon><text x=\"138\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">next()</text><rect x=\"156\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">express.json</text><text x=\"206\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fills req.body</text><line x1=\"256\" y1=\"68\" x2=\"292\" y2=\"68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"292.0,68.0 284.6,71.1 284.6,64.9\" fill=\"var(--phosphor)\"></polygon><text x=\"274\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">next()</text><rect x=\"292\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"342\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/links</text><text x=\"342\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">router</text><line x1=\"392\" y1=\"68\" x2=\"428\" y2=\"68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"428.0,68.0 420.6,71.1 420.6,64.9\" fill=\"var(--phosphor)\"></polygon><text x=\"410\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">next()</text><line x1=\"342\" y1=\"96\" x2=\"342\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"342.0,140.0 338.9,132.6 345.1,132.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"342\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">res.json(…)</text><rect x=\"428\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"478\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/:code</text><text x=\"478\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">short link</text><line x1=\"528\" y1=\"68\" x2=\"564\" y2=\"68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"564.0,68.0 556.6,71.1 556.6,64.9\" fill=\"var(--phosphor)\"></polygon><text x=\"546\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">next()</text><line x1=\"478\" y1=\"96\" x2=\"478\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"478.0,140.0 474.9,132.6 481.1,132.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"478\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">res.redirect(…)</text><rect x=\"564\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"614\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">404</text><text x=\"614\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">matched nothing</text><line x1=\"614\" y1=\"96\" x2=\"614\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"614.0,140.0 610.9,132.6 617.1,132.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"614\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">res.status(404)</text><rect x=\"560\" y=\"190\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">error handler</text><text x=\"630\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">(err, req, res, next)</text><path d=\"M70 96 L70 212 L556 212\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"548\" y1=\"212\" x2=\"557\" y2=\"212\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"557.0,212.0 549.6,215.1 549.6,208.9\" fill=\"var(--amber)\"></polygon><text x=\"300\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a throw, a rejected promise or next(err), from anywhere</text></svg>", "caption": "Each function answers or calls next(). Order is the order of app.use, and errors skip to the end."}
```

The order of `app.use` and `app.get` calls is the order of the chain. A logger at the top sees every
request, a body parser before the routes gives them `req.body`, and the error handler at the bottom
catches what fell through.

```schooling-example
{"language": "javascript", "file": "demo/chain.js", "parts": [
 {"code": "import express from \"express\";\n\nconst app = express();\n\napp.use((req, res, next) => {\n  const start = performance.now();\n  res.on(\"finish\", () => {\n    console.log(`${req.method} ${req.originalUrl} ${res.statusCode} ${(performance.now() - start).toFixed(1)} ms`);\n  });\n  next();\n});", "note": "**A logger.** It runs before every route and calls `next()` at once. The log line waits for `finish`, the response's own event, so that it can print the status the route chose and how long it took."},
 {"code": "app.use((req, res, next) => {\n  if (req.path === \"/health\") return res.send(\"ok\\n\");\n  next();\n});", "note": "**A middleware that answers.** It ends the chain for one path and passes everything else on. Nothing after it runs for `/health`."},
 {"code": "app.use((req, res, next) => {\n  req.requestId = Math.random().toString(36).slice(2, 8);\n  res.set(\"x-request-id\", req.requestId);\n  next();\n});", "note": "**A middleware that adds to the request.** Every route after it can read `req.requestId`."},
 {"code": "app.get(\"/links\", (req, res) => res.json({ requestId: req.requestId, links: [] }));\napp.get(\"/forgot\", (req, res, next) => {});\n\napp.listen(3000, \"127.0.0.1\");", "note": "Two routes. The second forgets the one rule a middleware has: answer, or call `next()`."}
]}
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/health; curl -s http://127.0.0.1:3000/links
ok

{"requestId":"z5zmod","links":[]}
ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/links | grep -i x-request-id
x-request-id: fpdsjh
ana@dev:~/server/links$ curl -s -m 2 http://127.0.0.1:3000/forgot; echo "curl exit code $?"

curl exit code 28
```

`-m 2` gives curl two seconds and no more. **The last request never got an answer**: the route neither
replied nor called `next()`, so the request sat in the chain with nothing left to move it, and curl gave
up with its exit code 28. Nothing was logged for it either, because `finish` never came. In the
server's terminal:

```
ana@dev:~/server/links$ node demo/chain.js
GET /health 200 2.6 ms
GET /links 200 1.0 ms
GET /links 200 0.5 ms
^C
```

**A request that hangs with no error anywhere is almost always a middleware that forgot `next()`**,
often on one branch of an `if`. That is why every middleware above either returns a reply or ends in
`next()`. The `requestId` here is only an example; a real one comes from `crypto.randomUUID()`, and
is passed on to every service this one calls, so that one request can be followed through all of
them.
