---
title: Waiting without being told to
version: 1
---

A test written for a page that changes under it would seem to need a pause before every step:
wait for the button, then click, then wait for the total, then check it. **Playwright tests in
this course have no pauses and no sleeps**, and they pass. Two mechanisms do the waiting, one
before every action and one inside every assertion, and both give up after a fixed time. This
section names them and measures the times; lesson 13 is about waits in depth, and lesson 3 about
the asynchronous loading that makes them necessary.

## Before an action: actionability

Before `click()` presses anything, Playwright finds the element the locator describes and checks,
in its documentation's words, that it is **visible**, **stable** (not moving in an animation),
**receives events** (no other element covers it) and is **enabled**. A `fill()` also needs it to be
**editable**. If any check fails, it looks again, and again, until they all pass or time runs out.
A button that appears half a second after the page loads is clicked half a second later, and the
test says nothing about it.

That is also why a locator is a description rather than an element. `page.getByRole('button')`
finds nothing when it is written; it is resolved each time it is used, against the page as it is
at that moment.

## After an action: an assertion that retries

The shop's **Add to basket** sends a request, and when the answer arrives it redraws the count and
shows *Added Mango* in the toast for two seconds. `click()` returns once the click is delivered,
not once any of that has happened. This test reads the toast both ways. Save it as
`tests/waiting.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a read is a snapshot, an assertion retries', async ({ page }) => {
  await page.goto('/');
  const toast = page.getByRole('status');
  await page.getByTestId('product-mango').getByRole('button', { name: 'Add to basket' }).click();
  await expect(toast).toHaveText('Added Mango');
  console.log(`read once: "${await toast.textContent()}"`);
  // The shop empties the toast two seconds after it appears.
  await expect(toast).toHaveText('');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/waiting.spec.js

Running 1 test using 1 worker

read once: "Added Mango"
  ✓  1 tests/waiting.spec.js:7:1 › a read is a snapshot, an assertion retries (3.1s)

  1 passed (4.6s)
```

The first assertion waited for the answer and the toast. `textContent()` then read it once and got
`Added Mango`: **a read is a snapshot**, taken the instant it runs, and it would read the same
thing however long the test waited afterwards. `expect(toast).toHaveText('')` passed on the same
element, because an assertion on a locator is a **web-first assertion**: it reads, compares, and
reads again until the text matches. Here it kept reading until the shop emptied the toast, which is
why the test took over two seconds.

**Never assert on a snapshot of something that is still changing.** `expect(await
toast.textContent()).toBe('')` checks the value at one instant; read before the shop has answered
or after the toast has cleared, it gives a different verdict on the same page, which is the flaky
test lesson 14 is about.

## How long is "until"

Neither mechanism waits for ever, and the defaults are worth knowing from a run rather than from
memory. To see them, add these two tests to the end of `tests/waiting.spec.js`, run the file, and
take them out again. Each waits for something that never happens:

```javascript
test('an assertion that is never true', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});

test('a click on a button that is not there', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Buy now' }).click();
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/waiting.spec.js

Running 3 tests using 1 worker

read once: "Added Mango"
  ✓  1 tests/waiting.spec.js:7:1 › a read is a snapshot, an assertion retries (3.2s)
  ✘  2 tests/waiting.spec.js:17:1 › an assertion that is never true (5.1s)
  ✘  3 tests/waiting.spec.js:22:1 › a click on a button that is not there (30.0s)


  1) tests/waiting.spec.js:17:1 › an assertion that is never true ──────────────────────────────────

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


      17 | test('an assertion that is never true', async ({ page }) => {
      18 |   await page.goto('/');
    > 19 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
         |                                                  ^
      20 | });
      21 |
      22 | test('a click on a button that is not there', async ({ page }) => {
        at /home/ana/quitanda/tests/waiting.spec.js:19:50

    Error Context: test-results/waiting-an-assertion-that-is-never-true/error-context.md

  2) tests/waiting.spec.js:22:1 › a click on a button that is not there ────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for getByRole('button', { name: 'Buy now' })


      22 | test('a click on a button that is not there', async ({ page }) => {
      23 |   await page.goto('/');
    > 24 |   await page.getByRole('button', { name: 'Buy now' }).click();
         |                                                       ^
      25 | });
      26 |
        at /home/ana/quitanda/tests/waiting.spec.js:24:55

    Error Context: test-results/waiting-a-click-on-a-button-that-is-not-there/error-context.md

  2 failed
    tests/waiting.spec.js:17:1 › an assertion that is never true ───────────────────────────────────
    tests/waiting.spec.js:22:1 › a click on a button that is not there ─────────────────────────────
  1 passed (40.7s)
```

The two failures report two different clocks:

- **an assertion gives up after five seconds**, and the message says so, `Timeout: 5000ms`, with a
  call log showing how many times it looked and what it found each time;
- **an action has no clock of its own.** The click waited for a button called *Buy now* until the
  whole test ran out of time, `Test timeout of 30000ms exceeded`, and the duration beside the test
  name shows it.

Both can be changed: `expect.timeout` and `timeout` in the configuration, `actionTimeout` under
`use`, or a `{ timeout }` on a single call. Changing them is lesson 13's subject. What matters here
is reading the failure: a call log that says the locator **resolved** and held the wrong value is a
page that did something unexpected; a call log that only ever says **waiting for** is a locator
that matches nothing, which is usually the test's fault.
