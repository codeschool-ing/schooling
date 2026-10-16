---
title: One behaviour, three layers
version: 1
---

A **layer** is how much of the system a test runs, not which tool it is written in. This section
takes one behaviour of the shop, *a banana in the basket costs R$ 5,90*, and checks it three times:
by calling the function that adds up the basket, by asking the server over HTTP, and by clicking
the button in a browser. Three files, the same fact, and three very different amounts of machinery
switched on to establish it.

The common belief is that these are three ways of testing the same thing, so the most realistic one
is the best. Each layer sees a different part of the shop, though, and the next two sections
measure what each part costs and what it can see.

## The unit layer: a function and nothing else

`total()` in `app/store.js`, from lesson 1, takes a list of basket lines and returns the price in
cents. It needs no server, no network and no page, so the cheapest test of it is a call. Node has
its own test runner, `node --test`, with no package to install, and `node:assert` for the checks.

**The file goes outside `tests/`.** Playwright runs every file in that folder whose name ends in
`.test.js` or `.spec.js`, and a Node test is not a Playwright test. Make the folder with
`mkdir unit`. Save it as `unit/total.test.js`:

```javascript
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { total } from '../app/store.js';

test('an empty basket costs nothing', () => {
  assert.equal(total([]), 0);
});

test('one banana costs 590 cents', () => {
  assert.equal(total([{ id: 'banana', qty: 1 }]), 590);
});

test('quantities multiply and lines add up', () => {
  // three bananas and two guavas: 3 * 590 + 2 * 1290
  assert.equal(total([{ id: 'banana', qty: 3 }, { id: 'guava', qty: 2 }]), 4350);
});
```

Run it with the TAP reporter, as lesson 8 did, which writes plain text a terminal can show:

```
ana@laptop:~/quitanda$ node --test --test-reporter=tap unit/total.test.js
TAP version 13
# Subtest: an empty basket costs nothing
ok 1 - an empty basket costs nothing
  ---
  duration_ms: 0.929121
  type: 'test'
  ...
# Subtest: one banana costs 590 cents
ok 2 - one banana costs 590 cents
  ---
  duration_ms: 0.22451
  type: 'test'
  ...
# Subtest: quantities multiply and lines add up
ok 3 - quantities multiply and lines add up
  ---
  duration_ms: 0.133609
  type: 'test'
  ...
1..3
# tests 3
# suites 0
# pass 3
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 68.064941
```

Three tests, and `duration_ms` under each is how long that test ran: 0.929, 0.225 and 0.134
milliseconds. The last line says the whole file took 68 milliseconds, and almost none of that was
the tests. **Three cases cost nothing to add**, which is why the third one, with quantities, is here
at all.

## The API layer: HTTP, and no browser

The same fact one layer up: reset the shop, send `POST /api/basket` with a banana, and read the
answer. Playwright's `request` fixture, which lessons 6 and 15 used, sends the request and knows
the `baseURL`, and the configuration's `webServer` starts the shop first. Save it as
`tests/basket-api.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Only the request fixture: HTTP to the shop, and no browser.
test('a banana in the basket costs 590 cents', async ({ request }) => {
  await request.post('/api/reset');
  const response = await request.post('/api/basket', { data: { id: 'banana' } });
  expect(response.status()).toBe(200);
  expect(await response.json()).toEqual({ lines: [{ id: 'banana', qty: 1 }], total: 590 });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-api.spec.js

Running 1 test using 1 worker

  ✓  1 tests/basket-api.spec.js:4:1 › a banana in the basket costs 590 cents (51ms)

  1 passed (1.2s)
```

One test, 51 ms as Playwright counts it, and 1.2 s for the whole run. This test runs `total()`
too, inside the server, along with the route, the JSON in both directions and the HTTP server
itself: a defect in any of them turns it red.

## The browser layer: the page, as a customer uses it

And the same fact as somebody sees it: open the shop, press Add to basket on the banana, read the
count and the total in the header. Save it as `tests/basket-ui.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('a banana in the basket shows R$ 5,90', async ({ page, request }) => {
  await request.post('/api/reset');
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
});
```

The expected text is typed with an ordinary space, and it passes: lesson 2 showed that `toHaveText`
treats the non-breaking space after `R$` as whitespace.

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-ui.spec.js

Running 1 test using 1 worker

  ✓  1 tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 (281ms)

  1 passed (1.6s)
```

281 ms for the test and 1.6 s for the run. **The test took five and a half times as long as the
API test, and the run only a little longer**, because most of a single run is what both files pay
before any test starts. The next section separates the two.

## Which layer needs a browser

The difference between the last two is easy to state and worth seeing once. Point Playwright at an
empty folder for its browsers and run both files. They write the same shared basket, so they run on
one worker, as every test that touches the basket does until lessons 15 and 19 deal with it:

```
ana@laptop:~/quitanda$ PLAYWRIGHT_BROWSERS_PATH=~/no-browsers npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1

Running 2 tests using 1 worker

  ✓  1 tests/basket-api.spec.js:4:1 › a banana in the basket costs 590 cents (55ms)
  ✘  2 tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 (2ms)


  1) tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ────────────────────────────

    Error: browserType.launch: Executable doesn't exist at /home/ana/no-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell
    ╔═════════════════════════════════════════════════════════════════════════╗
    ║ Looks like Playwright Test or Playwright was just installed or updated. ║
    ║ Please run the following command to download new browsers:              ║
    ║                                                                         ║
    ║     npx playwright install                                              ║
    ║                                                                         ║
    ║ <3 Playwright Team                                                      ║
    ╚═════════════════════════════════════════════════════════════════════════╝

  1 failed
    tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ─────────────────────────────
  1 passed (1.3s)
```

**The API test passed with no browser on the machine at all**; the browser test failed in its first
step, launching one. That is the difference between the two layers in a single run: one of them
needs a browser to exist, start and draw a page, and the other never asks for one.
