---
title: The obvious tests, and how they decide
version: 1
---

The first tests anybody writes against a page like this one type the word, look at the list and
check that it holds one fruit. **The trouble is in *look*.** Every one of the obvious ways to do it
picks a moment, and the last section showed that the list says different things at different
moments. A test that picks a moment is measuring the moment.

This version of the test file holds four of them. Three type the word key by key with
`pressSequentially`, which fires one `input` event per key as a person's typing does, and differ
only in when they read the list: at once, after half a second, after a whole second. The fourth
uses `fill`, which puts the whole word in the box in one go, and waits a second. Each reads the
list with `count()`, which counts **once** and answers. Save it as `tests/search.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/search.html');
});

test('reads the list as soon as the typing ends', async ({ page }) => {
  await page.getByLabel('Fruit').pressSequentially('papaya');
  expect(await page.locator('#results li').count()).toBe(1);
});

test('sleeps half a second, then reads', async ({ page }) => {
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await page.waitForTimeout(500);
  expect(await page.locator('#results li').count()).toBe(1);
});

test('sleeps a whole second, then reads', async ({ page }) => {
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await page.waitForTimeout(1000);
  expect(await page.locator('#results li').count()).toBe(1);
});

test('fills the box, sleeps a second, then reads', async ({ page }) => {
  await page.getByLabel('Fruit').fill('papaya');
  await page.waitForTimeout(1000);
  expect(await page.locator('#results li').count()).toBe(1);
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/search.spec.js

Running 4 tests using 1 worker

  ✘  1 tests/search.spec.js:7:1 › reads the list as soon as the typing ends (184ms)
  ✓  2 tests/search.spec.js:12:1 › sleeps half a second, then reads (673ms)
  ✘  3 tests/search.spec.js:18:1 › sleeps a whole second, then reads (1.2s)
  ✓  4 tests/search.spec.js:24:1 › fills the box, sleeps a second, then reads (1.2s)


  1) tests/search.spec.js:7:1 › reads the list as soon as the typing ends ──────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: 1
    Received: 0

       7 | test('reads the list as soon as the typing ends', async ({ page }) => {
       8 |   await page.getByLabel('Fruit').pressSequentially('papaya');
    >  9 |   expect(await page.locator('#results li').count()).toBe(1);
         |                                                     ^
      10 | });
      11 |
      12 | test('sleeps half a second, then reads', async ({ page }) => {
        at /home/ana/quitanda/tests/search.spec.js:9:53

    Error Context: test-results/search-reads-the-list-as-soon-as-the-typing-ends/error-context.md

  2) tests/search.spec.js:18:1 › sleeps a whole second, then reads ─────────────────────────────────

    Error: expect(received).toBe(expected) // Object.is equality

    Expected: 1
    Received: 3

      19 |   await page.getByLabel('Fruit').pressSequentially('papaya');
      20 |   await page.waitForTimeout(1000);
    > 21 |   expect(await page.locator('#results li').count()).toBe(1);
         |                                                     ^
      22 | });
      23 |
      24 | test('fills the box, sleeps a second, then reads', async ({ page }) => {
        at /home/ana/quitanda/tests/search.spec.js:21:53

    Error Context: test-results/search-sleeps-a-whole-second-then-reads/error-context.md

  2 failed
    tests/search.spec.js:7:1 › reads the list as soon as the typing ends ───────────────────────────
    tests/search.spec.js:18:1 › sleeps a whole second, then reads ──────────────────────────────────
  2 passed (6.3s)
```

## Four verdicts, one page

Two failed and two passed, and none of the four said anything true about the search.

**Reading at once failed with `Received: 0`.** `pressSequentially` returns when the last key has
been pressed, and at that moment no answer has come back: the list is empty. The test did not
find a defect; it found that it had looked before the page could have answered.

**Half a second passed, and a whole second failed with `Received: 3`.** Same page, same typing,
opposite verdicts, and the only difference is the number in `waitForTimeout`. The figure in the
last section says why: at 500 ms the list happened to hold Papaya, and at 1000 ms it held the
three fruit it ends on. **The pass is the more dangerous of the two**, because it is the one
nobody investigates. It goes into the suite, it stays green, and it reports a correct search on a
page that shows the wrong fruit to anybody who types fast. On a slower server, where every answer
lands later, it could just as well fail, and then it fails *sometimes*, which is the subject of
lesson 14.

**`fill` passed, for a reason that has nothing to do with the sleep.** It is the fourth test
that matters most, because it is the one many people would write first.

## Why `fill` hides the race

`fill` is Playwright's usual way to type into a box, and for most boxes it is the right one:
it is fast, and it sets the value the way pasting does. **That is exactly why it never meets this
defect.** One change of value is one `input` event, one request, one answer, and nothing to race
against. The test passes, and the page it passed on is the page that shows three fruit to anybody
who types quickly.

`pressSequentially` exists for the opposite case: a page that reacts to each key, like a search
box that suggests as you type. Neither method is the right one in general. **A test should type
the way the page's users do whenever the page reacts to the way they type**, and a search box that
sends a request per key is such a page. Testing it only with `fill` tests the one way of typing,
pasting, that cannot meet the defect.
