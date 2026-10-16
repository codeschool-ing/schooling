---
title: The page object answers, the test judges
version: 1
---

**A page object reports what the page shows; the test decides whether that is right.** Put the
judgement inside the page object, a method like `checkBasketHasOneItem()`, and two things go
wrong. The expectation is now hidden: the test reads *check the basket*, and the reader has to
open another file to learn what was expected. And the method fits one test: the next test, which
wants two items, needs a second method or a parameter, and the page object slowly becomes a
copy of the test suite. Fowler's article on the pattern says he favours page objects with no
assertions in them.

That leaves a decision that looks small: **when a test needs a fact from the page, what does the
page object hand back?** The basket's count could come back as a number, `1`, which is what the
test means. Or it could come back as the locator, which is what this lesson's `basketCount()`
does, and the test puts the assertion on it.

## A number is a snapshot

Lesson 10 showed the difference with a bare locator: `textContent()` read straight after a click
returned `0`, because the shop redraws the count only when the server's answer arrives, while
`expect(locator).toHaveText('1')` kept reading until it matched. Wrapping the read in a page
object does not change what it is. Here is the tempting method, as an addition to the end of the
class in `pages/basket-summary.js`:

```javascript
  async itemCount() {
    return Number(await this.count.textContent());
  }
```

On `localhost` the shop answers in a few milliseconds, so the read and the answer finish close
together and either can win: run it a few times and it passes on some runs and fails on others.
A real network gives the answer more time to be late. The tests below make that time fixed, so
the race comes out the same way on every run: a route, like the one lesson 3's `at-load.mjs`
used, holds the basket's answer back for 200 ms. Then one test compares the number once, and one
asks `expect.poll` to call the method again until the number matches. To try them, put them in a
file of their own, `tests/page-object-number.spec.js`, and delete it and the method afterwards:

```javascript
import { test, expect } from '@playwright/test';
import { ShopPage } from '../pages/shop-page.js';

test.beforeEach(async ({ page, request }) => {
  await request.post('/api/reset');
  // A slower network: the answer to adding a fruit arrives 200 ms late.
  await page.route('**/api/basket', async (route) => {
    if (route.request().method() === 'POST') await new Promise((ok) => setTimeout(ok, 200));
    await route.continue();
  });
});

test('the count, read as a number', async ({ page }) => {
  const shop = new ShopPage(page);
  await shop.open();
  await shop.addToBasket('banana');
  expect(await shop.basket.itemCount()).toBe(1);
});

test('the count, polled as a number', async ({ page }) => {
  const shop = new ShopPage(page);
  await shop.open();
  await shop.addToBasket('banana');
  await expect.poll(() => shop.basket.itemCount()).toBe(1);
});
```

Five runs of each:

```
ana@laptop:~/quitanda$ npx playwright test tests/page-object-number.spec.js --workers 1 --repeat-each 5 | grep -E 'passed|failed|✘|✓|Received'
  ✘   1 tests/page-object-number.spec.js:13:1 › the count, read as a number (281ms)
  ✓   2 tests/page-object-number.spec.js:20:1 › the count, polled as a number (611ms)
  ✘   3 tests/page-object-number.spec.js:13:1 › the count, read as a number (254ms)
  ✓   4 tests/page-object-number.spec.js:20:1 › the count, polled as a number (626ms)
  ✘   5 tests/page-object-number.spec.js:13:1 › the count, read as a number (252ms)
  ✓   6 tests/page-object-number.spec.js:20:1 › the count, polled as a number (591ms)
  ✘   7 tests/page-object-number.spec.js:13:1 › the count, read as a number (236ms)
  ✓   8 tests/page-object-number.spec.js:20:1 › the count, polled as a number (622ms)
  ✘   9 tests/page-object-number.spec.js:13:1 › the count, read as a number (255ms)
  ✓  10 tests/page-object-number.spec.js:20:1 › the count, polled as a number (595ms)
    Received: 0
    Received: 0
    Received: 0
    Received: 0
    Received: 0
  5 failed
  5 passed (13.4s)
```

**The number failed five times in five, and every failure received `0`.** The method read the
count while the answer was still on its way, and handed the test a snapshot of the moment before
the banana arrived. The polled version passed all five, and took longer, around 600 ms against
250: `expect.poll` calls the function, compares, and waits between tries, so it noticed the answer
some time after it arrived. On `localhost`, with no delay, the same
pair is lesson 14's flaky test, made by a page object: red on some runs and green on others, with
nobody touching anything.

So the rule is narrower than *never return a value*. **Return a locator whenever the test will
assert on something the page may still be changing**, because only an assertion on a locator, or
a poll, waits for the page. Return a value when it is settled and the test needs it for
arithmetic, as Cypress needed `.then()` to use the count in lesson 9: read it after an assertion has
established that the page is finished.

## The exception people argue about

One assertion keeps turning up inside page objects, and it has defenders: **checking that the
page is the page.** An `open()` that ends with `await expect(heading).toBeVisible()` fails within
the assertion's five seconds, naming the heading it did not find, instead of letting the next
step wait thirty seconds for a missing button. Fowler, who favours none, makes room for this kind: a check of
what must be true of the page at that point. The argument for it
is the message: a precondition broken in `open()` is reported where it broke. The argument
against is that the page object now decides what *loaded* means for every test, including the
one that was checking what happens when it does not load.

A middle road keeps both sides honest. The check stays a **precondition** about where the test
is, never an expectation about what the test is examining: a page object may refuse to continue
on the wrong page, and it may not decide that a count of 2 is wrong. This course's page objects
leave it out, because `addToBasket` already waits for its button and its failure says which.
