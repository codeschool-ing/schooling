---
title: Measuring the ceiling before the store does
version: 1
---

**A wrapped app is as fast as the page inside it, on the phone it runs on**, and the phones people
own are slower than the computer you build on. The cheapest way to see the ceiling coming is to
measure the planner on your own computer with the processor slowed down, the way Chrome's developer
tools offer for exactly this, and with more data than the demonstration has.

`ceiling.mjs` does both. It saves a plan of N sessions where the planner looks first, slows the
processor, and times two taps from the click to the next frame drawn. Save it beside `look.mjs`:

```javascript
// ceiling.mjs: how long the planner takes to answer a tap when a course has N
// sessions, on a processor slowed down the way DevTools slows it for a phone.
//
//   node ceiling.mjs URL N [SLOWDOWN]
//
// It saves a plan of N sessions where the planner looks first, reloads, and
// times two taps: opening the course, and marking its first session done. A
// tap is timed from the click to the next frame the browser paints.
import { chromium } from "playwright";

const [url, n, slowdown = "4"] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
const cdp = await page.context().newCDPSession(page);
await cdp.send("Emulation.setCPUThrottlingRate", { rate: Number(slowdown) });
await page.goto(url);
await page.evaluate((n) => {
  const plan = { courses: [{ id: "spanish", name: "Spanish A2" }], sessions: [] };
  for (let i = 1; i <= n; i++) {
    plan.sessions.push({ id: `s${i}`, course: "spanish", date: "2026-10-21", minutes: 30, done: false });
  }
  localStorage.setItem("CapacitorStorage.plan", JSON.stringify(plan));
}, Number(n));
await page.reload();
const tap = (name) => page.evaluate(async (name) => {
  const button = [...document.querySelectorAll("button")].find((b) => b.textContent === name);
  const start = performance.now();
  button.click();
  await new Promise((painted) => requestAnimationFrame(() => setTimeout(painted)));
  return Math.round(performance.now() - start);
}, name);
const open = await tap("Spanish A2");
const done = await tap("Mark done");
console.log(`${n} sessions, processor slowed ${slowdown}x: open ${open} ms, mark done ${done} ms`);
await browser.close();
```

It measures the built site rather than the dev server, which adds work of its own. `npm run preview`
serves `dist/` at port 4173, the way a static host would; start it in a terminal of its own, after
`npm run build`, and run the measurement at three sizes, with the processor slowed four times, and
once at full speed:

```
ana@dev:~/planner$ node ceiling.mjs 'http://localhost:4173/?today=2026-10-21' 50
50 sessions, processor slowed 4x: open 56 ms, mark done 20 ms
ana@dev:~/planner$ node ceiling.mjs 'http://localhost:4173/?today=2026-10-21' 500
500 sessions, processor slowed 4x: open 145 ms, mark done 88 ms
ana@dev:~/planner$ node ceiling.mjs 'http://localhost:4173/?today=2026-10-21' 5000
5000 sessions, processor slowed 4x: open 920 ms, mark done 1058 ms
ana@dev:~/planner$ node ceiling.mjs 'http://localhost:4173/?today=2026-10-21' 5000 1
5000 sessions, processor slowed 1x: open 167 ms, mark done 175 ms
```

**The time grows with the number of sessions**: at fifty, a tap answers in a few hundredths of a
second, and at five thousand it takes about a second on the slowed processor, which is long enough for
a person to tap again. At full speed the same tap takes a fraction of that, which is why it never shows
on the computer it was written on.

## Whose ceiling it is

This is the most useful thing the measurement tells you: **the slowness is the planner's, not the
WebView's**. `render()` throws the whole screen away and builds it again on every change, and
`savePlan()` writes the whole plan as one string every time. At fifty sessions that costs nothing; at
five thousand it is the whole cost. A native app written the same way would be slow too.

The fixes are web techniques: update only the item that changed, draw only the rows on the screen,
which is called **virtualising** a list, and keep large data in a file or a database instead of one
preference. React Native's `FlatList`, in lesson 8, virtualises by default, which is one of the real
things the native path buys. **Measure first, then decide whether it is a WebView problem**: most of
the time it is not, and a rewrite would carry the same design to a new platform.

What the measurement cannot show is the phone itself. A slowed desktop processor is a rough model of a
cheap phone, not the phone: memory, the GPU and the WebView's version all differ. The model is good
for one thing, finding out early that a design will not scale, and **the real test is an inexpensive
Android phone**, held in the hand, running the release build.
