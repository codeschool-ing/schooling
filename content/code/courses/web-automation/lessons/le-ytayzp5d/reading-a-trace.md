---
title: Reading a trace without the viewer
version: 1
---

The trace viewer of lesson 10 draws a trace as a timeline, a list of actions and a picture of the
page at each one. **It was not run for this course**, because it opens a window and the machine
these lessons were recorded on has no screen. That turns out to cost little: a trace is a zip
archive of text files, and the lines that explain a failure can be found with `unzip` and `grep`.
Doing it once by hand also shows what the viewer is drawing from, which helps the day it draws
something you do not believe.

## What is in the zip

```
%%CAP trace-list%%
```

Three kinds of file, and their names say which:

- **`0-trace.trace`** and **`0-trace.network`** are the browser's side, one JSON object per line:
  the actions with their times, and every request with its response. `1-trace.*` is the same for
  the `request` fixture that emptied the basket before the test; `test.trace` is the test runner's
  own steps, hooks and fixtures included.
- **`resources/`** holds what the lines point at: the page's HTML and stylesheet, the `jpeg`
  frames of the screen, and, by their sizes, three files you have met. 114572 bytes is
  `video.webm`, 43452 is the screenshot and 1510 is the error context: the trace carries a copy of
  every attachment, which is why it is the biggest file in the folder.
- **`*.stacks`** maps each action to the line of the test that made it.

## When the click happened

Every line of `0-trace.trace` that starts an action has a `"type":"before"`, a `"method"` naming
the action, and a `"startTime"` in milliseconds on the trace's own clock:

```
%%CAP trace-actions%%
```

Every line of `0-trace.network` has the address, the `"time"` the request took, and when it
started on the same clock, `"_monotonicTime"`:

```
%%CAP trace-network%%
```

Put the two on one line. `goto` started at 2426.4. `/slow/ssr.js` was requested at 2679.3 and took
1504.4 ms, so it arrived at **4183.7**. The click started at **2690.3**, eleven milliseconds after
the script was asked for and **1493 ms before it arrived**. The assertion started at 2796.7 and,
with its five seconds, gave up at about 7797. And the network file has no fourth line: **no
`POST /api/basket` was ever sent**. The click landed on a button with no handler yet, and the
request that would have changed the count was never made. Of the four stories, that leaves one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A timeline of the failing test, from its trace. The page is requested at 9 ms and answers in 220. The script /slow/ssr.js is requested at 253 ms and arrives at 1757 ms. The click happens at 264 ms, 11 ms after the script was asked for and nearly a second and a half before it arrived. The assertion starts at 370 ms and gives up at 5370 ms. No POST to /api/basket was ever sent.\"><path d=\"M170.0 33 L170.0 39\" stroke=\"var(--wire)\"></path><text x=\"170.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M265.0 33 L265.0 39\" stroke=\"var(--wire)\"></path><text x=\"265.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><path d=\"M360.0 33 L360.0 39\" stroke=\"var(--wire)\"></path><text x=\"360.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2000</text><path d=\"M455.0 33 L455.0 39\" stroke=\"var(--wire)\"></path><text x=\"455.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3000</text><path d=\"M550.0 33 L550.0 39\" stroke=\"var(--wire)\"></path><text x=\"550.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4000</text><path d=\"M645.0 33 L645.0 39\" stroke=\"var(--wire)\"></path><text x=\"645.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5000</text><text x=\"170.0\" y=\"240\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milliseconds after goto</text><text x=\"20\" y=\"54\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET /ssr</text><text x=\"20\" y=\"86\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET /slow/ssr.js</text><text x=\"20\" y=\"118\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">click</text><text x=\"20\" y=\"150\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">expect</text><text x=\"20\" y=\"182\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">POST /api/basket</text><rect x=\"170.8\" y=\"42\" width=\"20.9\" height=\"16\" rx=\"2\" fill=\"var(--scan)\"></rect><rect x=\"194.0\" y=\"74\" width=\"142.9\" height=\"16\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"336.9\" cy=\"82\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"346.9\" y=\"86\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">script arrives, 1757 ms</text><circle cx=\"195.1\" cy=\"114\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"207.1\" y=\"118\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">click, 264 ms</text><path d=\"M195.1 119 L195.1 206\" stroke=\"var(--amber)\" stroke-dasharray=\"3 3\"></path><rect x=\"205.2\" y=\"138\" width=\"475.0\" height=\"16\" rx=\"2\" fill=\"var(--panel)\"></rect><rect x=\"205.2\" y=\"138\" width=\"475.0\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\"></rect><circle cx=\"680.2\" cy=\"146\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"670.2\" y=\"172\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">gives up, 5370 ms</text><text x=\"213.2\" y=\"182\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">never sent</text></svg>", "caption": "The trace of the failing click, drawn to scale. The click lands while the script that would have heard it is still on its way, and the request it should have caused never appears."}
```

This is lesson 6's diagnosis, reached here without reading the page's code: the trace alone says
the click came before the script, and the fix is to wait for the page to be ready, as lesson 6
does. A developer handed this trace instead of *the test is flaky* has the timing to act on.

## The search race, from its trace

Lesson 3's race leaves a trace that tells its story the same way. The test types `papaya` key by
key and waits for the page to stop being busy. Save it as `evidence/search.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Fails on purpose: the search race of lesson 3. The answer to "p"
// arrives last and replaces the list.
test('typed key by key, the list settles on papaya', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});
```

```
%%CAP search-run%%
```

The six search requests, out of its network file:

```
%%CAP search-network%%
```

**The file lists responses in the order they finished**, and that order is the defect. Add each
`time` to its start: the answer to `papaya` arrived first, at about 2208, and the answer to `p`,
asked first, arrived last, at **2936.0**. Now the actions:

```
%%CAP search-actions%%
```

The first `expect`, the one waiting for `aria-busy="false"`, started at 2213.9; the second, the
one reading the list, at **3097.3**, after the answer to `p` had replaced it. The trace shows the
test read the list 161 ms after the stale answer arrived, so it could only ever see three fruit.
The terminal said *expected Papaya, received three*; the trace says which response put them there.

## What the viewer adds

The viewer shows the same lines as a timeline you can click, and for each action the page as it
was, rebuilt from the snapshots in `resources/`, with the network and console panels of lesson 1
beside it. That is faster than `grep` on the day you know what you are looking for and on the
day you do not. Its documentation also offers `trace.playwright.dev`, a page that opens a trace
inside your own browser without sending the file anywhere.
