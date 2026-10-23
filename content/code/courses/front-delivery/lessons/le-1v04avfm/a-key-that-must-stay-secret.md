---
title: When a feature needs a key that must stay secret
version: 1
---

**When a feature needs a secret key, the key goes on a server you control, and the page talks to that
server instead of to the service.** There is no front-end trick that avoids this. Encoding the key,
splitting it, fetching it at start, hiding it in a source map: each one hands it to the browser, and the
browser is the reader's.

The server in question is small. It holds the key in its own environment, accepts one narrow request from
the page, adds the key, and passes the request on. All three hosts with previews run code like this
beside a static site: Vercel and Netlify call them functions, Cloudflare calls them Pages Functions or
Workers. The shape is the same everywhere, so this section builds it with plain Node, on your computer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Three boxes from left to right. The browser holds the page, which knows only the path /api/support. Your server holds SUPPORT_TOKEN in its own environment; it accepts POST /api/support and adds the token. The service checks the token and opens a ticket. A dashed line marks the boundary: everything left of it is the reader&#x27;s, everything right of it is yours.\"><rect x=\"20\" y=\"50\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the browser</text><text x=\"115\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /api/support</text><text x=\"115\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no key in the bundle</text><line x1=\"250\" y1=\"30\" x2=\"250\" y2=\"180\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></line><text x=\"240\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the reader's</text><text x=\"260\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">yours</text><rect x=\"280\" y=\"50\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">your server</text><text x=\"375\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">SUPPORT_TOKEN</text><text x=\"375\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">adds the key</text><rect x=\"510\" y=\"50\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the service</text><text x=\"605\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Authorization: Bearer …</text><text x=\"605\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checks it</text><line x1=\"210\" y1=\"100\" x2=\"280\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"280.0,100.0 272.6,103.1 272.6,96.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"470\" y1=\"100\" x2=\"510\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"510.0,100.0 502.6,103.1 502.6,96.9\" fill=\"var(--paper-dim)\"></polygon></svg>", "caption": "The key stays on the side of the line you control; the page knows a path and nothing else."}
```

## A service that wants a key

The planner gets a *Contact support* feature, and support lives at a service that accepts a request only
with a secret token. This file stands in for that service, which in real life somebody else runs:

```javascript
// support-service.mjs
import { createServer } from "node:http";

createServer((request, response) => {
  if (request.headers.authorization !== "Bearer tok-demo-not-a-real-secret") {
    response.writeHead(401).end("unauthorised\n");
    return;
  }
  response.end("ticket opened\n");
}).listen(9000, "127.0.0.1");
```

## The server that holds the key

And this is the small server of your own. It refuses to start without the key, answers one path and one
method, and never sends the key back:

```schooling-example
{"language": "javascript", "file": "support-proxy.mjs", "parts": [
 {"code": "// support-proxy.mjs\nimport { createServer } from \"node:http\";\n\nconst token = process.env.SUPPORT_TOKEN;\nif (!token) throw new Error(\"SUPPORT_TOKEN is not set\");", "note": "The key comes from this process's environment, which on a host is the functions' own settings. Starting without it is an error, so a missing key fails at deploy rather than on a customer's first request."},
 {"code": "\ncreateServer(async (request, response) => {\n  if (request.method !== \"POST\" || request.url !== \"/api/support\") {\n    response.writeHead(404).end();\n    return;\n  }", "note": "One method on one path. Everything else is a 404, so the server cannot be used to reach anything else the key opens."},
 {"code": "  const reply = await fetch(\"http://127.0.0.1:9000/tickets\", {\n    method: \"POST\",\n    headers: { authorization: `Bearer ${token}` },\n  });\n  response.writeHead(reply.status).end(await reply.text());\n}).listen(8787, \"127.0.0.1\");", "note": "The key is added here, on the way out, and only the service's answer goes back to the page."}
]}
```

Started without its key, the proxy stops at once and says why:

```
ana@dev:~/planner$ node support-proxy.mjs
file:///home/ana/planner/support-proxy.mjs:5
if (!token) throw new Error("SUPPORT_TOKEN is not set");
                  ^

Error: SUPPORT_TOKEN is not set
    at file:///home/ana/planner/support-proxy.mjs:5:19
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)

Node.js v22.22.0
```

Start the service in one terminal, and the proxy with its key in another:

```
ana@dev:~/planner$ SUPPORT_TOKEN=tok-demo-not-a-real-secret node support-proxy.mjs
```

Then, from a third, ask each of them for a ticket the way a page would:

```
ana@dev:~/planner$ curl -s -X POST http://127.0.0.1:9000/tickets
unauthorised
ana@dev:~/planner$ curl -s -X POST http://127.0.0.1:8787/api/support
ticket opened
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8787/anything-else
404
```

**The service refuses anybody without the key, and the proxy gets a ticket without the caller ever
seeing it.** A page would call `/api/support`, and the bundle would contain that path and nothing else.

## What the proxy now owes

Moving the key to a server does not make the feature safe by itself. The proxy is a public address that
spends your key on every request, so it carries the duties the key used to:

- **narrow**: one action, the one the page needs, as here; never a general "forward anything" proxy;
- **limited**: a cap on how often one visitor may call it, or the key's quota is anybody's to burn;
- **honest about who is asking**: if the action belongs to a signed-in user, the proxy checks the
  session before spending the key. Front-quality lessons 5 and 6 are about sessions and tokens.

These two files were for this section only; the planner does not keep them. Stop both servers and
delete the files.
