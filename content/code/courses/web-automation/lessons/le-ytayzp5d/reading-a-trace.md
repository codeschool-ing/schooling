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
ana@laptop:~/quitanda$ unzip -l test-results/ssr-a-click-on-ssr-at-once/trace.zip
Archive:  test-results/ssr-a-click-on-ssr-at-once/trace.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
      579  2026-10-15 22:10   resources/src@5921d20bcda9502b03b2934047b8bcfb583299f4.txt
   106675  2026-10-15 22:10   resources/b257c4396365f6539681cc8303663e5eac455c34
     1510  2026-10-15 22:10   resources/628a1333a8dfd0f160cc4e4cb8592bb74a469b4c
    43452  2026-10-15 22:10   resources/725b004999c58a1604cdd2ee106b533de29ff6ec
    11358  2026-10-15 22:10   test.trace
     1913  2026-10-15 22:10   1-trace.trace
     1203  2026-10-15 22:10   1-trace.network
       14  2026-10-15 22:10   resources/e7e8acd9614309b836bf29744b10316e7e9ae74c.json
      142  2026-10-15 22:10   1-trace.stacks
    13105  2026-10-15 22:10   0-trace.trace
     5812  2026-10-15 22:10   0-trace.network
     2459  2026-10-15 22:10   resources/page@aa3c39622ffb7ae6bcfd9f587212f268-1792113041311.jpeg
    27130  2026-10-15 22:10   resources/page@aa3c39622ffb7ae6bcfd9f587212f268-1792113041354.jpeg
     2198  2026-10-15 22:10   resources/7bee19e04ab4993856ea04974b35e260df2b5230.html
     1240  2026-10-15 22:10   resources/39dfe74803f515f71990df1b2934669d13b07de7.css
      124  2026-10-15 22:10   0-trace.stacks
---------                     -------
   218914                     16 files
```

Three kinds of file, and their names say which:

- **`0-trace.trace`** and **`0-trace.network`** are the browser's side, one JSON object per line:
  the actions with their times, and every request with its response. `1-trace.*` is the same for
  the `request` fixture that emptied the basket before the test; `test.trace` is the test runner's
  own steps, hooks and fixtures included.
- **`resources/`** holds what the lines point at: the page's HTML and stylesheet, the `jpeg`
  frames of the screen, and, by their sizes, three files you have met. 106675 bytes is
  `video.webm`, 43452 is the screenshot and 1510 is the error context: the trace carries a copy of
  every attachment, which is why it is the biggest file in the folder.
- **`*.stacks`** maps each action to the line of the test that made it.

## When the click happened

Every line of `0-trace.trace` that starts an action has a `"type":"before"`, a `"method"` naming
the action, and a `"startTime"` in milliseconds on the trace's own clock:

```
ana@laptop:~/quitanda$ unzip -p test-results/ssr-a-click-on-ssr-at-once/trace.zip 0-trace.trace | grep '"type":"before"' | grep -o '"method":"[a-zA-Z]*"\|"startTime":[0-9.]*' | paste - -
"startTime":2109.897	"method":"newPage"
"startTime":2149.969	"method":"goto"
"startTime":2191.589	"method":"click"
"startTime":2281.868	"method":"expect"
```

Every line of `0-trace.network` has the address, the `"time"` the request took, and when it
started on the same clock, `"_monotonicTime"`:

```
ana@laptop:~/quitanda$ unzip -p test-results/ssr-a-click-on-ssr-at-once/trace.zip 0-trace.network | grep -o '"url":"[^"]*"\|"time":[0-9.]*\|"_monotonicTime":[0-9.]*' | paste - - -
"time":5.396000000000001	"url":"http://localhost:3000/ssr"	"_monotonicTime":2157.931
"time":5.26	"url":"http://localhost:3000/style.css"	"_monotonicTime":2169.836
"time":1504.583	"url":"http://localhost:3000/slow/ssr.js"	"_monotonicTime":2178.162
```

Put the two on one line. `goto` started at 2150.0. `/slow/ssr.js` was requested at 2178.2 and took
1504.6 ms, so it arrived at **3682.8**. The click started at **2191.6**, thirteen milliseconds after
the script was asked for and **1491 ms before it arrived**. The assertion started at 2281.9 and,
with its five seconds, gave up at about 7282. And the network file has no fourth line: **no
`POST /api/basket` was ever sent**. The click landed on a button with no handler yet, and the
request that would have changed the count was never made. Of the four stories, that leaves one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A timeline of the failing test, from its trace. The page is requested at 8 ms and answers in 5. The script /slow/ssr.js is requested at 28 ms and arrives at 1533 ms. The click happens at 42 ms, 13 ms after the script was asked for and nearly a second and a half before it arrived. The assertion starts at 132 ms and gives up at 5132 ms. No POST to /api/basket was ever sent.\"><path d=\"M170.0 33 L170.0 39\" stroke=\"var(--wire)\"></path><text x=\"170.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M265.0 33 L265.0 39\" stroke=\"var(--wire)\"></path><text x=\"265.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><path d=\"M360.0 33 L360.0 39\" stroke=\"var(--wire)\"></path><text x=\"360.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2000</text><path d=\"M455.0 33 L455.0 39\" stroke=\"var(--wire)\"></path><text x=\"455.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3000</text><path d=\"M550.0 33 L550.0 39\" stroke=\"var(--wire)\"></path><text x=\"550.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4000</text><path d=\"M645.0 33 L645.0 39\" stroke=\"var(--wire)\"></path><text x=\"645.0\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5000</text><text x=\"170.0\" y=\"240\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milliseconds after goto</text><text x=\"20\" y=\"54\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET /ssr</text><text x=\"20\" y=\"86\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET /slow/ssr.js</text><text x=\"20\" y=\"118\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">click</text><text x=\"20\" y=\"150\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">expect</text><text x=\"20\" y=\"182\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">POST /api/basket</text><rect x=\"170.8\" y=\"42\" width=\"2\" height=\"16\" rx=\"2\" fill=\"var(--scan)\"></rect><rect x=\"172.7\" y=\"74\" width=\"142.9\" height=\"16\" rx=\"2\" fill=\"var(--scan)\"></rect><circle cx=\"315.6\" cy=\"82\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"325.6\" y=\"86\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">script arrives, 1533 ms</text><circle cx=\"174.0\" cy=\"114\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"186.0\" y=\"118\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">click, 42 ms</text><path d=\"M174.0 119 L174.0 206\" stroke=\"var(--amber)\" stroke-dasharray=\"3 3\"></path><rect x=\"182.5\" y=\"138\" width=\"475.0\" height=\"16\" rx=\"2\" fill=\"var(--panel)\"></rect><rect x=\"182.5\" y=\"138\" width=\"475.0\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\"></rect><circle cx=\"657.5\" cy=\"146\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"647.5\" y=\"172\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">gives up, 5132 ms</text><text x=\"190.5\" y=\"182\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">never sent</text></svg>", "caption": "The trace of the failing click, drawn to scale. The click lands while the script that would have heard it is still on its way, and the request it should have caused never appears."}
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
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/search.spec.js

Running 1 test using 1 worker

  ✘  1 evidence/search.spec.js:5:1 › typed key by key, the list settles on papaya (6.2s)
```

The six search requests, out of its network file:

```
ana@laptop:~/quitanda$ unzip -p test-results/search-*/trace.zip 0-trace.network | grep -o '"url":"[^"]*search?[^"]*"\|"time":[0-9.]*\|"_monotonicTime":[0-9.]*' | paste - - - | grep search
"time":6.488	"url":"http://localhost:3000/api/search?q=papaya"	"_monotonicTime":2331.021
"time":156.255	"url":"http://localhost:3000/api/search?q=papay"	"_monotonicTime":2319.92
"time":304.797	"url":"http://localhost:3000/api/search?q=papa"	"_monotonicTime":2317.998
"time":455.45799999999997	"url":"http://localhost:3000/api/search?q=pap"	"_monotonicTime":2313.911
"time":602.719	"url":"http://localhost:3000/api/search?q=pa"	"_monotonicTime":2309.842
"time":754.2520000000001	"url":"http://localhost:3000/api/search?q=p"	"_monotonicTime":2305.811
```

**The file lists responses in the order they finished**, and that order is the defect. Add each
`time` to its start: the answer to `papaya` arrived first, at about 2338, and the answer to `p`,
asked first, arrived last, at **3060.1**. Now the actions:

```
ana@laptop:~/quitanda$ unzip -p test-results/search-*/trace.zip 0-trace.trace | grep '"type":"before"' | grep -o '"method":"[a-zA-Z]*"\|"startTime":[0-9.]*' | paste - -
"startTime":2144.525	"method":"newPage"
"startTime":2200.275	"method":"goto"
"startTime":2254.442	"method":"type"
"startTime":2342.834	"method":"expect"
"startTime":3238.033	"method":"expect"
```

The first `expect`, the one waiting for `aria-busy="false"`, started at 2342.8; the second, the
one reading the list, at **3238.0**, after the answer to `p` had replaced it. The trace shows the
test read the list 178 ms after the stale answer arrived, so it could only ever see three fruit.
The terminal said *expected Papaya, received three*; the trace says which response put them there.

## What the viewer adds

The viewer shows the same lines as a timeline you can click, and for each action the page as it
was, rebuilt from the snapshots in `resources/`, with the network and console panels of lesson 1
beside it. That is faster than `grep` on the day you know what you are looking for and on the
day you do not. Its documentation also offers `trace.playwright.dev`, a page that opens a trace
inside your own browser without sending the file anywhere.
