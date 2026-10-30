---
title: When to fetch it
version: 1
---

**Code loaded on demand is code somebody waits for.** From the home page, a click on *Minutes per week*
draws the stats page at once, the list and an empty canvas, and the chart a round trip later. How long
that is depends on the network, and `tools/after-click.ts` measures it: it opens a page, clicks, and
reads the mark `chart.ts` leaves when it has drawn. Save it in `tools/`:

```typescript
// tools/after-click.ts: open a page, click something, and say how long after the
// click the chart was drawn, by the mark the page itself makes when it draws one.
//
//   node tools/after-click.ts URL SELECTOR [--slow] [--hover MS]
//
// --slow      every request waits 300 ms longer, as in look.ts
// --hover MS  rest the pointer on the element MS milliseconds before the click, as a person does
import { chromium } from "playwright";

const [url, selector, ...rest] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
if (rest.includes("--slow")) {
  const cdp = await page.context().newCDPSession(page);
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false, latency: 300, downloadThroughput: -1, uploadThroughput: -1,
  });
}
await page.goto(url, { waitUntil: "networkidle" });
if (rest.includes("--hover")) {
  await page.hover(selector);
  await page.waitForTimeout(Number(rest[rest.indexOf("--hover") + 1]));
}
const clicked = await page.evaluate(() => performance.now());
await page.click(selector);
await page.waitForFunction(() => document.documentElement.dataset.chart);
const drawn = Number(await page.evaluate(() => document.documentElement.dataset.chart));
console.log(`chart drawn ${Math.round(drawn - clicked)} ms after the click`);
await browser.close();
```

```
ana@dev:~/planner$ node tools/after-click.ts http://localhost:3000/ "text=Minutes per week" --slow
chart drawn 414 ms after the click
```

**About four hundred milliseconds**, most of it the 300 the network adds to the request for the chunk.
It is not an INP problem: the page answered the click at once, and the chart filled in after. It is still
a wait somebody sees, and on a real phone network it is the length of a round trip to the server, every
first time.

## Fetching a little earlier

**A person's pointer reaches a link before the click**, by a few hundred milliseconds, and a keyboard
reaches it as focus before Enter. Either is a warning that the chart may be needed. In `src/main.ts`,
add these lines after the call to `mount`:

```typescript

// A pointer resting on the link, or the keyboard's focus reaching it, is the warning: the
// chart's code is fetched then, and is usually there by the time of the click.
const warm = (e: Event) => {
  if ((e.target as Element).closest?.('a[href="/stats"]')) import("./chart.ts");
};
addEventListener("pointerover", warm);
addEventListener("focusin", warm);
```

`import()` of a module that is already loading or loaded returns the same promise, so warming it twice,
or warming and then clicking, fetches it once. The click's own `import()` then finds the code there, or
on its way. Build, restart, and measure both ways: clicking straight away, and resting on the link for
300 milliseconds first, as a person does:

```
ana@dev:~/planner$ node tools/after-click.ts http://localhost:3000/ "text=Minutes per week" --slow
chart drawn 406 ms after the click
ana@dev:~/planner$ node tools/after-click.ts http://localhost:3000/ "text=Minutes per week" --slow --hover 300
chart drawn 63 ms after the click
```

**The click that waited on the link drew its chart in a fraction of the time**: the chunk was fetched
while the pointer rested, and the click found it there. The click with no warning is no better than
before, which is the honest limit of the idea.

## Four moments to load at

| moment | how | for what |
|---|---|---|
| **when it is used** | `import()` in the handler, as `mount`'s callback does | anything rare: a dialog, an editor, an export |
| **on a warning** | `import()` on `pointerover` or `focusin`, as here | what a person is about to open |
| **when it comes into view** | an `IntersectionObserver` that calls `import()` | the parts further down a long page |
| **when the browser is idle** | `requestIdleCallback`, or `<link rel="prefetch">` | what most visitors will need soon, fetched at the lowest priority |

**Each moment is a bet about the visitor.** Loading when idle spends the bandwidth of every visitor on
what only some will use, which is fine on a desktop and a cost on a metered phone plan. Loading on use
spends nothing, and makes the people who do use it wait. The warning sits between them and costs a few
lines.
