---
title: Two rules
version: 1
---

**Every file the planner sends falls under one of two rules**, and which one depends on its name.

- **A file whose name carries a hash of its contents**, `index-B_kobX3K.js`, never changes at that
  address: a different content gets a different name, so the HTML of the next build points somewhere
  else. It can be kept for a year without asking: `public, max-age=31536000, immutable`.
- **Everything else** can change at the same address: the pages, the plan, the notice, the pictures and
  the fonts, which are in `public/` under names that do not change. It is kept and checked every time:
  `no-cache`, with an `ETag` to check it by.

Vite writes the first kind into `dist/assets/` and nothing else does, so the rule is a test of the path.

## In server.ts

`send` gets a fifth argument, the `Cache-Control` to send, and an ETag of its own, a SHA-1 of the body,
which it compares with the browser's `If-None-Match` before sending anything. First the import, after
the one of `node:zlib`:

```typescript
import { createHash } from "node:crypto";
```

Then replace `send`, with its comment, with this, which also defines the rule:

```typescript
// Every answer goes through here. Text shrinks with gzip when the browser can read it;
// cache says how long it may be kept; and the ETag, a hash of the body, lets a browser
// that has a copy ask "is it still this?" and be told 304 instead of sent it again.
const send = (req: IncomingMessage, res: ServerResponse, type: string, body: string | Buffer, cache: string) => {
  const etag = `"${createHash("sha1").update(body).digest("base64url")}"`;
  const head = { "content-type": type, vary: "accept-encoding", "cache-control": cache, etag };
  if (req.headers["if-none-match"] === etag) {
    res.writeHead(304, head).end();
    return;
  }
  const gzip = /\bgzip\b/.test(req.headers["accept-encoding"] ?? "");
  res.writeHead(200, { ...head, ...(gzip && { "content-encoding": "gzip" }) });
  res.end(gzip ? gzipSync(body) : body);
};
// A file whose name carries a hash of its contents never changes, so it may be kept a year
// without asking; anything else is kept and checked again every time.
const cacheFor = (pathname: string) =>
  pathname.startsWith("/assets/") ? "public, max-age=31536000, immutable" : "no-cache";
```

The ETag is the hash of the body before compression, so the same page has the same ETag whether it was
sent with gzip or without. A 304 carries no body and no `content-encoding`, only the headers of the copy
the browser already has. And the two calls pass a rule. In the branch for files:

```typescript
      send(req, res, types[extname(pathname)] ?? "application/octet-stream", body, cacheFor(pathname));
```

and in the page branch:

```typescript
  send(req, res, "text/html; charset=utf-8", html, "no-cache");
```

Restart `server.ts`, and come back:

```
ana@dev:~/planner$ node tools/revisit.ts http://localhost:3000/courses/git
/courses/git                   200, downloaded again
/fonts/plex-400.woff2          200, downloaded again
/fonts/plex-700.woff2          200, downloaded again
/assets/index-B_kobX3K.js      200, downloaded again
/assets/planner-BNdUlffC.js    200, downloaded again
/covers/git-800.avif           200, downloaded again
```

**The two scripts came from the cache without a request, and everything else was a 304.** The page, the
fonts and the cover were asked about and kept; nothing was downloaded twice. A deploy still reaches every
visitor at once: the new HTML is a new ETag, so it is downloaded, and it names the new scripts by their new
names.
