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
%%CAP side%%
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
%%CAP codegen%%
```

**The first test passed.** On a shop that had just started, the basket was empty, which is the
state it was recorded in.

**The second failed with the right fruit in the wrong basket.** Its two clicks worked and the count
said `3`: the banana the first test added was still there, because the basket is the one list the
whole shop shares, from lesson 1, and nothing in either recording empties it. Each session was
recorded on a fresh shop, so each one passed while it was being made, and they fail as soon as they
run one after another. That is lesson 15's subject arriving through a recorder.

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
%%CAP hand%%
```

## Why the recordings stay where they are

The two files in `recorded/` fail, and they are kept on purpose, like the failing tests lesson 16
keeps in `evidence/`: they are specimens of what a recording does, to be run by name with their own
configuration. A plain `npx playwright test` reads `tests/` and never meets them.

**`test.fail()` would be the wrong way to keep them.** Lessons 3, 5 and 7 used it for a test that
documents a defect in the shop, and said its weakness: any failure satisfies it. Here it would be
worse, because there is no defect in the shop to document. `codegen.spec.js` holds a test that
passes, and marking the file as expected to fail would turn that pass into a red line. The defect is
in the recordings, and the honest place for a recording that cannot pass is outside the suite, with
a configuration whose name says what it holds.
