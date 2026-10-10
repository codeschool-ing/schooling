---
title: Drawn is not the same as working
version: 1
---

The HTML from `/ssr` draws eight cards, each with an **Add to basket** button. They are real
`<button>` elements, visible and enabled, and **they do nothing** until a script gives each one a
click handler. Frameworks that render on the server call that step **hydration**: the HTML arrives
dry, and a script that comes after it makes it respond. The shop does it by hand, in the file the
server sends from `/slow/ssr.js`. Save it as `app/public/ssr.js`:

```javascript
// Until this file has run, the buttons on /ssr are drawn and do nothing.
for (const button of document.querySelectorAll('button[data-id]')) {
  button.addEventListener('click', async () => {
    const response = await fetch('/api/basket', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: button.dataset.id }),
    });
    const basket = await response.json();
    const count = basket.lines.reduce((n, line) => n + line.qty, 0);
    document.querySelector('[data-testid=basket-count]').textContent = count;
  });
}
document.body.dataset.ready = 'true';
```

Its last line sets `data-ready="true"` on the `<body>`, after every button has its handler. The
next section has a use for it.

## The gap, measured

`look.mjs` from lesson 1 prints every response a page receives, with the milliseconds since it
asked for the page. The home page first:

```
ana@laptop:~/quitanda$ node look.mjs
   17 ms  200 GET /  (document)
   49 ms  200 GET /style.css  (stylesheet)
   50 ms  200 GET /app.js  (script)
   81 ms  200 GET /api/products  (fetch)
   85 ms  200 GET /api/basket  (fetch)
```

Then `/ssr`, with its address as the argument:

```
ana@laptop:~/quitanda$ node look.mjs http://localhost:3000/ssr
   13 ms  200 GET /ssr  (document)
   25 ms  200 GET /style.css  (stylesheet)
 1538 ms  200 GET /slow/ssr.js  (script)
```

On `/`, the products arrive at 81 ms in a request of their own, and until then the list is
empty. On `/ssr` they came with the document at 13 ms, and the script that makes the buttons work
arrived at 1538 ms. **For about a second and a half the page shows eight buttons that ignore
every click.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two timelines from 0 to 1700 milliseconds. The home page, rendered in the browser, shows an empty list until its products arrive at 81 ms and then works. The server-rendered page shows its products from 13 ms, but its buttons do nothing until ssr.js arrives at 1538 ms. A test that clicks as soon as the page has loaded clicks inside that gap.\"><path d=\"M170 250 L690 250\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M170.0 246 L170.0 254\" stroke=\"var(--wire)\"></path><text x=\"170.0\" y=\"272\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">0 ms</text><path d=\"M322.9 246 L322.9 254\" stroke=\"var(--wire)\"></path><text x=\"322.9\" y=\"272\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">500 ms</text><path d=\"M475.9 246 L475.9 254\" stroke=\"var(--wire)\"></path><text x=\"475.9\" y=\"272\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">1000 ms</text><path d=\"M628.8 246 L628.8 254\" stroke=\"var(--wire)\"></path><text x=\"628.8\" y=\"272\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">1500 ms</text><text x=\"690\" y=\"292\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">time since the page was asked for</text><text x=\"20\" y=\"66\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">/</text><text x=\"20\" y=\"84\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">client-side</text><rect x=\"170.0\" y=\"50\" width=\"24.8\" height=\"30\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><rect x=\"194.8\" y=\"50\" width=\"495.2\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"206.8\" y=\"70\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" text-anchor=\"start\">products drawn, buttons work</text><text x=\"170.0\" y=\"40\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">empty list for 81 ms</text><text x=\"20\" y=\"146\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">/ssr</text><text x=\"20\" y=\"164\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">server-side</text><rect x=\"174.0\" y=\"130\" width=\"466.4\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"186.0\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" text-anchor=\"start\">products shown, buttons do nothing</text><rect x=\"640.4\" y=\"130\" width=\"49.6\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"644.4\" y=\"149\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\" text-anchor=\"start\">working</text><path d=\"M174.0 186 L174.0 162\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><path d=\"M174.0 162 L169.0 172 L179.0 172 Z\" fill=\"var(--paper)\"></path><text x=\"174.0\" y=\"202\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\">load: goto returns,</text><text x=\"174.0\" y=\"218\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">and a test clicks here</text><path d=\"M640.4 120 L640.4 170\" stroke=\"var(--phosphor)\" stroke-dasharray=\"3 3\"></path><text x=\"632.4\" y=\"192\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"end\">ssr.js</text><text x=\"632.4\" y=\"208\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"end\">1538 ms</text></svg>", "caption": "The two pages over time, from the look.mjs runs above. The server-rendered page is useful to the eye first and to a click last."}
```

## A test that clicks at once

The obvious test opens the page, clicks Banana's button and checks that the basket says 1. The
`beforeEach` empties the basket first through the shop's reset, because the basket is one list
shared by everybody and an earlier test may have filled it; lesson 15 is about that. Save it as
`tests/ssr.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The basket is shared, so every test starts by emptying it.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a click on /ssr adds to the basket', async ({ page }) => {
  await page.goto('/ssr');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js

Running 1 test using 1 worker

  ✘  1 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket (5.4s)


  1) tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket ────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  getByTestId('basket-count')
    Expected: "1"
    Received: "0"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for getByTestId('basket-count')
        9 × locator resolved to <span data-testid="basket-count">0</span>
          - unexpected value "0"


       9 |   await page.goto('/ssr');
      10 |   await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
    > 11 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
         |                                                  ^
      12 | });
      13 |
        at /home/ana/quitanda/tests/ssr.spec.js:11:50

    Error Context: test-results/ssr-a-click-on-ssr-adds-to-the-basket/error-context.md

  1 failed
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket ─────────────────────────────────────
```

**The click succeeded and the basket stayed at 0.** Playwright did not object to the click itself.
Before clicking, it checks that the element is visible, stable, enabled and not covered by
anything else, which its documentation calls **actionability checks**, and the button passed all
of them. It then waited the five seconds an assertion waits by default for the text to become `1`,
and gave up. No check on the button could have caught this, because a button with no handler and a
button with one look exactly alike from outside.

## Several runs, in case it varies

A timing problem often passes some of the time, so before deciding what to do about one, find out
which kind you have. `--repeat-each` runs the test that many times, `--workers 1` runs the copies
one after another, and `grep` keeps the lines that say how each run ended. The copies run in
parallel by default, and in parallel they would share the shop's one basket, so one copy's click
could show up in another copy's count; that is lesson 15's subject, and here it would only muddy
the answer:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js --repeat-each 5 --workers 1 | grep -E 'passed|failed|✘|✓'
  ✘  1 tests/ssr.spec.js:9:1 › a click on /ssr adds to the basket (5.3s)
  ✘  2 tests/ssr.spec.js:9:1 › a click on /ssr adds to the basket (5.4s)
  ✘  3 tests/ssr.spec.js:9:1 › a click on /ssr adds to the basket (5.3s)
  ✘  4 tests/ssr.spec.js:9:1 › a click on /ssr adds to the basket (5.3s)
  ✘  5 tests/ssr.spec.js:9:1 › a click on /ssr adds to the basket (5.2s)
    Error: expect(locator).toHaveText(expected) failed
    Error: expect(locator).toHaveText(expected) failed
    Error: expect(locator).toHaveText(expected) failed
    Error: expect(locator).toHaveText(expected) failed
    Error: expect(locator).toHaveText(expected) failed
  5 failed
```

Five failures out of five. `page.goto` returns when the page's `load` event has fired, and only
then does the inline script ask for `/slow/ssr.js`; the click lands inside the 1.5 s the server
holds it back, every time. Shorten that pause to a few milliseconds and the same test would pass
on a fast machine and fail on a loaded one, which is the shape of the flaky tests in lesson 14.
