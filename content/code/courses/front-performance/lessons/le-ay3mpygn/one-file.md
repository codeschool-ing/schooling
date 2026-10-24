---
title: One file for every page
version: 1
---

**Vite builds the planner into one JavaScript file**, and every page loads all of it: the course page,
the home page, and any page added later. The build says how big it is:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 9 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                  0.69 kB │ gzip: 0.35 kB
dist/assets/index-gserWk4t.css   0.76 kB │ gzip: 0.41 kB
dist/assets/index-yh2nfJj3.js   18.08 kB │ gzip: 6.95 kB

✓ built in 192ms
```

Eighteen kilobytes, seven over the network. For three pages that is fine, and it would stay fine if
the planner never grew. Pages do grow, and what decides whether one file is still right is not its
size but **how much of it a given page uses**.

## How much a page runs

Chromium can say, for every script, which parts of it ran. In its developer tools that is the
**Coverage** panel, under the menu of more tools: reload with it recording, and every script is a row
with its size and the share that never ran, drawn in red. `tools/unused.ts` asks the same question from
a program. Save it in `tools/`:

```typescript
// tools/unused.ts: load a page and say, for each script it downloaded, how much of
// it ever ran: the Coverage panel of the browser's developer tools, as a program.
//
//   node tools/unused.ts URL
import { chromium } from "playwright";

const browser = await chromium.launch();
const page = await browser.newPage();
await page.coverage.startJSCoverage();
await page.goto(process.argv[2], { waitUntil: "networkidle" });
const entries = await page.coverage.stopJSCoverage();
await browser.close();

for (const entry of entries.filter((e) => e.url.includes("/assets/"))) {
  // V8 reports ranges with how often each ran, inner ranges inside outer ones. Applied
  // from the outermost in, each character ends up marked by the innermost range around it.
  const ran = new Uint8Array(entry.source!.length);
  const ranges = entry.functions.flatMap((f) => f.ranges)
    .sort((a, b) => a.startOffset - b.startOffset || b.endOffset - a.endOffset);
  for (const r of ranges) ran.fill(r.count > 0 ? 1 : 0, r.startOffset, r.endOffset);
  const used = ran.reduce((sum, x) => sum + x, 0);
  const kb = (n: number) => `${(n / 1024).toFixed(1)} KB`;
  console.log(`${new URL(entry.url).pathname.padEnd(30)} ${kb(ran.length).padStart(8)}, ran ${kb(used).padStart(8)} (${Math.round(100 * used / ran.length)}%)`);
}
```

The comment in the middle is the only subtle part. V8, Chromium's JavaScript engine, reports a range
for every function and for every block inside a function that did not run, and a block that did not
run can sit inside a function that did. Sorting the ranges from the outermost in, and letting each one
overwrite what it covers, leaves every character marked by the innermost range around it.

```
ana@dev:~/planner$ node tools/unused.ts http://localhost:3000/courses/git
/assets/index-yh2nfJj3.js       17.7 KB, ran   8.2 KB (46%)
```

**Less than half of the planner's script runs on a course page.** That is normal and harmless: the
rest is the home page's drawing, the handlers for clicks that have not happened, the code for a
mismatch that did not occur. A share like this is no reason to split anything. What would be is a
large share of a large file, and the next section makes one.
