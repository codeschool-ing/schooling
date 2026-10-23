---
title: The links service in Express
version: 1
---

**The same service as lesson 5, in the layout of lesson 3, in five small files.** Each section of this
lesson is one piece of it. Replace lesson 4's one-route `server.js`, and add the rest beside
`src/code.js`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The five files of the links service and who imports whom. server.js imports app.js and starts it listening. app.js builds the application and mounts the router from links.js. links.js holds the routes and imports admin.js, for the key, and store.js, for the links. store.js imports code.js, which makes the codes.\"><rect x=\"20\" y=\"90\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">server.js</text><text x=\"90\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">listens</text><rect x=\"180\" y=\"90\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/app.js</text><text x=\"250\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">builds the app</text><rect x=\"350\" y=\"90\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/links.js</text><text x=\"420\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the routes</text><rect x=\"540\" y=\"30\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/admin.js</text><text x=\"610\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the key</text><rect x=\"540\" y=\"150\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/store.js</text><text x=\"610\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the links</text><line x1=\"160\" y1=\"113\" x2=\"178\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"178.0,113.0 170.6,116.1 170.6,109.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"320\" y1=\"113\" x2=\"348\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"348.0,113.0 340.6,116.1 340.6,109.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"490\" y1=\"105\" x2=\"538\" y2=\"60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,60.0 534.8,67.3 530.5,62.8\" fill=\"var(--paper-dim)\"></polygon><line x1=\"490\" y1=\"121\" x2=\"538\" y2=\"168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,168.0 530.6,165.1 534.9,160.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"380\" y=\"175\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">src/code.js</text><text x=\"450\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">makes the codes</text><line x1=\"540\" y1=\"186\" x2=\"522\" y2=\"192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"522.0,192.0 528.0,186.7 530.0,192.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">an arrow: imports</text></svg>", "caption": "One job per file: the rules of the service sit in links.js, and the plumbing around it."}
```

## The store

```javascript
// src/store.js: where the links live. In memory for now; lesson 8 gives it a file.
import { makeCode } from "./code.js";

const links = new Map(); // code -> { code, url, visits, created }

export async function add(url) {
  let code;
  do code = makeCode();
  while (links.has(code));
  const link = { code, url, visits: 0, created: new Date().toISOString() };
  links.set(code, link);
  return link;
}

export async function find(code) {
  return links.get(code);
}

export async function all() {
  return [...links.values()];
}

export async function remove(code) {
  return links.delete(code);
}

export async function visit(code) {
  const link = links.get(code);
  if (link) link.visits++;
  return link;
}
```

**Every function is `async`, though nothing here waits.** Lesson 8 keeps the links in a file, and
writing a file is asynchronous; if the functions returned plain values now, every route would change
then. Written this way, only this file changes.

## The admin key

```javascript
// src/admin.js: a shared key for whoever runs the service.
import { timingSafeEqual } from "node:crypto";

const ADMIN_KEY = "change-me-in-lesson-9"; // lesson 9 moves it to the environment

export function requireKey(req, res, next) {
  const given = Buffer.from(req.get("x-admin-key") ?? "");
  const wanted = Buffer.from(ADMIN_KEY);
  if (given.length !== wanted.length || !timingSafeEqual(given, wanted)) {
    return res.status(401).json({ error: "this needs the admin key" });
  }
  next();
}
```

## The routes

```schooling-example
{"language": "javascript", "file": "src/links.js", "parts": [
 {"code": "// src/links.js: the routes under /links.\nimport express from \"express\";\nimport { requireKey } from \"./admin.js\";\nimport * as store from \"./store.js\";\n\nexport const links = express.Router();\n\nfunction isWebAddress(text) {\n  try {\n    const url = new URL(text);\n    return url.protocol === \"http:\" || url.protocol === \"https:\";\n  } catch {\n    return false;\n  }\n}", "note": "The router for everything under `/links`, and the check from lesson 5 that only web addresses are stored."},
 {"code": "links\n  .route(\"/\")\n  .get(requireKey, async (req, res) => res.json(await store.all()))\n  .post(async (req, res) => {\n    const url = req.body?.url;\n    if (!isWebAddress(url)) return res.status(400).json({ error: \"url must be an http or https address\" });\n    const link = await store.add(url);\n    res.status(201).location(`/links/${link.code}`).json(link);\n  })\n  .all((req, res) => res.set(\"allow\", \"GET, POST\").status(405).json({ error: \"method not allowed\" }));", "note": "**Anybody may create a link; only the admin may list them.** The 201 carries the new link's address in `location`."},
 {"code": "links\n  .route(\"/:code\")\n  .get(async (req, res) => {\n    const link = await store.find(req.params.code);\n    if (!link) return res.status(404).json({ error: `no link ${req.params.code}` });\n    res.json(link);\n  })\n  .delete(requireKey, async (req, res) => {\n    if (!(await store.remove(req.params.code))) return res.status(404).json({ error: `no link ${req.params.code}` });\n    res.status(204).end();\n  })\n  .all((req, res) => res.set(\"allow\", \"GET, DELETE\").status(405).json({ error: \"method not allowed\" }));", "note": "One link: anybody may read it, only the admin may delete it, and the 405 says which methods exist."}
]}
```

## The application

```schooling-example
{"language": "javascript", "file": "src/app.js", "parts": [
 {"code": "// src/app.js: the application, built and not started.\nimport express from \"express\";\nimport { links } from \"./links.js\";\nimport * as store from \"./store.js\";\n\nexport function createApp() {\n  const app = express();", "note": "**`createApp` builds the application and returns it without listening**, lesson 3's reason for two files. A test calls it; `server.js` calls it and listens."},
 {"code": "  app.use((req, res, next) => {\n    res.on(\"finish\", () => console.log(`${req.method} ${req.originalUrl} ${res.statusCode}`));\n    next();\n  });\n  app.use(express.json({ limit: \"1kb\" }));\n  app.use(\"/links\", links);", "note": "The chain, top to bottom: a log line for every request, the JSON body parser, the router."},
 {"code": "  app.get(\"/:code\", async (req, res, next) => {\n    const link = await store.visit(req.params.code);\n    if (!link) return next();\n    res.redirect(302, link.url);\n  });", "note": "**The short link itself.** A code that is not there calls `next()`, and falls through to the 404 below."},
 {"code": "  app.use((req, res) => res.status(404).json({ error: `nothing at ${req.path}` }));\n  app.use((err, req, res, next) => {\n    const status = err.status ?? 500;\n    if (status >= 500) console.error(`${req.method} ${req.originalUrl}:`, err);\n    res.status(status).json({ error: status >= 500 ? \"internal error\" : err.message });\n  });\n\n  return app;\n}", "note": "The 404 for anything that matched nothing, and then the error handler, last."}
]}
```

```javascript
// server.js
import { createApp } from "./src/app.js";

createApp().listen(3000, "127.0.0.1", () => console.log("links on http://127.0.0.1:3000"));
```

Lesson 5's 110 lines are about 100 here across five files, and the difference is not the count. **Each
file has one job**, `src/links.js` is nothing but the rules of the service, and none of the plumbing
is ours to get wrong.

## Using it

```
ana@dev:~/server/links$ curl -si -H 'content-type: application/json' -d '{"url": "https://expressjs.com/"}' http://127.0.0.1:3000/links
HTTP/1.1 201 Created
X-Powered-By: Express
Location: /links/wuhuch
Content-Type: application/json; charset=utf-8
Content-Length: 96
ETag: W/"60-awXfUEWKuqqp75g5Jpz5AyPjMAY"
Date: Fri, 16 Oct 2026 23:20:05 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"code":"wuhuch","url":"https://expressjs.com/","visits":0,"created":"2026-10-16T23:20:05.813Z"}
```

```
ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/wuhuch | head -3
HTTP/1.1 302 Found
X-Powered-By: Express
Location: https://expressjs.com/
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/wuhuch
{"code":"wuhuch","url":"https://expressjs.com/","visits":1,"created":"2026-10-16T23:20:05.813Z"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links
{"error":"this needs the admin key"}
ana@dev:~/server/links$ curl -s -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links
[{"code":"wuhuch","url":"https://expressjs.com/","visits":1,"created":"2026-10-16T23:20:05.813Z"}]
ana@dev:~/server/links$ curl -s -X DELETE -H 'x-admin-key: change-me-in-lesson-9' -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/links/wuhuch
204
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/nothing/here
{"error":"nothing at /nothing/here"}
```

## Testing it

The test starts the application on a port the system picks, asks it questions with `fetch`, and
closes it when the file is done:

```schooling-example
{"language": "javascript", "file": "test/links.test.js", "parts": [
 {"code": "import { test, before, after } from \"node:test\";\nimport assert from \"node:assert/strict\";\nimport { createApp } from \"../src/app.js\";\n\nlet server, base;\nbefore(async () => {\n  server = createApp().listen(0, \"127.0.0.1\");\n  await new Promise((resolve) => server.once(\"listening\", resolve));\n  base = `http://127.0.0.1:${server.address().port}`;\n});\nafter(() => server.close());\n\nconst post = (path, body) =>\n  fetch(base + path, { method: \"POST\", headers: { \"content-type\": \"application/json\" }, body: JSON.stringify(body) });", "note": "**`before` and `after` run once around the file's tests.** Port 0 gives a free port, and `server.close()` in `after` lets the test process finish, lesson 2's rule about what keeps a process alive."},
 {"code": "test(\"a new link answers 201 with its location\", async () => {\n  const res = await post(\"/links\", { url: \"https://example.com/\" });\n  assert.equal(res.status, 201);\n  const link = await res.json();\n  assert.equal(res.headers.get(\"location\"), `/links/${link.code}`);\n});\n\ntest(\"following a link redirects and counts the visit\", async () => {\n  const link = await (await post(\"/links\", { url: \"https://example.com/a\" })).json();\n  const res = await fetch(`${base}/${link.code}`, { redirect: \"manual\" });\n  assert.equal(res.status, 302);\n  assert.equal(res.headers.get(\"location\"), \"https://example.com/a\");\n  const seen = await (await fetch(`${base}/links/${link.code}`)).json();\n  assert.equal(seen.visits, 1);\n});\n\ntest(\"a url that is not a web address is refused\", async () => {\n  const res = await post(\"/links\", { url: \"javascript:alert(1)\" });\n  assert.equal(res.status, 400);\n});", "note": "What the service promises a client: a 201 with a location, a redirect that is counted, a refusal of anything but a web address."},
 {"code": "test(\"deleting needs the admin key\", async () => {\n  const link = await (await post(\"/links\", { url: \"https://example.com/b\" })).json();\n  const res = await fetch(`${base}/links/${link.code}`, { method: \"DELETE\" });\n  assert.equal(res.status, 401);\n});", "note": "And what it promises whoever runs it: nothing is deleted without the key."}
]}
```

```
ana@dev:~/server/links$ npm test

> links@0.1.0 test
> node --test --test-reporter=spec

✔ a code has the right length (0.996466ms)
✔ a code uses only the alphabet (5.434548ms)
✔ isCode refuses what makeCode would never make (0.188832ms)
POST /links 201
✔ a new link answers 201 with its location (62.900467ms)
POST /links 201
GET /wxvhgq 302
GET /links/wxvhgq 200
✔ following a link redirects and counts the visit (8.646862ms)
POST /links 400
✔ a url that is not a web address is refused (2.711347ms)
POST /links 201
DELETE /links/pqw9uc 401
✔ deleting needs the admin key (5.480915ms)
ℹ tests 7
ℹ suites 0
ℹ pass 7
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 236.864328
```

Seven tests: lesson 4's three, and these four. The lines between them are the application's own log,
one per request the tests made. `redirect: "manual"` stops `fetch` following the 302
to `example.com`, so the test sees the redirect itself and never leaves the computer.
