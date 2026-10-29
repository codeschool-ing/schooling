---
title: Offline
version: 1
---

**The only honest test of an offline strategy is the network switched off.** `tools/offline.ts` opens the
first address it is given, waits for the worker to be ready, and opens it again, because **a service worker
controls the pages opened after it was installed, not the page that installed it**. Then it takes the
browser off the network and opens every address, saying what each page showed in its heading and where every
response came from. Save it in `tools/`:

```typescript
// tools/offline.ts: open a page so its service worker installs, open it again so the worker
// controls it, then take the browser off the network and open pages, saying for each what
// it showed and where every response came from.
//
//   node tools/offline.ts URL [URL...]    (the first is visited online; all are opened offline)
import { chromium } from "playwright";

const urls = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext();
const page = await context.newPage();
await page.goto(urls[0], { waitUntil: "networkidle" });
await page.evaluate(() => navigator.serviceWorker.ready);
// A worker controls the pages opened after it was installed, not the one that installed it.
await page.reload({ waitUntil: "networkidle" });
await context.setOffline(true);
for (const url of urls) {
  const served = new Set<string>();
  const log = (r: import("playwright").Response) =>
    served.add(`${new URL(r.url()).pathname} ${r.status()} ${r.fromServiceWorker() ? "from the service worker" : "from the network"}`);
  page.on("response", log);
  try {
    await page.goto(url, { waitUntil: "load" });
    console.log(`${url}: "${await page.textContent("h1")}"`);
  } catch (e) {
    console.log(`${url}: ${(e as Error).message.split("\n")[0]}`);
  }
  page.off("response", log);
  for (const line of served) console.log(`  ${line}`);
}
await browser.close();
```

Visit the Git course, then try it, a course never opened, and the stats page, all offline:

```
ana@dev:~/planner$ node tools/offline.ts http://localhost:3000/courses/git http://localhost:3000/courses/javascript http://localhost:3000/stats
http://localhost:3000/courses/git: "Git"
  /courses/git 200 from the service worker
  /assets/index-DKDcq93q.js 200 from the service worker
  /assets/planner-BNdUlffC.js 200 from the service worker
  /fonts/plex-400.woff2 200 from the service worker
  /covers/git-800.avif 200 from the service worker
  /fonts/plex-700.woff2 200 from the service worker
http://localhost:3000/courses/javascript: "You are offline"
  /courses/javascript 200 from the service worker
http://localhost:3000/stats: "You are offline"
  /stats 200 from the service worker
```

**The Git course opened with no network at all**, every file from the worker: the page from its last copy,
the scripts from the cache, the cover and the fonts from theirs. **The other two showed the offline page**,
which is the network-first strategy's last resort, and better than the browser's own error, because it says
what happened and links to what does work.

## What works offline that was never fetched

**Once the Git page is open, the rest of the planner works offline too**: a click on *All courses* draws the
home page from the plan in the page, with no request, as lesson 8's decision kept it. The page that needs the
network is the one the browser loads, and a planner that navigates by itself needs that only once. The stats
page is the exception: its chart is a chunk loaded on demand, so offline it needs to have been opened once
online for the chunk to be in the cache.

## What it costs online

**A controlled page's every request goes through a script first.** A worker the browser has stopped, which it
does when a site has been idle, must be started before it answers, and on a slow phone that can cost tens of
milliseconds before the first byte of a page. Browsers can start the page's own request in parallel with the
worker, a feature called navigation preload, which a worker turns on in its `activate` event. On a repeat
visit the trade is still good: the scripts, fonts and cover arrive without a round trip, which lesson 9's
304s could not do.
