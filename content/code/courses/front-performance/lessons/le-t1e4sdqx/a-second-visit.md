---
title: A second visit, measured
version: 1
---

**`tools/revisit.ts` loads a page, then loads it again in the same browser**, the way a visitor comes
back, and says for each request of the second visit which of the three things happened. Save it in
`tools/`:

```typescript
// tools/revisit.ts: load a page, then load it again in the same browser, as a
// visitor coming back, and say how each request of the second visit was answered:
// from the cache without asking, with a 304 that let the browser keep its copy, or
// downloaded again.
//
//   node tools/revisit.ts URL
import { chromium } from "playwright";

const url = process.argv[2];
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(url, { waitUntil: "networkidle" });

// The DevTools protocol says what the page's own API does not: whether a request reached the
// network at all, and the status the server really sent, which for a 304 is not the one the page sees.
const cdp = await page.context().newCDPSession(page);
await cdp.send("Network.enable");
const rows = new Map<string, { path: string; cached: boolean; status?: number }>();
cdp.on("Network.requestWillBeSent", (e) => {
  // A data: address is part of the page, not a request to anybody.
  if (e.request.url.startsWith("http")) rows.set(e.requestId, { path: new URL(e.request.url).pathname, cached: false });
});
cdp.on("Network.requestServedFromCache", (e) => { const row = rows.get(e.requestId); if (row) row.cached = true; });
cdp.on("Network.responseReceivedExtraInfo", (e) => { const row = rows.get(e.requestId); if (row) row.status = e.statusCode; });
await page.goto(url, { waitUntil: "networkidle" });
await browser.close();
for (const r of rows.values()) {
  const how = r.cached ? "from the cache, not asked" : r.status === 304 ? "304, kept its copy" : `${r.status}, downloaded again`;
  console.log(`${r.path.padEnd(30)} ${how}`);
}
```

The page's own APIs report a revalidated response as a 200, the status of the copy the browser ended up
using; the protocol of the developer tools reports the status that crossed the network, which is the one
that tells a 304 from a download. With `server.ts` running as lesson 8 left it:

```
ana@dev:~/planner$ node tools/revisit.ts http://localhost:3000/courses/git
/courses/git                   200, downloaded again
/fonts/plex-400.woff2          200, downloaded again
/fonts/plex-700.woff2          200, downloaded again
/assets/index-B_kobX3K.js      200, downloaded again
/assets/planner-BNdUlffC.js    200, downloaded again
/covers/git-800.avif           200, downloaded again
```

**Everything downloaded again.** `server.ts` sends no `Cache-Control`, no `ETag` and no `Last-Modified`,
so the browser had neither a lifetime nor anything to check its copies with. A second visit costs exactly
what the first did. `curl -I` shows the headers of one of the planner's scripts:

```
ana@dev:~/planner$ curl -sI http://localhost:3000/assets/$(ls dist/assets | grep -m1 '^index.*js')
HTTP/1.1 200 OK
content-type: text/javascript
vary: accept-encoding
Date: Sat, 24 Oct 2026 01:03:10 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

Not one of them is about caching. The two rules of the next section fix that.
