---
title: Why your tests never meet it
version: 1
---

The obvious test for the offer page sets a new offer and checks that the page shows it. **It
passes, and the flaw is still there.** That is not luck: it is how Playwright
runs every test, and it is worth understanding before deciding whether to change it.

## A new browser for every test

A **browser context** is one browser profile: its own cookies, its own storage and its own HTTP
cache, cut off from every other context in the same browser. Playwright's reference says it in one
line: a new context *won't share cookies/cache with other browser contexts*. The `page` a test
receives lives in a context made for that test and thrown away after it, so **every test is a
customer on a first visit**, with nothing kept from any test before it. Lesson 10 is about contexts
in general; here only the cache matters.

Here is that obvious test. `beforeEach` resets the shop before each test, so the offer always starts
as the mango; the test changes it and opens the page. Save it as `tests/cache.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a new offer reaches the page', async ({ page, request }) => {
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/cache.spec.js

Running 1 test using 1 worker

  ✓  1 tests/cache.spec.js:7:1 › a new offer reaches the page (271ms)

  1 passed (1.9s)
```

One test, green. It proves the server hands a new offer to a new visitor, which is true and worth
knowing. It says nothing about the customer who already had the page open, because no test in this
file has ever been that customer.

**That is the trade.** An empty cache makes a test repeatable: it cannot pass because of something
an earlier test left behind, and it does not fail because of it either, which lesson 15 makes the
rule for all test data. The price is that every test meets the shop the way only a first-time
visitor does, and a defect that needs a second visit is invisible to the whole suite.

## Writing the returning customer

To meet the flaw, a test has to be a returning customer **on purpose**: visit, change, visit again,
all in one context. Add this test at the end of `tests/cache.spec.js`:

```javascript
test('a returning customer sees the new offer', async ({ page, request }) => {
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Mango');
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/cache.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/cache.spec.js:7:1 › a new offer reaches the page (221ms)
  ✘  2 tests/cache.spec.js:13:1 › a returning customer sees the new offer (5.2s)


  1) tests/cache.spec.js:13:1 › a returning customer sees the new offer ────────────────────────────

    Error: expect(locator).toContainText(expected) failed

    Locator: locator('#offer')
    Expected substring: "Banana"
    Received string:    "Mango for R$ 3,90"
    Timeout: 5000ms

    Call log:
      - Expect "toContainText" with timeout 5000ms
      - waiting for locator('#offer')
        9 × locator resolved to <p id="offer">Mango for R$ 3,90</p>
          - unexpected value "Mango for R$ 3,90"


      16 |   await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
      17 |   await page.goto('/offer.html');
    > 18 |   await expect(page.locator('#offer')).toContainText('Banana');
         |                                        ^
      19 | });
      20 |
        at /home/ana/quitanda/tests/cache.spec.js:18:40

    Error Context: test-results/cache-a-returning-customer-sees-the-new-offer/error-context.md

  1 failed
    tests/cache.spec.js:13:1 › a returning customer sees the new offer ─────────────────────────────
  1 passed (6.9s)
```

The second test failed, and its report says why in two lines: it expected `Banana` and received
`Mango for R$ 3,90`, nine times over five seconds. **That is the flaw, found by a test** for the
first time, and it took one decision: open the page twice in the same context instead of once.
The suite cannot stay red over a flaw that is there on purpose, and the next section turns this
test into one that says so; leave it failing until then.

## Other ways to come back

The same page visited twice is one returning customer. There are others, and they do not all keep
the cache. This script changes the offer once and sends five visitors back to the page, each made a
different way, with the shop running. One of them uses `launchPersistentContext`, which keeps the
profile in a folder, here `profile`, the way an ordinary browser keeps yours between launches. Save it as `visitors.mjs`:

```javascript
// The offer changes once; five visitors come back, and each says what it
// was shown.
import { chromium } from '@playwright/test';
import { rm } from 'node:fs/promises';

const shop = 'http://localhost:3000';
const post = (path, body) => fetch(shop + path, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
});
async function visit(who, page) {
  await page.goto(shop + '/offer.html');
  const text = await page.locator('#offer', { hasNotText: '…' }).textContent();
  console.log(who.padEnd(28), text);
}

await post('/api/reset', {});
await rm('profile', { recursive: true, force: true });
const browser = await chromium.launch();
const context = await browser.newContext();
const page = await context.newPage();
await visit('before the change', page);
let kept = await chromium.launchPersistentContext('profile');
await visit('before, in a kept profile', await kept.newPage());
await kept.close();

await post('/api/offer', { id: 'banana', price: 290 });

await visit('the same page', page);
await visit('a new page, same context', await context.newPage());
const saved = await browser.newContext({ storageState: await context.storageState() });
await visit('a new context, saved state', await saved.newPage());
await visit('a new context', await (await browser.newContext()).newPage());
kept = await chromium.launchPersistentContext('profile');
await visit('the kept profile, reopened', await kept.newPage());

await kept.close();
await browser.close();
```

```
ana@laptop:~/quitanda$ node visitors.mjs
before the change            Mango for R$ 3,90
before, in a kept profile    Mango for R$ 3,90
the same page                Mango for R$ 3,90
a new page, same context     Mango for R$ 3,90
a new context, saved state   Banana for R$ 2,90
a new context                Banana for R$ 2,90
the kept profile, reopened   Mango for R$ 3,90
```

Three of the five came back to the old offer, and what they share is the cache, not the steps:

- **the same page**, and **a new page in the same context**: a context has one cache, whichever
  page asks;
- **a kept profile, reopened**: `launchPersistentContext` writes the cache to the folder with
  everything else, and the second launch read it back. It is the closest a script gets to a person
  who closes the browser and opens it tomorrow. Delete the `profile` folder after the run;
- **a new context made from saved state** was shown the new offer. `storageState` carries cookies
  and local storage, which is what a logged-in session needs, and **not the HTTP cache**. A suite
  that logs in once and reuses the state in every test still runs every test as a first visit, as
  far as the cache goes.

So a returning customer in a test is either two visits inside one test, or a persistent context
kept between runs. The first is what the next section builds on, because it needs no folder and
leaves nothing behind.
