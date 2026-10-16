---
title: Running a recording
version: 1
---

Neither recorder could be operated here, but their output can be run. Selenium IDE's recording
becomes a Playwright test step for step, with the behaviour its playback code has; codegen's is
Playwright already. **Both go into a folder of their own**, because a recording is about to fail
and the suite in `tests/` is the one a red run should mean something in. Lesson 14 kept its flaky
test apart the same way. Save this as `recorded.config.js`:

```javascript
// Recordings, run as tests but kept apart from the suite in tests/.
// Everything else comes from the project's own configuration.
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

export default defineConfig({
  ...base,
  testDir: 'recorded',
});
```

## The IDE's recording, replayed

Each command of the `.side` file from the Selenium IDE section becomes one line, and each line does
what the IDE's playback does: a click waits up to five seconds for its target, the pause is a fixed
second, and `assertText` reads the text once. Save it as `recorded/side.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The Selenium IDE recording, one command per line, played the way the IDE
// plays it: a click waits up to 5 s for its target, assertText reads once.
test('two fruit', async ({ page }) => {
  await page.goto('/');
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.locator('#card-4821 > button').click({ timeout: 5000 });
  await page.locator('#card-1730 > button').click({ timeout: 5000 });
  await page.waitForTimeout(1000);
  expect(await page.locator('[data-testid="basket-count"]').textContent()).toBe('2');
});
```

```
ana@laptop:~/quitanda$ npx playwright test --config recorded.config.js recorded/side.spec.js

Running 1 test using 1 worker

  ✘  1 recorded/side.spec.js:5:1 › two fruit (5.3s)


  1) recorded/side.spec.js:5:1 › two fruit ─────────────────────────────────────────────────────────

    TimeoutError: locator.click: Timeout 5000ms exceeded.
    Call log:
      - waiting for locator('#card-4821 > button')


       6 |   await page.goto('/');
       7 |   await page.setViewportSize({ width: 1280, height: 800 });
    >  8 |   await page.locator('#card-4821 > button').click({ timeout: 5000 });
         |                                             ^
       9 |   await page.locator('#card-1730 > button').click({ timeout: 5000 });
      10 |   await page.waitForTimeout(1000);
      11 |   expect(await page.locator('[data-testid="basket-count"]').textContent()).toBe('2');
        at /home/ana/quitanda/recorded/side.spec.js:8:45

    Error Context: test-results/side-two-fruit/error-context.md

  1 failed
    recorded/side.spec.js:5:1 › two fruit ──────────────────────────────────────────────────────────
```

**It failed on its first step that names an element**, after exactly the five seconds the IDE
would have waited, and for the reason lesson 2 gave: the card that was `#card-4821` while somebody
recorded is some other number now. The pause and the read-once check never ran. Fixing the id
would only uncover them, and lesson 3 has already shown what a fixed pause does to a check that
reads once.

## Codegen's recordings, replayed

Three codegen sessions, saved into one file and renamed, because three tests called `test` are a
duplicate Playwright refuses. The first two use the names the generator gave in the previous
section. The third clicks the Acerola, which the generator named by its random `id`; the number in
it was copied from one run of `pick.mjs`, and yours will be another. Save it as
`recorded/codegen.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('banana', async ({ page }) => {
  await page.goto('http://localhost:3000/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toContainText('1');
});

test('two fruit', async ({ page }) => {
  await page.goto('http://localhost:3000/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await page.getByTestId('product-mango').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toContainText('2');
});

test('acerola', async ({ page }) => {
  await page.goto('http://localhost:3000/');
  await page.locator('#card-8155 > button').click();
  await expect(page.getByRole('status')).toContainText('Added Acerola');
});
```

```
ana@laptop:~/quitanda$ npx playwright test --config recorded.config.js recorded/codegen.spec.js

Running 3 tests using 1 worker

  ✓  1 recorded/codegen.spec.js:3:1 › banana (386ms)
  ✘  2 recorded/codegen.spec.js:9:1 › two fruit (5.3s)
  ✘  3 recorded/codegen.spec.js:16:1 › acerola (30.0s)


  1) recorded/codegen.spec.js:9:1 › two fruit ──────────────────────────────────────────────────────

    Error: expect(locator).toContainText(expected) failed

    Locator: getByTestId('basket-count')
    Expected substring: "2"
    Received string:    "3"
    Timeout: 5000ms

    Call log:
      - Expect "toContainText" with timeout 5000ms
      - waiting for getByTestId('basket-count')
        9 × locator resolved to <span data-testid="basket-count">3</span>
          - unexpected value "3"


      11 |   await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
      12 |   await page.getByTestId('product-mango').getByRole('button', { name: 'Add to basket' }).click();
    > 13 |   await expect(page.getByTestId('basket-count')).toContainText('2');
         |                                                  ^
      14 | });
      15 |
      16 | test('acerola', async ({ page }) => {
        at /home/ana/quitanda/recorded/codegen.spec.js:13:50

    Error Context: test-results/codegen-two-fruit/error-context.md

  2) recorded/codegen.spec.js:16:1 › acerola ───────────────────────────────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for locator('#card-8155 > button')


      16 | test('acerola', async ({ page }) => {
      17 |   await page.goto('http://localhost:3000/');
    > 18 |   await page.locator('#card-8155 > button').click();
         |                                             ^
      19 |   await expect(page.getByRole('status')).toContainText('Added Acerola');
      20 | });
      21 |
        at /home/ana/quitanda/recorded/codegen.spec.js:18:45

    Error Context: test-results/codegen-acerola/error-context.md

  2 failed
    recorded/codegen.spec.js:9:1 › two fruit ───────────────────────────────────────────────────────
    recorded/codegen.spec.js:16:1 › acerola ────────────────────────────────────────────────────────
  1 passed (38.1s)
```

**The first test passed.** On a shop that had just started, the basket was empty, which is the
state it was recorded in.

**The second failed with the right fruit in the wrong basket.** Its two clicks worked and the
count said `3`: the banana the first test added was still there, because the basket is the one list
the whole shop shares, from lesson 1, and nothing in either recording empties it. Each session was
recorded on a fresh shop, so each one passed while it was being made.

**And on the next run the same test passed, on the same three items.** Start the shop yourself with
`npm start`, so it outlives the run, run the first two tests again, and ask the shop what its basket
holds:

```
ana@laptop:~/quitanda$ npx playwright test --config recorded.config.js recorded/codegen.spec.js -g 'banana|two fruit' | grep -E '✓|✘'
  ✓  1 recorded/codegen.spec.js:3:1 › banana (220ms)
  ✓  2 recorded/codegen.spec.js:9:1 › two fruit (223ms)
ana@laptop:~/quitanda$ curl -s http://localhost:3000/api/basket
{"lines":[{"id":"banana","qty":2},{"id":"mango","qty":1}],"total":1630}
```

Two bananas and a mango, under a test whose name promises two items, and this time a tick beside
it. **The assertion passed because of what it asks.** `toContainText('2')` wants the character
`2` somewhere in the count, and it keeps asking: if it looks between the test's banana arriving and
its mango arriving, the count says `2` for a moment, and a moment is enough. Whether it looks then
is timing, which is why one run failed and the next passed. That is two lessons' subjects arriving
through one recorder: a flaky test, lesson 14's, and a check satisfied by the wrong state, the quiet
way to be wrong from lesson 2, made possible by lesson 15's missing reset.

**The third failed on the random id**, this time after Playwright's own thirty-second limit for a
whole test, since codegen writes no timeout of its own into the click.

## The same checks, written by hand

Lesson 12 built the page object and the `shop` fixture, which empties the basket and opens the shop
before every test that asks for it. Written with them, the two-fruit check needs no ids, no pause
and no address. Save it as `tests/two-fruit.spec.js`:

```javascript
import { test, expect } from './fixtures.js';

test('a banana and a mango make two items', async ({ shop }) => {
  await shop.addToBasket('banana');
  await shop.addToBasket('mango');
  await expect(shop.basketCount()).toHaveText('2');
  await expect(shop.page.getByRole('status')).toHaveText('Added Mango');
});
```

Run it three times, with one worker. Two workers would run copies at the same moment against the
one shared basket, and one copy's reset would land in the middle of the other's clicks; lessons 15
and 19 take that problem apart.

```
ana@laptop:~/quitanda$ npx playwright test tests/two-fruit.spec.js --repeat-each 3 --workers 1

Running 3 tests using 1 worker

  ✓  1 tests/two-fruit.spec.js:3:1 › a banana and a mango make two items (378ms)
  ✓  2 tests/two-fruit.spec.js:3:1 › a banana and a mango make two items (419ms)
  ✓  3 tests/two-fruit.spec.js:3:1 › a banana and a mango make two items (344ms)

  3 passed (4.8s)
```

## Why the recordings stay where they are

The two files in `recorded/` fail, and they are kept on purpose, like the failing tests lesson 16
keeps in `evidence/`: they are specimens of what a recording does, to be run by name with their own
configuration. A plain `npx playwright test` reads `tests/` and never meets them.

**`test.fail()` would be the wrong way to keep them.** Lessons 3, 5 and 7 used it for a test that
documents a defect in the shop, and said its weakness: any failure satisfies it. Here it would be
worse, because there is no defect in the shop to document. `codegen.spec.js` holds a test that
passes and one that passes or fails by timing, and marking the file as expected to fail would turn
the first into a red line and make the second flaky in the other direction. The defect is
in the recordings, and the honest place for a recording that cannot pass is outside the suite, with
a configuration whose name says what it holds.
