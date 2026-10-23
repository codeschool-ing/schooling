---
title: What hydration costs the processor
version: 1
---

**Hydration runs the page's components once more, in the browser, to find out what the server
already knew.** For the planner that is one function call. For a framework it is the whole component
tree, rebuilt in memory and walked over the existing elements. On a laptop it is quick enough not to
notice, and the visitors it matters to are on phones, whose processors are several times slower.

Chromium can slow its own processor down. `tools/cpu.ts` opens a page with the processor slowed four
times, which is roughly a mid-range phone next to the laptop this was recorded on, and reports two of
Chromium's own counters: the time spent running JavaScript, and the time spent on every task of the
main thread, parsing, style, layout and painting included. Each number is the median of five fresh
loads, because one load is noisy. Save it in `tools/`:

```typescript
// tools/cpu.ts: how much work the browser's main thread did to open a page,
// on a processor slowed four times, as a mid-range phone is next to a laptop.
//
//   node tools/cpu.ts URL...
//
// "script" is time spent running JavaScript; "all" is every task on the main
// thread: parsing, style, layout, painting and the scripts. Both come from
// Chromium's own counters, and each is the median of five fresh loads.
import { chromium } from "playwright";

const browser = await chromium.launch();
const median = (xs: number[]) => xs.sort((a, b) => a - b)[Math.floor(xs.length / 2)];
console.log(" script ms   all ms  address");
for (const url of process.argv.slice(2)) {
  const script: number[] = [], all: number[] = [];
  for (let run = 0; run < 5; run++) {
    const page = await browser.newPage();
    const cdp = await page.context().newCDPSession(page);
    await cdp.send("Emulation.setCPUThrottlingRate", { rate: 4 });
    await cdp.send("Performance.enable");
    await page.goto(url, { waitUntil: "networkidle" });
    const { metrics } = await cdp.send("Performance.getMetrics");
    const ms = (name: string) => Math.round(1000 * metrics.find((m) => m.name === name)!.value);
    script.push(ms("ScriptDuration"));
    all.push(ms("TaskDuration"));
    await page.close();
  }
  console.log(`${String(median(script)).padStart(7)}  ${String(median(all)).padStart(7)}  ${url}`);
}
await browser.close();
```

With the planner's `server.ts` on 3000 and lesson 2's four servers on 3001 to 3004, all built as
lesson 3 left them, open the same course page in each:

```
ana@dev:~/planner$ node tools/cpu.ts http://localhost:3000/courses/git http://localhost:3001/courses/git http://localhost:3002/courses/git http://localhost:3003/courses/git http://localhost:3004/courses/git
```

## Reading it

**Next.js again costs the most and SvelteKit the least, but not in proportion to what they sent.**
Next.js sent about five times SvelteKit's JavaScript in lesson 2, and ran about three and a half times
its script time here. And the plain planner, with 2.8 KB, measured as much script time as Angular:
at this size the counters are measuring what any page with a script costs to start, as much as the
framework, and only the large difference stands clear of it. What the numbers do agree with is the
scale: a page with two links and two sessions costs a slowed processor tens of milliseconds to take
over, and a real page, with a hundred components, costs proportionally more, all of it while the
page looks ready.

Lesson 5 gives the cost a name, as part of how quickly a page answers a tap, and lesson 6 opens the
same work in Chromium's performance panel, task by task.
