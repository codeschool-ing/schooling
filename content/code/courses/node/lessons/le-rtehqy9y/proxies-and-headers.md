---
title: Who is asking, and what to tell them
version: 1
---

**`req.ip` is the address the request came from, and behind a proxy that is the proxy's address.** In
production a Node service usually sits behind one — Nginx, a load balancer, a platform's router — and
every request arrives from it. The proxy says who the real client was in a header,
`X-Forwarded-For`, and Express reads it only when told to trust the proxy that wrote it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Inside one machine, a proxy listens on the public address and passes each request to Node on 127.0.0.1, adding X-Forwarded-For with the address the request really came from. Outside the machine, a client at 203.0.113.9. Node trusts the header only because the proxy, on loopback, is the only thing that can reach it.\"><rect x=\"20\" y=\"80\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a client</text><text x=\"95\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">203.0.113.9</text><rect x=\"230\" y=\"20\" width=\"470\" height=\"210\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"246\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one machine</text><rect x=\"260\" y=\"80\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"340\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the proxy</text><text x=\"340\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">public address, :443</text><rect x=\"500\" y=\"80\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Node, 127.0.0.1:3000</text><text x=\"590\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">trust proxy: \"loopback\"</text><line x1=\"170\" y1=\"115\" x2=\"258\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"258.0,115.0 250.6,118.1 250.6,111.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"420\" y1=\"115\" x2=\"498\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"498.0,115.0 490.6,118.1 490.6,111.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"459\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">X-Forwarded-For:</text><text x=\"459\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">203.0.113.9</text><text x=\"590\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">req.ip = 203.0.113.9</text><text x=\"214\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">internet</text></svg>", "caption": "The header is believed because only the proxy can reach the loopback address. Trust that reaches further lets any client write its own."}
```

```javascript
// demo/ip.js
import express from "express";

const app = express();
if (process.argv[2]) app.set("trust proxy", process.argv[2]);
app.get("/ip", (req, res) => res.json({ ip: req.ip, ips: req.ips }));
app.listen(3000, "127.0.0.1");
```

Ask it with a forged header, first with no trust set:

```
ana@dev:~/server/links$ curl -s -H 'X-Forwarded-For: 203.0.113.9' http://127.0.0.1:3000/ip
{"ip":"127.0.0.1","ips":[]}
```

and again with the server restarted as `node demo/ip.js loopback`:

```
ana@dev:~/server/links$ curl -s -H 'X-Forwarded-For: 203.0.113.9' http://127.0.0.1:3000/ip
{"ip":"203.0.113.9","ips":["203.0.113.9"]}
```

**With no trust, the header is ignored and `req.ip` is the socket's address**, which is the truth.
With `loopback`, Express believes an `X-Forwarded-For` that arrives from `127.0.0.1`, and the forged
address became `req.ip`. That is the right setting when the only thing that can reach the service on loopback is the proxy on
the same machine, and the wrong one anywhere else. **`trust proxy` set to `true` believes the header
from anybody**, so every client can choose the address the logs, the rate limits and the audit trail
record. Trust exactly the proxies you run, by address or by count, and
nothing more. The addresses here are from `203.0.113.0/24`, a range reserved for documentation that
belongs to nobody.

## What the response tells the world

Lesson 6 noted `X-Powered-By: Express`. Two lines remove it and add the header that matters most
for an API:

- **`app.disable("x-powered-by")`**, so that a scan for a vulnerable framework version learns nothing
  from a reply;
- **`X-Content-Type-Options: nosniff`**, which tells a browser to believe the `Content-Type` and never
  guess, so that a JSON body cannot be treated as a script or a page.

A site that serves pages to browsers needs more of them — `Content-Security-Policy`,
`Strict-Transport-Security` and others — and the **`helmet`** package sets a sensible group in one
line; for an API answering JSON these two are the core. The links application with both, and with the
trust a proxy on the same machine needs:

```schooling-example
{"language": "javascript", "file": "src/app.js", "parts": [
 {"code": "// src/app.js: the application, built and not started.\nimport express from \"express\";\nimport { links } from \"./links.js\";\nimport * as store from \"./store.js\";\n\nexport function createApp() {\n  const app = express();\n  app.disable(\"x-powered-by\");\n  app.set(\"trust proxy\", \"loopback\");\n  app.use((req, res, next) => {\n    res.set(\"x-content-type-options\", \"nosniff\");\n    next();\n  });", "note": "**The three lines this lesson adds**, before anything else: no framework name, trust only a proxy on this machine, and `nosniff` on every reply."},
 {"code": "  app.use((req, res, next) => {\n    res.on(\"finish\", () => console.log(`${req.ip} ${req.method} ${req.originalUrl} ${res.statusCode}`));\n    next();\n  });\n  app.use(express.json({ limit: \"1kb\" }));\n  app.use(\"/links\", links);", "note": "The log line now says who asked, which is why the trust setting has to be right."},
 {"code": "  app.get(\"/:code\", async (req, res, next) => {\n    const link = await store.visit(req.params.code);\n    if (!link) return next();\n    res.redirect(302, link.url);\n  });\n\n  app.use((req, res) => res.status(404).json({ error: `nothing at ${req.path}` }));\n  app.use((err, req, res, next) => {\n    const status = err.status ?? 500;\n    if (status >= 500) console.error(`${req.method} ${req.originalUrl}:`, err);\n    res.status(status).json({ error: status >= 500 ? \"internal error\" : err.message });\n  });\n\n  return app;\n}", "note": "The rest is lesson 6's, unchanged."}
]}
```

```
ana@dev:~/server/links$ npm test 2>&1 | grep -E "^(✔|✖|ℹ (tests|pass|fail))"
✔ a code has the right length (0.699116ms)
✔ a code uses only the alphabet (5.934597ms)
✔ isCode refuses what makeCode would never make (0.229715ms)
✔ a new link answers 201 with its location (39.311932ms)
✔ following a link redirects and counts the visit (9.100847ms)
✔ a url that is not a web address is refused (2.763037ms)
✔ deleting needs the admin key (5.822677ms)
ℹ tests 7
ℹ pass 7
ℹ fail 0
```

`grep` keeps only the lines that report a result, without the log lines between them. The seven tests of lesson 6 still pass with the new checks in place. **That is what they were for**:
the routes changed underneath them, and the promises they hold the service to did not.
