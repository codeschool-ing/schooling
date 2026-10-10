---
title: A defect in the shop, not a flaky test
version: 1
---

The test that waits for `aria-busy="false"` failed, and it will fail on every run, at the same
line, with the same three fruit. **That is what separates a defect from a flaky test**: a flaky
test fails *sometimes* for a reason in the test or its surroundings, and lesson 14 is about those;
this one fails *every time* because the page is wrong. A customer who types fast and reads the list
gets the wrong fruit. The fix belongs in `search.js`, and your job is to say so in a way a
developer can act on.

## The report

`manual-testing` lesson 15 covers what a defect report needs. This one writes itself from the
evidence the lesson has already produced:

- *what was done*: on `/search.html`, type `papaya` with no pause between keys;
- *what was expected*: the list shows Papaya, the count says *1 found*;
- *what happened*: the list shows Papaya, Passion fruit and Pineapple and the count says
  *3 found*, once `aria-busy` is `false`;
- *why*: one request per key, answers arrive in reverse because short queries are slower, and
  the page draws whichever answer arrives last, including answers to questions the box no longer
  asks;
- *how to see it*: the output of `race.mjs`, and the failing test.

The last line is what makes the report hard to dismiss. *Works for me* is a common first answer
to a timing defect, and it is true: the developer typed at a person's speed.

## What to do with the test meanwhile

The test is right and the suite is red. Three things can happen to it while the defect waits for a
fix, and only one of them keeps both the suite and the test honest.

**Delete it, or keep it out of the project**, and the defect lives only in the report. Nobody will
notice when it is fixed, nor if it comes back after the fix.

**Skip it** with `test.skip()`, and Playwright does not run it at all. The suite turns green, the
test stops looking, and the day the defect is fixed nothing tells anybody to switch it back on.

**Mark it as expected to fail** with `test.fail()`. Playwright runs it every time and reports it as
passing **as long as it fails**. The day somebody fixes the page, the test passes, and Playwright
reports *that* as a failure: the annotation is now wrong and has to go. The test keeps watching the
defect from both sides. This is the one the course uses, and the final version of the file carries
it. A test with `fill` stays beside it, written with web-first assertions this time, because it
checks the half of the page with no race in it. Save it as `tests/search.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/search.html');
});

test('one request: filling the box finds papaya', async ({ page }) => {
  await page.getByLabel('Fruit').fill('papaya');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
  await expect(page.locator('#count')).toHaveText('1 found');
});

test('typed key by key, the list settles on papaya', async ({ page }) => {
  // A known defect, reported: the answer to "p" arrives last and replaces
  // the list. Delete this line when it is fixed; the test must then pass.
  test.fail();
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
  await expect(page.locator('#count')).toHaveText('1 found');
});
```

```
%%CAP v3%%
```

**Read the marks and the summary separately.** The mark beside each test says what the test did:
the second one failed, so it carries `✘`, after retrying for its five seconds. The summary says
whether each test did what it was declared to do, and a test declared to fail that failed is
counted among the *2 passed*. Look at the comment above `test.fail()`: it says what the defect is
and what to do when it is fixed. An annotation without that sentence is a red test hidden for a
reason nobody can find again.

## The day it is fixed

A fix is the developer's to write, and there is more than one. The page could cancel the older
request when a new key arrives (`fetch` takes an `AbortSignal` for that), or it could remember what
it asked and drop any answer to a question the box no longer holds. Here is the second, as a
replacement for the listener in `app/public/search.js`:

```javascript
%%CAP fixed-listener%%
```

With that change in place, the same test file:

```
%%CAP v3-fixed%%
```

**The marks and the summary have swapped.** The second test passed, so it carries `✓`, and
because it was declared to fail, the summary counts it as *1 failed* and explains: *Expected to
fail, but passed.* That is the annotation doing its job: it turned *the defect is fixed* into a
red line nobody can miss, and the fix to the test is to delete one line. If you try the change yourself, put the original `search.js` back afterwards. The
shop's flaws are kept on purpose.

`test.fail()` has a weakness worth knowing before you rely on it: **it accepts any failure**. If
the search page stopped loading at all, the test would fail before it typed a key and still
be reported as passing. That is the price of a quarantine, and lesson 14 is about paying it
carefully.
