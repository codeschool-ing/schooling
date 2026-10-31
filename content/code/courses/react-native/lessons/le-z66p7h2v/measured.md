---
title: Measuring an animation
version: 1
---

**An animation is a sequence of frames, and the only proof it happened is the sequence.** This program
opens the planner in a browser, goes to *This week*, presses a *Mark done* button, returns to *Courses*
and reads the bar's drawn width every 50 milliseconds. Save it as `frames.mjs`:

```javascript
// frames.mjs: open the Courses tab, go to This week, press a button, come back, and print the
// week bar's drawn width every 50 ms for the next half second.
//
//   node frames.mjs URL BUTTON [--reduced]
//
// --reduced asks the browser for reduced motion, as the phone's accessibility setting would.
import { chromium } from "playwright";

const [url, button, flag] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage({ reducedMotion: flag === "--reduced" ? "reduce" : "no-preference" });
await page.goto(url);
await page.waitForLoadState("networkidle");
await page.getByRole("tab", { name: "This week" }).click(); // Courses stays mounted behind it
const press = await page.getByRole("button", { name: button, exact: true }).elementHandle();
const tab = await page.getByRole("tab", { name: "Courses" }).elementHandle();
// Pressed and measured inside the page, in one go, so the times are the page's own and not
// the program's round trips to the browser.
const widths = await page.evaluate(
  ([press, tab]) =>
    new Promise((done) => {
      press.click();
      tab.click();
      const seen = [];
      const look = () => {
        const bar = document.querySelector('[data-testid="week-done"]');
        seen.push(Math.round(bar.getBoundingClientRect().width));
        if (seen.length < 11) setTimeout(look, 50);
        else done(seen);
      };
      look();
    }),
  [press, tab],
);
console.log("width every 50 ms:", widths.join(" "));
await browser.close();
```

Two details make the numbers honest. The *Courses* tab is opened first, so the bar is already on screen
when the session is marked done; a tab React Navigation had never shown would mount the bar at its new
value, with nothing to animate. And the press, the return and the sampling happen inside the page, in one
`evaluate`, so the 50 milliseconds are the page's own and not the time it takes the program to talk to the
browser.

With the server running and the web build served as in lesson 10:

```
ana@dev:~/planner$ node frames.mjs 'http://localhost:8082/?today=2026-10-21' 'Mark 20 min on 2026-10-21 done'
width every 50 ms: 739 796 861 902 924 934 936 936 936 936 936
```

**739 is 60 percent of the 1232 points the bar can fill, and 936 is 76 percent**: 75 and then 95 of 125
minutes. In between, the width climbs quickly and then slows, 57, 65, 41, 22, 10, 2 points per sample,
which is `Easing.out(Easing.cubic)`, and it arrives within the 300 milliseconds asked for. On the web,
`react-native-web` runs the native driver's animation in JavaScript, since a browser has no separate UI
thread to hand it to; *on a phone the same description runs on the UI thread, which was not measured for
this course*. What the browser proves is the description: the start, the end, the curve and the time.
