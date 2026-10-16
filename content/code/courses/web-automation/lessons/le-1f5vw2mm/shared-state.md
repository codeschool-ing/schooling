---
title: One basket for everybody
version: 1
---

**A reset puts the shop in a known state at one moment, and in a parallel run that moment belongs
to somebody else.** The basket file passed because its two tests ran one after the other, each
reset followed by its own clicks. Run them at the same time and every reset lands in the middle of
the other test. That is the shop's unmarked flaw from lesson 1, which lesson 10 showed with two
browser contexts: the basket lives on the server, as one list, and nothing in a test can give a
test a basket of its own.

## Two tests at once

Playwright runs files in parallel and the tests inside a file one after another, unless told
otherwise; lesson 19 is about those rules. `--fully-parallel` tells it otherwise for one run, so
the two tests of the same file go to two workers at the same moment:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js --fully-parallel --workers 2

Running 2 tests using 2 workers

  ✓  1 tests/basket-data.spec.js:11:1 › a banana costs R$ 5,90 (276ms)
  ✘  2 tests/basket-data.spec.js:18:1 › two mangoes cost R$ 9,00 (5.4s)


  1) tests/basket-data.spec.js:18:1 › two mangoes cost R$ 9,00 ─────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  locator('.basket-total')
    Expected: "R$ 9,00"
    Received: "R$ 14,90"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for locator('.basket-total')
        9 × locator resolved to <span class="basket-total">R$ 14,90</span>
          - unexpected value "R$ 14,90"


      21 |   await add(page, 'mango');
      22 |   await expect(page.getByTestId('basket-count')).toHaveText('2');
    > 23 |   await expect(page.locator('.basket-total')).toHaveText('R$ 9,00');
         |                                               ^
      24 | });
      25 |
        at /home/ana/quitanda/tests/basket-data.spec.js:23:47

    Error Context: test-results/basket-data-two-mangoes-cost-R-9-00/error-context.md

  1 failed
    tests/basket-data.spec.js:18:1 › two mangoes cost R$ 9,00 ──────────────────────────────────────
  1 passed (6.7s)
```

The banana test passed and the mango test found R$ 14,90: one banana and two mangoes, in a basket both tests had just reset. The banana test passed because its page shows the answer to its own click and is never redrawn; its count check had already read its `1`. The mango test's count check even passed, having read the `2` drawn by its first click's answer before the second answer arrived, which is lesson 13's subject. The `beforeEach` reset ran in both workers, and **both resets did their job**: each
emptied the basket at the instant it ran. Then the other worker's clicks arrived in the same
basket. A reset at the start is safe only when nothing else is writing between the reset and the
last assertion, and in a parallel run something always might be.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two workers share the shop's one basket. Worker 1, the banana test, resets the basket and adds a banana. Worker 2, the mango test, resets it too and adds two mangoes. The basket on the server goes 0, 0, 1, 2, 3. The banana test reads 1 from its own answer and passes; the mango test expects R$ 9,00 and reads R$ 14,90.\"><text x=\"20\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">worker 1</text><text x=\"20\" y=\"68\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the banana test</text><text x=\"20\" y=\"212\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">worker 2</text><text x=\"20\" y=\"228\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the mango test</text><text x=\"20\" y=\"132\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the basket</text><text x=\"20\" y=\"148\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">on the server</text><rect x=\"162\" y=\"38\" width=\"76\" height=\"26\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"200\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">reset</text><rect x=\"342\" y=\"38\" width=\"76\" height=\"26\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"380\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+ banana</text><rect x=\"595\" y=\"38\" width=\"90\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"640\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sees 1: passes</text><rect x=\"252\" y=\"198\" width=\"76\" height=\"26\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"290\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">reset</text><rect x=\"432\" y=\"198\" width=\"76\" height=\"26\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"470\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+ mango</text><rect x=\"522\" y=\"198\" width=\"76\" height=\"26\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"560\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+ mango</text><rect x=\"595\" y=\"198\" width=\"90\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"640\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 14,90</text><path d=\"M200 64 L200 116\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"200\" cy=\"131\" r=\"14\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></circle><text x=\"200\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M290 198 L290 146\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"290\" cy=\"131\" r=\"14\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></circle><text x=\"290\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M380 64 L380 116\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"380\" cy=\"131\" r=\"14\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></circle><text x=\"380\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><path d=\"M470 198 L470 146\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"470\" cy=\"131\" r=\"14\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></circle><text x=\"470\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><path d=\"M560 198 L560 146\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"560\" cy=\"131\" r=\"14\" fill=\"var(--amber)\" stroke=\"var(--wire)\"></circle><text x=\"560\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--ink)\">3</text><path d=\"M214 131 L276 131 M304 131 L366 131 M394 131 L456 131 M484 131 L546 131\" stroke=\"var(--wire)\"></path><text x=\"380\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">each reset empties the basket for both tests; every click after it lands in the same list</text></svg>", "caption": "One order of events that fits the run above. Both resets happen before any click, and still neither test has the basket to itself."}
```

The usual reaction is to reset more often: before every click, or right before the assertion. It
narrows the window and never closes it, because a click from the other worker can land between any
two lines. And every extra reset is another chance to wipe the other test's basket halfway through,
so the failures move around instead of going away. Under parallel runs, **a shared resource with a
reset is a race, however the resets are placed.**

## The real fix is in the shop

Unique data fixed the customers because each test could make its own. The basket cannot be made
unique from the outside: there is one, and the API has no way to ask for another. **The fix is a
change to the application**: a basket per visitor, kept by a cookie or a session, so that a test
in a fresh browser context, which lesson 10 showed has no cookies, gets an empty basket of its own
without resetting anything.

That is a developer's change, and the tester's part is to ask for it with the evidence: the run
above, the line of `app/routes/shop.js` that keeps one `store.basket`, and what it costs, which is
a suite that cannot run its basket tests in parallel. The same flaw is a defect for customers too:
two people shopping at once share a basket, and lesson 10's capture is the proof. Testability is
a feature, and asking for it is part of the job; `manual-testing` lesson 15 covers the report.

## Meanwhile: the tests take turns

Until the shop changes, the tests that share the basket must not run at the same time. Playwright
has a setting for one file: `test.describe.configure({ mode: 'serial' })` runs the file's tests in
order in one worker, even when the run asks for full parallelism, and if one fails it skips the
rest, since they may depend on what it left. Save it as `tests/basket-data.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The shop keeps one basket for everybody: these tests take turns.
test.describe.configure({ mode: 'serial' });

const add = (page, id) =>
  page.getByTestId(`product-${id}`).getByRole('button', { name: 'Add to basket' }).click();

// Every test starts from an empty basket.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a banana costs R$ 5,90', async ({ page }) => {
  await page.goto('/');
  await add(page, 'banana');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
});

test('two mangoes cost R$ 9,00', async ({ page }) => {
  await page.goto('/');
  await add(page, 'mango');
  await add(page, 'mango');
  await expect(page.getByTestId('basket-count')).toHaveText('2');
  await expect(page.locator('.basket-total')).toHaveText('R$ 9,00');
});
```

The same command as before:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js --fully-parallel --workers 2

Running 2 tests using 1 worker

  ✓  1 tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 (236ms)
  ✓  2 tests/basket-data.spec.js:21:1 › two mangoes cost R$ 9,00 (345ms)

  2 passed (2.1s)
```

*Running 2 tests using 1 worker*: the file kept its tests together. **What serial mode does not do
is protect the file from other files.** `tests/banana.spec.js`, from lesson 11, also resets the
basket and adds to it. Run both files with two workers, the ordinary way a suite runs:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js tests/banana.spec.js --workers 2

Running 3 tests using 2 workers

  ✓  1 tests/banana.spec.js:3:1 › a banana goes into the basket (274ms)
  ✘  2 tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 (5.3s)
  -  3 tests/basket-data.spec.js:21:1 › two mangoes cost R$ 9,00


  1) tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ───────────────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  getByTestId('basket-count')
    Expected: "1"
    Received: "2"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for getByTestId('basket-count')
        9 × locator resolved to <span data-testid="basket-count">2</span>
          - unexpected value "2"


      15 |   await page.goto('/');
      16 |   await add(page, 'banana');
    > 17 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
         |                                                  ^
      18 |   await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
      19 | });
      20 |
        at /home/ana/quitanda/tests/basket-data.spec.js:17:50

    Error Context: test-results/basket-data-a-banana-costs-R-5-90/error-context.md

  1 failed
    tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ────────────────────────────────────────
  1 did not run
  1 passed (6.7s)
```

The basket file's banana test counted 2, the other file's banana included, and serial mode then skipped the mango test, *1 did not run*, because a serial file stops at its first failure. Serial mode is a statement about one file's tests, and the basket is a fact about the
server. The only arrangement that keeps every basket test away from every other is **one worker
for the tests that use the basket**:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-data.spec.js tests/banana.spec.js --workers 1

Running 3 tests using 1 worker

  ✓  1 tests/banana.spec.js:3:1 › a banana goes into the basket (218ms)
  ✓  2 tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 (284ms)
  ✓  3 tests/basket-data.spec.js:21:1 › two mangoes cost R$ 9,00 (331ms)

  3 passed (2.2s)
```

`--workers 1` on the command line is the bluntest form, and it makes the whole run serial. Lesson
19 shows how to give only the basket tests a single worker while the rest of the suite runs in
parallel. Both are a cost paid every run, and the comment at the top of the file says why it is
being paid. When the shop gets a basket per visitor, that comment is the line to delete.

| | fixes the data? | keeps parallel runs? | whose work |
|---|---|---|---|
| reset at the start | only when one test runs at a time | no | the tester's |
| serial mode for the file | inside that file | other files still collide | the tester's |
| one worker for basket tests | yes | for everything else | the tester's |
| a basket per visitor | yes | yes | the developer's, on request |
