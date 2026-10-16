---
title: The explicit wait, a loop with a clock
version: 1
---

**An explicit wait is a loop written at the one place it is needed: a condition, asked again and
again, until it holds or a clock runs out.** Three numbers describe any of them: how long it may
last, how often it asks, and what it asks. The implicit wait in the last section fixed the first
for the whole session and could only ever ask one question, *does something match this locator*.
An explicit wait lets each line of a test choose all three.

## In Selenium: `driver.wait`

`driver.wait(condition, timeout)` is the whole mechanism. The `until` module holds ready-made
conditions, `elementLocated`, `elementTextIs`, `elementIsVisible`, `titleIs` and a dozen others, and
each is a function that answers *not yet* or a value. The installed source of `selenium-webdriver`
4.51 gives the defaults:

```
ana@laptop:~/quitanda$ grep -n 'wait(condition, timeout = 0' node_modules/selenium-webdriver/lib/webdriver.js
858:  wait(condition, timeout = 0, message = undefined, pollTimeout = 200) {
```

Two of them matter. **The wait asks every 200 ms** unless you pass a fourth argument. And **a
timeout of `0`, the default, means no limit**: `driver.wait(until.elementLocated(...))` with no
second argument waits for ever, which on a build server means until something else kills the job.
Always pass the timeout.

This test is the `/ssr` click from the last section done properly. It waits for the ready marker,
clicks, and waits for the count; the implicit wait stays at its default of zero. Save it as
`selenium/ssr.test.js`:

```javascript
import { test, before, after } from 'node:test';
import { Builder, By, until } from 'selenium-webdriver';
import chrome from 'selenium-webdriver/chrome.js';

const shop = 'http://localhost:3000';
let driver;

before(async () => {
  const options = new chrome.Options().addArguments('--headless=new');
  driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
});

after(async () => {
  await driver?.quit();
});

test('a click on /ssr counts once the page is ready', async () => {
  await fetch(`${shop}/api/reset`, { method: 'POST' });
  await driver.get(`${shop}/ssr`);
  await driver.wait(until.elementLocated(By.css('body[data-ready="true"]')), 5000);
  await driver.findElement(By.css('[data-testid=product-banana] button')).click();
  const count = await driver.findElement(By.css('[data-testid=basket-count]'));
  await driver.wait(until.elementTextIs(count, '1'), 5000);
});
```

With the shop started:

```
ana@laptop:~/quitanda$ node --test --test-reporter=tap selenium/ssr.test.js
TAP version 13
# Subtest: a click on /ssr counts once the page is ready
ok 1 - a click on /ssr counts once the page is ready
  ---
  duration_ms: 2287.296376
  type: 'test'
  ...
1..1
# tests 1
# suites 0
# pass 1
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 2663.874181
```

The test has no `assert`, and needs none: **a wait that times out throws**, and a thrown error is a
failed test. The last line is the check.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two lanes on one timeline of the server-rendered page, from 0 to 2000 milliseconds. The implicit wait finds the button at 30 ms, because it exists from the start, and the click at about 140 ms is lost. The page script has run at about 1500 ms. The explicit wait asks for the ready marker every 200 ms, gets no for every look until 1400 ms, and yes at 1600 ms, when the click works.\"><path d=\"M562.9 30 L562.9 200\" stroke=\"var(--phosphor)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><text x=\"556.9\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"end\">ssr.js has run</text><text x=\"20\" y=\"70\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">implicit wait</text><text x=\"20\" y=\"88\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">findElement</text><path d=\"M170.0 66 L690.0 66\" stroke=\"var(--scan)\" stroke-width=\"1\"></path><circle cx=\"177.8\" cy=\"66\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"187.8\" y=\"54\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">found at once</text><path d=\"M202.4 76 L212.4 86 M212.4 76 L202.4 86\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"219.4\" y=\"86\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" text-anchor=\"start\">click lost</text><text x=\"20\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">explicit wait</text><text x=\"20\" y=\"168\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">driver.wait</text><path d=\"M170.0 146 L690.0 146\" stroke=\"var(--scan)\" stroke-width=\"1\"></path><circle cx=\"170.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"222.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"274.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"326.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"378.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"430.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"482.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"534.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"586.0\" cy=\"146\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"598.0\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"start\">true: now click</text><text x=\"170.0\" y=\"176\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">asks every 200 ms, for up to 5000 ms</text><path d=\"M170 214 L690 214\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M170.0 210 L170.0 218\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"170.0\" y=\"234\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">0 ms</text><path d=\"M300.0 210 L300.0 218\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"300.0\" y=\"234\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">500 ms</text><path d=\"M430.0 210 L430.0 218\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"430.0\" y=\"234\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">1000 ms</text><path d=\"M560.0 210 L560.0 218\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"560.0\" y=\"234\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">1500 ms</text><path d=\"M690.0 210 L690.0 218\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"690.0\" y=\"234\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">2000 ms</text><text x=\"690\" y=\"256\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">time since the page loaded</text></svg>", "caption": "The same page, two waits. The implicit wait ends when the button exists; the explicit wait ends when the page is ready. Times from the run in the last section."}
```

## In Playwright: assertions and `waitFor`

Playwright writes the loop for you in two places, and lesson 10 named both. A **web-first
assertion**, `expect(locator).toHaveText(...)` and its relatives, is an explicit wait whose
condition is the assertion itself. Its timeout is five seconds by default. Its interval is not a
fixed number: the installed code checks once at once, then again after 100, 250, 500 and 1000 ms,
and every second after that, so a quick answer is seen quickly and a slow one does not cost a
request every few milliseconds. That arithmetic is the count in every call log: one look, then
looks at 100, 350 and 850 ms, then one a second, makes the *9 ×* lesson 3 printed in five seconds.

`locator.waitFor()` is the other. It waits for an element to reach a **state**, `attached`,
`detached`, `visible` or `hidden`, `visible` unless you say otherwise, and checks nothing about its
text or its value. It suits a step whose next line is not an assertion:

```javascript
await page.locator('body[data-ready="true"]').waitFor({ state: 'attached' });
```

The state matters here: `<body>` counts as visible, but a marker element hidden with CSS would never
be, and `waitFor()` with no state would wait for it until it timed out.

**Prefer the assertion when the wait is the check, and `waitFor` when it is only a gate before an
action.** Both are explicit, both have a timeout, both stop the moment their condition holds. When
neither ready-made condition fits, the next section writes one.
