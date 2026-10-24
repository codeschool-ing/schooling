---
title: Compressing what the server sends
version: 1
---

**A browser says in every request which compressions it can read**, in the `accept-encoding`
header, and a server that can use one compresses the body and says so in `content-encoding`. Every
browser in use reads `gzip`; most also read `br`, Brotli, which compresses text a little better.
Node has both in `node:zlib`. This section uses `gzip`, because it is the one every client reads.

Three changes to `server.ts`. First the imports: replace the first line with these two, which add
the types of a request and a response, and the compressor:

```typescript
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { gzipSync } from "node:zlib";
```

Then a function every answer goes through. Add it right after the line that defines `esc`:

```typescript
// Every answer goes through here. Text shrinks to a fraction of its size with gzip, and a
// browser says in accept-encoding whether it can read it; vary tells a cache the answer
// depends on that header.
const send = (req: IncomingMessage, res: ServerResponse, type: string, body: string | Buffer) => {
  const gzip = /\bgzip\b/.test(req.headers["accept-encoding"] ?? "");
  res.writeHead(200, { "content-type": type, vary: "accept-encoding", ...(gzip && { "content-encoding": "gzip" }) });
  res.end(gzip ? gzipSync(body) : body);
};
```

`vary` matters for the lessons on caching: a cache that stored one answer for everybody would hand a
compressed page to a client that cannot read it. Lesson 9 is about that header.

Last, the two places that answer with a body use it. In the branch for files, replace the two lines
that write the head and the body with:

```typescript
      send(req, res, types[extname(pathname)] ?? "application/octet-stream", body);
```

and at the end of the page branch, replace the same two lines with:

```typescript
  send(req, res, "text/html; charset=utf-8", html);
```

Restart `server.ts` and ask for the home page the way a browser does:

```
ana@dev:~/planner$ curl -s -H 'accept-encoding: gzip' -o /dev/null -D - http://localhost:3000/ | sed '/^\r$/q'
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
vary: accept-encoding
content-encoding: gzip
Date: Sat, 24 Oct 2026 00:15:14 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked
```

`content-encoding: gzip`: the body that follows is compressed, and the browser undoes it before reading.
Measure again, with the default method:

```
ana@dev:~/planner$ node gen.ts 5000 && npm run lighthouse -- http://localhost:3000/ >/dev/null && node tools/report.ts report.report.json
5000 courses
performance 75, throttling simulate
  FCP  4.3 s    weight 10
  LCP  4.3 s    weight 25
  TBT  10 ms    weight 30
  CLS  0        weight 25
  SI   4.3 s    weight 10
  insight: Use efficient cache lifetimes, Est savings of 18 KiB
  insight: Document request latency, Est savings of 414 KiB
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 300 ms
  request /                            done at    39 ms, 633040 B
  request /assets/index-C9VFYfGa.js    done at    63 ms, 17819 B
  request /assets/index-CGM1waBA.css   done at    63 ms, 538 B
  request /favicon.svg                 done at   102 ms, 9695 B
```

**A hundred, and the LCP went from 4.3 seconds to 1.3.** The HTML went from more than six
hundred kilobytes to about fifty, and the script and the stylesheet are smaller too. Nothing about the
page changed; the same bytes travel in a smaller box.

## Where compression usually lives

**In production a server like `server.ts` rarely compresses for itself.** The reverse proxy in front of
it, nginx or Caddy, or the CDN of lesson 9, does it for every application behind it, and usually with
Brotli as well. Doing it in the application is right here, because there is nothing in front of it. On
a real deployment, check the header of a real response before adding it: compressing twice wastes time,
and compressing nowhere is one of the most common findings Lighthouse makes.

`gzipSync` compresses each answer again, every time. For a page drawn per request that is the price;
for a file that never changes, such as the build's script, a server can compress it once, at build
time, and send the stored copy.
