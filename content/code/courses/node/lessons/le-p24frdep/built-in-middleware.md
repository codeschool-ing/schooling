---
title: The middleware Express ships
version: 1
---

**Express ships a few middleware functions for the work almost every service needs**, and each is a
call that returns a function for `app.use`:

| middleware | what it does | what it leaves in `req` |
|---|---|---|
| `express.json()` | reads a JSON body, with a size limit | `req.body`, an object |
| `express.urlencoded()` | reads a form, `name=value&…` | `req.body`, an object |
| `express.text()`, `express.raw()` | reads a body as a string, or as a Buffer | `req.body` |
| `express.static(dir)` | sends the files in a folder, with types and caching headers | nothing; it answers |

## express.json

It replaces lesson 5's `readJson`, with the same three checks:

```javascript
// demo/json.js
import express from "express";

const app = express();
app.use(express.json({ limit: "1kb" }));

app.post("/links", (req, res) => res.json({ received: req.body }));

app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "https://example.com/"}' http://127.0.0.1:3000/links
{"received":{"url":"https://example.com/"}}
ana@dev:~/server/links$ curl -s -d 'url=https://example.com/' http://127.0.0.1:3000/links
{}
```

**A body that is not JSON is not refused: it is ignored.** `express.json` only reads a request whose
`content-type` says JSON, and passes any other request on with no `req.body` at all, which in
Express 5 is `undefined`. That is why the form got `{}` back: `received` was `undefined`, and JSON
leaves such a property out. So a route that reads `req.body.url` throws a `TypeError` on a form, and a
route that reads `req.body?.url` treats a form as an empty body. Lesson 7 decides which of those the
links service wants. The two failures `readJson` answered itself, too large and badly formed, are
errors that `express.json` passes to the error handler, and the section on error handlers shows what
that does with them.

## express.static

```javascript
// demo/static.js
import express from "express";
import path from "node:path";

const app = express();
app.use(express.static(path.join(import.meta.dirname, "..", "public")));
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ mkdir -p public && echo '<h1>links</h1>' > public/index.html
ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/
HTTP/1.1 200 OK
X-Powered-By: Express
Accept-Ranges: bytes
Cache-Control: public, max-age=0
Last-Modified: Fri, 16 Oct 2026 23:19:53 GMT
ETag: W/"f-1a14703cc20"
Content-Type: text/html; charset=utf-8
Content-Length: 15
Date: Fri, 16 Oct 2026 23:19:53 GMT
Connection: keep-alive
Keep-Alive: timeout=5

<h1>links</h1>

ana@dev:~/server/links$ curl -s -o /dev/null -w "%{http_code}\n" --path-as-is http://127.0.0.1:3000/../package.json
404
```

`express.static` answered `/` with `index.html`, set its type, and added `Last-Modified` and caching
headers. **The folder is built from `import.meta.dirname`**, so the program finds `public` beside the
project whichever folder it was started from, lesson 3's point about `process.cwd()`. And a request
for a path outside the folder is refused: `--path-as-is` makes curl send `/../package.json` as
written instead of tidying it, and the folder held as a boundary.
