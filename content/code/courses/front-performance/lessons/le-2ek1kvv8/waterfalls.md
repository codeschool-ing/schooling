---
title: Waterfalls
version: 1
---

**A waterfall is a page's requests drawn as bars along time**, one row per request, in the order
they started. Lighthouse's report has one, the panel's Network track is one, and WebPageTest is known
for its. It is the chart that shows **what waited for what**, which no single number does.

`tools/waterfall.ts` draws one in the terminal: each row is a request, with when it finished, how
many bytes came over the network, and a bar of one `#` per 50 milliseconds. Save it in `tools/`:

```typescript
// tools/waterfall.ts: load a page in Chromium and draw every request it made as
// a bar along time, the way a waterfall chart does.
//
//   node tools/waterfall.ts URL [--slow]
//
// --slow  every request waits 300 ms longer, as in look.ts
import { chromium } from "playwright";

const [url, ...rest] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
if (rest.includes("--slow")) {
  const cdp = await page.context().newCDPSession(page);
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false, latency: 300, downloadThroughput: -1, uploadThroughput: -1,
  });
}
const rows: { path: string; start: number; end: number; bytes: number }[] = [];
page.on("requestfinished", async (request) => {
  const t = request.timing();
  const sizes = await request.sizes();
  rows.push({ path: new URL(request.url()).pathname, start: t.startTime, end: t.startTime + t.responseEnd,
    bytes: sizes.responseBodySize });
});
await page.goto(url, { waitUntil: "networkidle" });
await browser.close();

// One character for every 50 ms, counted from the start of the first request.
const zero = Math.min(...rows.map((r) => r.start));
for (const r of rows.sort((a, b) => a.start - b.start)) {
  const from = Math.round((r.start - zero) / 50), to = Math.max(from + 1, Math.round((r.end - zero) / 50));
  const bar = " ".repeat(from) + "#".repeat(to - from);
  console.log(`${r.path.padEnd(28)} ${String(Math.round(r.end - zero)).padStart(5)} ms ${String(r.bytes).padStart(7)} B  ${bar}`);
}
```

## Two planners, one page

Lesson 1 built the planner twice: rendered in the browser, as `vite preview` serves it, and rendered
by `server.ts`. Start the preview in a second terminal, then draw the course page from each, with every
request 300 milliseconds slower:

```
ana@dev:~/planner$ npx vite preview --port 4173 --strictPort
  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

```
ana@dev:~/planner$ node tools/waterfall.ts http://localhost:3000/courses/git --slow
/courses/git                   304 ms     753 B  ######
/assets/index-C9VFYfGa.js      621 ms    6689 B        ######
/assets/index-CGM1waBA.css     621 ms     274 B        ######
ana@dev:~/planner$ node tools/waterfall.ts http://localhost:4173/courses/git --slow
/courses/git                   305 ms     515 B  ######
/assets/index-C9VFYfGa.js      623 ms    6694 B        ######
/assets/index-CGM1waBA.css     623 ms     371 B        ######
/courses.json                  928 ms     725 B              #######
/notice.json                  1246 ms      78 B                     ######
```

**Two steps for the server's page, four for the browser's.** The server's HTML names the script and
the stylesheet, and the browser asks for both at once, so they share a step. The page rendered in the
browser then has to run its script before it knows it needs `courses.json`, and has to have the plan
before it asks for `notice.json`: each is a round trip that could not start until the one before it
ended. Lighthouse called this the **network dependency tree**, and it is the reason a page rendered in
the browser is slow on a slow network whatever its size: **latency adds up along a chain, and
bandwidth does not shorten it.**

## Reading one

- **A staircase is a chain.** Each step that starts where another ended is a request that was found
  late. The fixes are to put what the page needs into the first response, as `server.ts` does with
  the plan and the notice, or to tell the browser about it early, which lesson 7 does with `preload`.
- **A long bar is a big or a slow response.** Compressing it, as this lesson did, or making it smaller
  shortens the bar and not the chain.
- **Bars side by side are parallel**, and cost one round trip between them.

The bytes are worth a look too: `vite preview` compresses what it sends and `server.ts`, since this
lesson, does as well, so the script is about 6.7 kilobytes over the network from both, against the
seventeen it is on disk. Stop the preview with Ctrl-C when you are done.
