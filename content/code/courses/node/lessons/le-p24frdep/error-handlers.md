---
title: Errors, and the middleware that handles them
version: 1
---

**In Express 5 an error thrown in a route, or a promise a route returns that rejects, goes to the
error handlers instead of ending the process.** That one change is the main reason to be on version 5:
in Express 4 a rejected promise in an `async` route was lesson 2's unhandled rejection, and the
server died exactly as lesson 5's `fragile.js` did.

```javascript
// demo/errors.js
import express from "express";

const app = express();

app.get("/sync", () => {
  throw new Error("thrown in a route");
});
app.get("/async", async () => {
  await new Promise((resolve) => setTimeout(resolve, 10));
  throw new Error("rejected in an async route");
});
app.get("/next", (req, res, next) => {
  next(new Error("passed to next"));
});

app.listen(3000, "127.0.0.1", () => console.log("listening"));
```

```
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/sync
500
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/async
500
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/next
500
```

All three became a 500 and the server stayed up. The third way, **`next(err)`**, is how a callback
that is not a promise reports an error, and how a middleware gives up on a request it cannot
handle.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The path of a request through the Express chain. Normally it passes the logger, the JSON parser and the router, and a route answers. When a route throws, or its promise rejects, Express skips every ordinary middleware still ahead and goes straight to the error handler, the one with four parameters, which answers with a status and a JSON body.\"><rect x=\"20\" y=\"60\" width=\"96\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">log</text><rect x=\"130\" y=\"60\" width=\"116\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"188.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">express.json</text><rect x=\"260\" y=\"60\" width=\"96\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"308.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">router</text><rect x=\"370\" y=\"60\" width=\"96\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">route</text><rect x=\"480\" y=\"60\" width=\"66\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"513.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">404</text><rect x=\"560\" y=\"60\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">(err, req, res, next)</text><line x1=\"116\" y1=\"82\" x2=\"128\" y2=\"82\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"128.0,82.0 120.6,85.1 120.6,78.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"246\" y1=\"82\" x2=\"258\" y2=\"82\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"258.0,82.0 250.6,85.1 250.6,78.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"356\" y1=\"82\" x2=\"368\" y2=\"82\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"368.0,82.0 360.6,85.1 360.6,78.9\" fill=\"var(--phosphor)\"></polygon><text x=\"418\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">answers: 200, 201…</text><path d=\"M418 104 C 418 170, 630 170, 630 108\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"630\" y1=\"116\" x2=\"630\" y2=\"106\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"630.0,106.0 633.1,113.4 626.9,113.4\" fill=\"var(--amber)\"></polygon><text x=\"520\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">throws, or rejects: everything between is skipped</text><text x=\"20\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one request, left to right</text></svg>", "caption": "An error does not travel the chain: it jumps to the one middleware that takes four arguments."}
```

## The default handler says too much

With no handler of your own, Express's default writes the error into the reply. What it writes
depends on `NODE_ENV`:

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/sync | head -8
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Error</title>
</head>
<body>
<pre>Error: thrown in a route<br> &nbsp; &nbsp;at file:///home/ana/server/links/demo/errors.js:7:9<br> &nbsp; &nbsp;at Layer.handleRequest (/home/ana/server/links/node_modules/router/lib/layer.js:152:17)<br> &nbsp; &nbsp;at next (/home/ana/server/links/node_modules/router/lib/route.js:157:13)<br> &nbsp; &nbsp;at Route.dispatch (/home/ana/server/links/node_modules/router/lib/route.js:117:3)<br> &nbsp; &nbsp;at handle (/home/ana/server/links/node_modules/router/index.js:435:11)<br> &nbsp; &nbsp;at Layer.handleRequest (/home/ana/server/links/node_modules/router/lib/layer.js:152:17)<br> &nbsp; &nbsp;at /home/ana/server/links/node_modules/router/index.js:295:15<br> &nbsp; &nbsp;at processParams (/home/ana/server/links/node_modules/router/index.js:582:12)<br> &nbsp; &nbsp;at next (/home/ana/server/links/node_modules/router/index.js:291:5)<br> &nbsp; &nbsp;at Function.handle (/home/ana/server/links/node_modules/router/index.js:186:3)</pre>
```

Stop the server, start it again as `NODE_ENV=production node demo/errors.js`, and ask the same
thing:

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/sync
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Error</title>
</head>
<body>
<pre>Internal Server Error</pre>
</body>
</html>
```

**Unless `NODE_ENV` is `production`, the reply carries the stack trace**: file paths on the server,
the names of the libraries, line numbers. That is lesson 5's rule broken by default, and it is why
the variable matters, which lesson 9 returns to. In production it said only `Internal Server Error`.
Either way it is HTML, which a JSON client does not want.

## Writing your own

An error handler is a middleware with **four** parameters, `(err, req, res, next)`, added after
every route. Express recognises it by that count:

```javascript
// demo/handler.js
import express from "express";

const app = express();
app.use(express.json({ limit: "1kb" }));

app.post("/links", (req, res) => res.status(201).json({ received: req.body }));
app.get("/broken", () => {
  throw new Error("database password rejected");
});

app.use((err, req, res, next) => {
  const status = err.status ?? 500;
  if (status >= 500) console.error(`${req.method} ${req.originalUrl}:`, err);
  res.status(status).json({ error: status >= 500 ? "internal error" : err.message });
});

app.listen(3000, "127.0.0.1", () => console.log("listening"));
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/broken
{"error":"internal error"}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": ' http://127.0.0.1:3000/links
{"error":"Unexpected end of JSON input"}
ana@dev:~/server/links$ head -c 2000 /dev/zero | tr '\0' 'a' | curl -s -H 'content-type: application/json' -d @- http://127.0.0.1:3000/links
{"error":"request entity too large"}
```

**The errors `express.json` raised carry a `status`**, 400 for bad JSON and 413 for too large, so
the handler passes their message on; an error with no status is ours, a 500, and its message stays in
the log, where `database password rejected` belongs. That is lesson 5's edge in six lines, and it
applies to every route the application will ever have.
