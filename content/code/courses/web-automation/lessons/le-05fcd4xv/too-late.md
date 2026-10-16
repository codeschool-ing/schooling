---
title: When waiting too long fails
version: 1
---

**Everything so far has been about waiting long enough. A state that does not last turns the
problem round: a test that arrives after it has gone fails, and no timeout can help it.** The
usual belief is that a patient test is a safe test, that a wait which gives up only after ten
seconds can only ever be more reliable than one that gives up after five. That holds for a state
that arrives and stays. The shop's toast arrives and leaves.

## A message that lasts two seconds

When you add a fruit, `app.js` writes *Added Banana* into the `.toast` paragraph and, with a
`setTimeout`, empties it again two seconds later. The paragraph never goes away; only its text
does. A person glances at it and moves on. A test has to read it inside those two seconds.

This test does the order most people would write first: click, check the basket, then the toast.
A sleep sits between them, the kind that stays in a suite after somebody added it to make a
different failure go away, and the toast's assertion has been given a generous ten seconds. Save
it as `tests/toast.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('adding a banana says so', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button').click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await page.waitForTimeout(2000); // let the basket settle
  await expect(page.locator('.toast')).toHaveText('Added Banana', { timeout: 10000 });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/toast.spec.js

Running 1 test using 1 worker

  ✘  1 tests/toast.spec.js:7:1 › adding a banana says so (12.4s)


  1) tests/toast.spec.js:7:1 › adding a banana says so ─────────────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  locator('.toast')
    Expected: "Added Banana"
    Received: ""
    Timeout:  10000ms

    Call log:
      - Expect "toHaveText" with timeout 10000ms
      - waiting for locator('.toast')
        14 × locator resolved to <p role="status" class="toast"></p>
           - unexpected value ""


      10 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
      11 |   await page.waitForTimeout(2000); // let the basket settle
    > 12 |   await expect(page.locator('.toast')).toHaveText('Added Banana', { timeout: 10000 });
         |                                        ^
      13 | });
      14 |
        at /home/ana/quitanda/tests/toast.spec.js:12:40

    Error Context: test-results/toast-adding-a-banana-says-so/error-context.md

  1 failed
    tests/toast.spec.js:7:1 › adding a banana says so ──────────────────────────────────────────────
```

**The assertion looked 14 times in ten seconds and found an empty paragraph every time.**
The call log says the locator *resolved*, so the element was there; what it held was `""`. By the
time the assertion began, the message had been shown and taken away, and asking again for ten
seconds, or a hundred, asks about a page that will never say it again. The ten-second timeout
changed one thing: how long the test took to fail.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A timeline from the click. The toast says Added Banana from 0 to 2000 ms and is empty after. The test that looks first is satisfied at once. The test that sleeps for 2000 ms starts looking just after the text has gone and keeps looking for 10 seconds, finding an empty paragraph every time.\"><text x=\"20\" y=\"50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">the toast</text><rect x=\"170.0\" y=\"34\" width=\"320.0\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"330.0\" y=\"50\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"middle\">Added Banana</text><rect x=\"490.0\" y=\"34\" width=\"192.0\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></rect><text x=\"586.0\" y=\"50\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">\"\"</text><text x=\"20\" y=\"104\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">look first</text><circle cx=\"174.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"186.0\" y=\"104\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"start\">satisfied at once</text><text x=\"20\" y=\"154\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">sleep, then look</text><path d=\"M170.0 150 L491.6 150\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" stroke-dasharray=\"2 4\"></path><text x=\"330.0\" y=\"142\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">2000 ms sleep</text><circle cx=\"491.6\" cy=\"150\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M491.6 150 L682.0 150\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M682.0 150 L674.0 145 L674.0 155 Z\" fill=\"var(--amber)\"></path><text x=\"690.0\" y=\"154\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" text-anchor=\"start\">10 s</text><text x=\"491.6\" y=\"176\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" text-anchor=\"start\">every look finds \"\"</text><path d=\"M170 206 L682.0 206\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M170.0 202 L170.0 210\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"170.0\" y=\"226\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">0 ms</text><path d=\"M330.0 202 L330.0 210\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"330.0\" y=\"226\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">1000 ms</text><path d=\"M490.0 202 L490.0 210\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"490.0\" y=\"226\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">2000 ms</text><path d=\"M650.0 202 L650.0 210\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"650.0\" y=\"226\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">3000 ms</text><text x=\"682.0\" y=\"248\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">time since the click</text></svg>", "caption": "A state that leaves. The assertion that starts after 2000 ms can only ever see the empty paragraph, however long it looks."}
```

## Look while it is there

The fix is the order, and it removes the sleep with it. **Check a passing state first, straight
after the action that causes it, and leave the lasting states for later.** The assertion on the
toast then starts within milliseconds of the click and is satisfied on its first or second look.
The basket count lasts, so it can wait its turn. A last assertion checks that the toast goes away
again, which is the other half of its behaviour and the one a person would notice if it broke: a
message that never leaves. `toBeEmpty` passes when the element has no text, and its three-second
timeout is a deliberate statement that two seconds is the promise. Save it as `tests/toast.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('adding a banana says so, then stops saying it', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button').click();
  await expect(page.locator('.toast')).toHaveText('Added Banana');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await expect(page.locator('.toast')).toBeEmpty({ timeout: 3000 });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/toast.spec.js

Running 1 test using 1 worker

  ✓  1 tests/toast.spec.js:7:1 › adding a banana says so, then stops saying it (3.3s)

  1 passed (5.0s)
```

**The test took 3.3 s, and most of that is the last assertion doing what it says.** The toast
emptied two seconds after the click; the assertion, which by then was looking once a second, as
section 04 counted, saw the empty paragraph at its next look. A test that checks a disappearance
pays for it in time, which is a reason to check one only where it matters.

## What makes a state fleeting

The toast is the plainest case. The same shape turns up wherever a page shows something on the
way to something else: a *Saving…* label, a spinner, a highlight on a changed row, a banner that
closes itself, the two-fruit list the search page showed for a moment in lesson 3. Three
habits keep a test on the right side of them.

- **Assert a fleeting state immediately after its cause**, with nothing slow in between, not even
  another assertion on something that lasts.
- **Do not raise its timeout.** Its timeout only has to cover how long the state takes to appear;
  how long it stays is the page's business, and a longer wait cannot stretch it.
- **If the state is too short to catch reliably, test what it leaves behind instead**, the saved
  record or the count, or ask the developers for a signal that lasts. A message that is gone
  before a test can read it is also gone before some people can read it; how long a message must
  stay on screen is an accessibility question, and `non-functional-testing` lessons 12 to 15 are
  where it is answered.
