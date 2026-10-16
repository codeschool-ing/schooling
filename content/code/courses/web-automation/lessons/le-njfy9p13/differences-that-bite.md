---
title: Differences that bite
version: 1
---

The comfortable belief is that a test which passes headless passes headed, and the reverse,
because it is the same browser. **The engine is the same; the window, the name and the fonts are
not**, and a test that depends on any of the three can pass in one mode and fail in another. Here
is one that does, written the way a developer at a big monitor might write it.

## A test that trusts the window

The test checks that all eight products fit on the first screen, with nothing to scroll. Its
author turned off Playwright's viewport because they wanted *the real window*, the one they saw on
their desk. Save it as `tests/headless.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// No viewport: the page is as big as the browser's window, whatever that is.
test.use({ viewport: null });

test('every product is fully on the first screen', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
  await expect(page.getByTestId('product-pineapple')).toBeInViewport({ ratio: 1 });
});
```

`toBeInViewport({ ratio: 1 })` passes when the whole element is inside the visible area; Pineapple
is the last card, so if it fits, all of them do. In the default mode, the headless shell:

```
ana@laptop:~/quitanda$ npx playwright test tests/headless.spec.js

Running 1 test using 1 worker

  ✓  1 tests/headless.spec.js:6:1 › every product is fully on the first screen (192ms)

  1 passed (1.7s)
```

In new headless, through the projects of `headless.config.js`:

```
ana@laptop:~/quitanda$ npx playwright test --config headless.config.js --project=new-headless tests/headless.spec.js

Running 1 test using 1 worker

  ✘  1 [new-headless] › tests/headless.spec.js:6:1 › every product is fully on the first screen (5.5s)


  1) [new-headless] › tests/headless.spec.js:6:1 › every product is fully on the first screen ──────

    Error: expect(locator).toBeInViewport() failed

    Locator:  getByTestId('product-pineapple')
    Expected: in viewport
    Received: viewport ratio 0.36936089396476746
    Timeout:  5000ms

    Call log:
      - Expect "toBeInViewport" with timeout 5000ms
      - waiting for getByTestId('product-pineapple')
        9 × locator resolved to <li class="card" id="card-5500" data-testid="product-pineapple">…</li>
          - unexpected value "viewport ratio 0.36936089396476746"


       7 |   await page.goto('/');
       8 |   await expect(page.locator('#products li')).toHaveCount(8);
    >  9 |   await expect(page.getByTestId('product-pineapple')).toBeInViewport({ ratio: 1 });
         |                                                       ^
      10 | });
      11 |
        at /home/ana/quitanda/tests/headless.spec.js:9:55

    Error Context: test-results/headless-every-product-is-fully-on-the-first-screen-new-headless/error-context.md

  1 failed
    [new-headless] › tests/headless.spec.js:6:1 › every product is fully on the first screen ───────
```

And headed, under Xvfb:

```
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed tests/headless.spec.js

Running 1 test using 1 worker

  ✓  1 tests/headless.spec.js:6:1 › every product is fully on the first screen (340ms)

  1 passed (1.9s)
```

**Pass, fail, pass, and the shop did not change.** The failure says how much of the card it could
see: `viewport ratio 0.369…`, a little over a third. The section on two headless Chromiums measured
why. Each mode invents a window, and new headless invents the shortest one, 493 pixels tall. At 780
wide, the shop's grid puts three products in a row. Pineapple is in the third row:

```
ana@laptop:~/quitanda$ node -e "import('@playwright/test').then(async ({ chromium }) => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 780, height: 493 } }); await p.goto('http://localhost:3000/'); console.log(await p.getByTestId('product-pineapple').boundingBox()); await b.close(); })"
{ x: 270.65625, y: 443.875, width: 238.671875, height: 133 }
```

Its top at 443.875 and its height of 133 put its bottom at 576.875, past 493 and inside the shell's 600 and
the Xvfb window's 917.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 1080 300\" role=\"img\" aria-label=\"Four rectangles drawn to one scale, all starting at the top: the shell's own window, 800 by 600; new headless, 780 by 493; headed under Xvfb, 1050 by 917; and Playwright's viewport, 1280 by 720. A band across all of them marks the pineapple card, from 443.875 to 576.875 pixels down. It sits fully inside every rectangle except new headless, whose bottom edge at 493 cuts through it.\"><rect x=\"20\" y=\"40\" width=\"200\" height=\"150\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the shell</text><text x=\"20\" y=\"32\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">800x600</text><rect x=\"26\" y=\"151\" width=\"48\" height=\"33\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"></rect><text x=\"20\" y=\"208\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">fully inside</text><rect x=\"238.0\" y=\"40\" width=\"195\" height=\"123\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"238.0\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">new headless</text><text x=\"238.0\" y=\"32\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">780x493</text><rect x=\"244.0\" y=\"151\" width=\"48\" height=\"33\" fill=\"var(--scan)\" stroke=\"var(--amber)\"></rect><text x=\"238.0\" y=\"181\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">cut off at 493</text><rect x=\"451.0\" y=\"40\" width=\"262\" height=\"229\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"451.0\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">headed, Xvfb</text><text x=\"451.0\" y=\"32\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1050x917</text><rect x=\"457.0\" y=\"151\" width=\"48\" height=\"33\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"></rect><text x=\"451.0\" y=\"287\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">fully inside</text><rect x=\"731.5\" y=\"40\" width=\"320\" height=\"180\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"731.5\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Playwright's viewport</text><text x=\"731.5\" y=\"32\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1280x720</text><rect x=\"737.5\" y=\"151\" width=\"48\" height=\"33\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"></rect><text x=\"731.5\" y=\"238\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">fully inside</text><text x=\"80\" y=\"169\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pineapple card</text></svg>", "caption": "Each mode invents its own window, and only one of them cuts the card. Playwright's default viewport is the same rectangle in all three."}
```

**The test was never about the shop**; it was about whichever window the browser happened to open.
On the author's desk it passed. On a build server it passes or fails depending on which Chromium
the configuration names, and switching from the shell to new headless, which looks like a change
of nothing, turns it red.

## The fix is to choose the size

Delete the `test.use` line, and the test runs at Playwright's 1280 by 720 in every mode. Pinning
the size is a decision about what *the first screen* means, and the test can say so out loud. The
second test below checks the size it ran at, so a change to the default arrives as a failure with
a number in it, not as a layout surprise. The third reads lesson 7's deals page with a
headless user agent. Save the file again as `tests/headless.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('every product is fully on the first screen', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
  await expect(page.getByTestId('product-pineapple')).toBeInViewport({ ratio: 1 });
});

test('the page is the size the test asked for', async ({ page }) => {
  await page.goto('/');
  expect(page.viewportSize()).toEqual({ width: 1280, height: 720 });
  expect(await page.evaluate(() => innerWidth)).toBe(1280);
});

test('a headless desktop browser gets the desktop deals page', async ({ page }) => {
  await page.goto('/deals');
  await expect(page.getByText('Weekly deals, in a table.')).toBeVisible();
});
```

```
ana@laptop:~/quitanda$ npx playwright test --config headless.config.js tests/headless.spec.js

Running 6 tests using 2 workers

  ✓  2 [shell] › tests/headless.spec.js:3:1 › every product is fully on the first screen (282ms)
  ✓  3 [shell] › tests/headless.spec.js:9:1 › the page is the size the test asked for (177ms)
  ✓  1 [new-headless] › tests/headless.spec.js:3:1 › every product is fully on the first screen (384ms)
  ✓  4 [shell] › tests/headless.spec.js:15:1 › a headless desktop browser gets the desktop deals page (138ms)
  ✓  5 [new-headless] › tests/headless.spec.js:9:1 › the page is the size the test asked for (269ms)
  ✓  6 [new-headless] › tests/headless.spec.js:15:1 › a headless desktop browser gets the desktop deals page (152ms)

  6 passed (2.7s)
```

```
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed tests/headless.spec.js

Running 3 tests using 1 worker

  ✓  1 tests/headless.spec.js:3:1 › every product is fully on the first screen (440ms)
  ✓  2 tests/headless.spec.js:9:1 › the page is the size the test asked for (194ms)
  ✓  3 tests/headless.spec.js:15:1 › a headless desktop browser gets the desktop deals page (241ms)

  3 passed (2.4s)
```

**Nine green lines across three modes.** A phone is a different question: lesson 7 tested the
narrow window with a device descriptor, which sets the size on purpose, and that is the same fix
seen from the other side.

## The name a site reads

The deals page looks for `Mobile` and nothing else, so `HeadlessChrome` is just a desktop browser
to it, and the third test holds that. **Other sites read the same string for other reasons.** Some
analytics tools drop visits whose user agent says headless; some sites send a challenge page to
anything that looks automated, and `navigator.webdriver` is one of the signs they check. A test
of your own site against those rules is testing a different page from the one people see.

The tester's way out is to make it explicit, never to hide it. In a test environment, ask the
developers for a setting that lets the suite's traffic through, and keep a test that proves the
setting is off in production. A `userAgent` in a project's `use`, the way the device descriptors
set one, changes what the server reads; it does not change `navigator.webdriver`, and a test that
needs to pretend to be a person is a sign the environment is wrong.

## The fonts

The last difference has no failing test here, because the machine is the same in every mode. A
headless run on a build server and a headed run on a laptop are two machines, and `system-ui`
names a different font on each. A card's title that fits on one line in one wraps in the other,
and every screenshot comparison between them fails on pixels nobody can see a problem in. Lesson
16 compares screenshots, and its rule follows from this one: **take the reference image on the
same kind of machine, in the same mode, that the comparison will run in.**
