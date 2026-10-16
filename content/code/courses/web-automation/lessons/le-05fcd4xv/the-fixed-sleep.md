---
title: The fixed sleep, measured
version: 1
---

**A fixed sleep is a guess about how long the page will take, written down as a number.** On the
day the number is chosen it is right for that machine and that server. On every other day it is
either too short, and the test fails on a page with nothing wrong with it, or too long, and the
test spends time waiting for something that happened long ago. It is never exactly right, because
the page does not take the same time twice. Lesson 3 showed a sleep deciding a test by luck; this
section puts the cost of the habit in seconds.

The usual defence of a sleep is that it is simple and that a second here and there does not
matter. Both halves are worth checking against a real suite, so here is one, written the way a
suite full of sleeps gets written: each pause is a round number that seemed generous.

## Four tests, four guesses

The tests cover four pages from earlier lessons. The home page draws its products after it loads
(lesson 3); a click shows the toast, *Added Banana*; the server-rendered page at `/ssr` ignores a
click until its script arrives (lesson 6); and the search page finds one fruit for `papaya` typed
in one go. Each test pauses before it reads, and reads once. The basket is shared by everybody who
uses the shop, so each test empties it first. Save it as `tests/sleeps.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('the home page lists eight fruit', async ({ page }) => {
  await page.goto('/');
  await page.waitForTimeout(1000);
  expect(await page.locator('#products li').count()).toBe(8);
});

test('adding a banana says so', async ({ page }) => {
  await page.goto('/');
  await page.waitForTimeout(1000);
  await page.getByTestId('product-banana').getByRole('button').click();
  await page.waitForTimeout(500);
  expect(await page.locator('.toast').textContent()).toBe('Added Banana');
});

test('a click on /ssr adds to the basket', async ({ page }) => {
  await page.goto('/ssr');
  await page.waitForTimeout(1000);
  await page.getByTestId('product-banana').getByRole('button').click();
  await page.waitForTimeout(500);
  expect(await page.getByTestId('basket-count').textContent()).toBe('1');
});

test('searching for papaya finds one fruit', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').fill('papaya');
  await page.waitForTimeout(1000);
  expect(await page.locator('#results li').count()).toBe(1);
});
```

Run it with one worker. Four tests at once would add to one shared basket at the same time, which
is lesson 15's subject; here it would only blur the timings:

```
ana@laptop:~/quitanda$ npx playwright test tests/sleeps.spec.js --workers 1

Running 4 tests using 1 worker

  ✓  1 tests/sleeps.spec.js:7:1 › the home page lists eight fruit (1.2s)
  ✓  2 tests/sleeps.spec.js:13:1 › adding a banana says so (1.7s)
  ✘  3 tests/sleeps.spec.js:21:1 › a click on /ssr adds to the basket (1.7s)
  ✓  4 tests/sleeps.spec.js:29:1 › searching for papaya finds one fruit (1.3s)


  1) tests/sleeps.spec.js:21:1 › a click on /ssr adds to the basket ────────────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: "1"
    Received: "0"

      24 |   await page.getByTestId('product-banana').getByRole('button').click();
      25 |   await page.waitForTimeout(500);
    > 26 |   expect(await page.getByTestId('basket-count').textContent()).toBe('1');
         |                                                                ^
      27 | });
      28 |
      29 | test('searching for papaya finds one fruit', async ({ page }) => {
        at /home/ana/quitanda/tests/sleeps.spec.js:26:64

    Error Context: test-results/sleeps-a-click-on-ssr-adds-to-the-basket/error-context.md

  1 failed
    tests/sleeps.spec.js:21:1 › a click on /ssr adds to the basket ─────────────────────────────────
  3 passed (8.8s)
```

**One second was too short for `/ssr`.** The script that wires its buttons arrives about a second
and a half after the page loads, so the click landed in the gap and the count stayed at `0`. The
other three passed, and each took a little over its own sleeps.

## The usual repair

The repair everybody reaches for first is a bigger number. Change the first `waitForTimeout(1000)`
in the `/ssr` test to `waitForTimeout(2000)`, and run the file again:

```
ana@laptop:~/quitanda$ npx playwright test tests/sleeps.spec.js --workers 1

Running 4 tests using 1 worker

  ✓  1 tests/sleeps.spec.js:7:1 › the home page lists eight fruit (1.3s)
  ✓  2 tests/sleeps.spec.js:13:1 › adding a banana says so (1.8s)
  ✓  3 tests/sleeps.spec.js:21:1 › a click on /ssr adds to the basket (2.7s)
  ✓  4 tests/sleeps.spec.js:29:1 › searching for papaya finds one fruit (1.1s)

  4 passed (8.5s)
```

Green, and the price is in the durations: 1.3 s, 1.8 s, 2.7 s and 1.1 s, and 8.5 s for the run.
Every test now takes as long as its sleeps, whatever the page needed. **The suite waits for the slowest day anybody has imagined, on every run.** And
2000 is still a guess: on a build server busy enough to deliver the script half a second later,
the same test fails again, and the next repair is 3000.

## The same four tests, waiting for a state

Each sleep stood in for a question the page can answer: *are there eight products*, *does the
toast say it*, *has the page said it is ready*, *does the list hold Papaya*. Asked as web-first
assertions, which retry until they are true or their time runs out, the questions replace the
numbers. The `/ssr` test waits for the `data-ready` marker lesson 6 introduced. This version
replaces the first. Save it as `tests/sleeps.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('the home page lists eight fruit', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
});

test('adding a banana says so', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button').click();
  await expect(page.locator('.toast')).toHaveText('Added Banana');
});

test('a click on /ssr adds to the basket', async ({ page }) => {
  await page.goto('/ssr');
  await expect(page.locator('body')).toHaveAttribute('data-ready', 'true');
  await page.getByTestId('product-banana').getByRole('button').click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});

test('searching for papaya finds one fruit', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').fill('papaya');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/sleeps.spec.js --workers 1

Running 4 tests using 1 worker

  ✓  1 tests/sleeps.spec.js:7:1 › the home page lists eight fruit (202ms)
  ✓  2 tests/sleeps.spec.js:12:1 › adding a banana says so (265ms)
  ✓  3 tests/sleeps.spec.js:18:1 › a click on /ssr adds to the basket (2.1s)
  ✓  4 tests/sleeps.spec.js:25:1 › searching for papaya finds one fruit (139ms)

  4 passed (4.3s)
```

**Three of the four now finish in a fraction of a second, and the fourth takes what the page
takes**: 4.3 s for the run, against 8.5 s with the sleeps. The `/ssr` test is the only slow one, because the page itself is slow, and it would stay
green on the day the script took four seconds instead of one and a half. The file keeps its name,
as a reminder of what it used to be.

Comparing the summaries is the measurement this section promised: the same four checks, the same
pages, with the sleeps and without them. A suite of a few hundred tests multiplies that difference
by a few hundred. The rest of this lesson is about the waits that replace sleeps, in Selenium and
in Playwright, and where each of them stops working.
