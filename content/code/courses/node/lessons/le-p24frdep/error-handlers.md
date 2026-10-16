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
