---
title: Measuring the planner
version: 1
---

**The `web-vitals` library measures the three metrics inside the page, exactly as Google's own tools
do**, from the same browser APIs, and calls a function with each value. It is Google's, it is small,
and it is the one this course uses. Install it into the planner, as a dependency of the app this
time rather than a tool, because it runs in every visitor's browser:

```
ana@dev:~/planner$ npm install --save-exact web-vitals@6.2.3

added 1 package, and audited 22 packages in 471ms

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

## Reporting from the page

`src/vitals.ts` asks for all three and prints each to the console as it changes. It uses the
library's **attribution** build, which adds to each value the element or the interaction that caused
it, and for INP the three parts of the section "INP: how long a tap waits". `reportAllChanges` makes
it report every new value rather than only the final one, which is what you want while watching:

```typescript
// src/vitals.ts: measure the three Core Web Vitals of this page, as a visitor's
// browser lives through them, and say each one on the console as it changes.
import { onCLS, onINP, onLCP } from "web-vitals/attribution";

onLCP((m) => console.log(`[vitals] LCP ${Math.round(m.value)} ms ${m.rating} ${m.attribution.target ?? ""}`),
  { reportAllChanges: true });
onINP((m) => {
  const a = m.attribution;
  const parts = [a.inputDelay, a.processingDuration, a.presentationDelay].map(Math.round);
  console.log(`[vitals] INP ${Math.round(m.value)} ms ${m.rating} ${a.interactionTarget ?? ""}`
    + ` (input ${parts[0]}, processing ${parts[1]}, presentation ${parts[2]})`);
}, { reportAllChanges: true });
onCLS((m) => console.log(`[vitals] CLS ${m.value.toFixed(3)} ${m.rating} ${m.attribution.largestShiftTarget ?? ""}`),
  { reportAllChanges: true });
```

## Something real to measure

A real page has something that arrives on its own schedule. The planner gets **a notice for the
week**, from a file the server hands out, shown above the page. Save it as `public/notice.json`:

```json
{ "text": "New this week: every course page shows the day of each session." }
```

`index.html` gets a place for it, a paragraph above `<main>`; add this line just before
`<main id="app"></main>`:

```html
    <p class="notice" id="notice"></p>
```

And two rules at the end of `src/style.css`, one for the notice and one that keeps the empty
paragraph from taking any room:

```css
.notice { margin: 0 0 1rem; padding: 0.75rem 1rem; background: #fef3c7; border-radius: 0.5rem; }
.notice:empty { padding: 0; margin: 0; }
```

`src/main.ts` loads `vitals.ts` first, so the measuring starts before anything else, and fills the
notice at the end. It is written for the section after next, which has the server fill the notice
itself, so the script fetches it only when the paragraph is still empty:

```typescript
// src/main.ts: take the plan the server put in the page, or fetch it, and hand it to the view.
import "./style.css";
import "./vitals.ts";
import type { Plan } from "./planner.ts";
import { mount } from "./view.ts";

const embedded = document.getElementById("plan");
const plan: Plan = embedded
  ? JSON.parse(embedded.textContent!)
  : await (await fetch("/courses.json")).json();
mount(document.querySelector<HTMLElement>("#app")!, plan);

// This week's notice: written by the server when it can, fetched here when it was not.
const box = document.getElementById("notice")!;
if (!box.textContent) {
  const notice: { text: string } = await (await fetch("/notice.json")).json();
  box.textContent = notice.text;
}
```

`textContent` and not `innerHTML`, because the notice is text from a server and must not be read as
HTML.

## The tool

`tools/vitals.ts` opens a page, optionally as a phone, with the network or the processor slowed, and
with one click; it then prints the last value the page reported for each metric. Save it in `tools/`:

```typescript
// tools/vitals.ts: open a page in Chromium and print the last value the page's
// own web-vitals code reported for each metric.
//
//   node tools/vitals.ts URL [--phone] [--slow] [--cpu N] [--click SELECTOR]
//
// --phone      a window 390 pixels wide and 844 high, the size of a common phone
// --slow       every request waits 300 ms longer, as in look.ts
// --cpu N      the processor runs N times slower, as in cpu.ts
// --click SEL  one second after loading, click the element SEL, as a person would
import { chromium } from "playwright";

const [url, ...rest] = process.argv.slice(2);
const option = (name: string) => (rest.includes(name) ? rest[rest.indexOf(name) + 1] : null);
const browser = await chromium.launch();
const page = await browser.newPage(
  rest.includes("--phone") ? { viewport: { width: 390, height: 844 } } : {});
const cdp = await page.context().newCDPSession(page);
if (rest.includes("--slow")) {
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false, latency: 300, downloadThroughput: -1, uploadThroughput: -1,
  });
}
if (option("--cpu")) await cdp.send("Emulation.setCPUThrottlingRate", { rate: Number(option("--cpu")) });
const last = new Map<string, string>();
page.on("console", (m) => {
  const [tag, name] = m.text().split(" ");
  if (tag === "[vitals]") last.set(name, m.text());
});
await page.goto(url, { waitUntil: "networkidle" });
await page.waitForTimeout(1000);
if (option("--click")) {
  await page.click(option("--click")!);
  await page.waitForTimeout(1000);
}
for (const line of last.values()) console.log(line);
// Leaving the page is what makes a page send its final values, as a visitor's would.
await page.goto("about:blank");
await browser.close();
```

Build, restart `server.ts` with `TZ=UTC` as in lesson 4, and measure a course page on a desktop-sized
window with nothing slowed:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/courses/git
[vitals] LCP 100 ms good #notice
[vitals] CLS 0.007 good #app
```

All good, and nothing to learn from it: everything is on one computer. The next two sections slow
things down until each metric has something to say.
