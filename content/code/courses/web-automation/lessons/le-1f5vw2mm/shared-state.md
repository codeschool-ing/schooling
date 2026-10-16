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
%%CAP basket-parallel%%
```

@@PARALLEL@@ The `beforeEach` reset ran in both workers, and **both resets did their job**: each
emptied the basket at the instant it ran. Then the other worker's clicks arrived in the same
basket. A reset at the start is safe only when nothing else is writing between the reset and the
last assertion, and in a parallel run something always might be.

@@FIGURE@@

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
%%CAP basket-serial%%
```

*Running 2 tests using 1 worker*: the file kept its tests together. **What serial mode does not do
is protect the file from other files.** `tests/banana.spec.js`, from lesson 11, also resets the
basket and adds to it. Run both files with two workers, the ordinary way a suite runs:

```
%%CAP basket-banana%%
```

@@BANANA@@ Serial mode is a statement about one file's tests, and the basket is a fact about the
server. The only arrangement that keeps every basket test away from every other is **one worker
for the tests that use the basket**:

```
%%CAP basket-one%%
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
