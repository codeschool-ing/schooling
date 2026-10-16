---
title: Deleting a test, and the defects the suite documents
version: 1
---

**A test that has not failed for a year is not, for that reason, useless.** It may guard
something that never broke because it was guarded, or something that would cost a great deal the
one time it did. What makes a test useless is that **it cannot fail**. Lesson 7 showed the shape:
`toBeHidden()` on its own passes on a button that was renamed or deleted, because a locator that
matches nothing counts as hidden. So the question to ask of a quiet test is not how long it has
been green. It is whether it would go red if the thing it guards broke, and the way to find out is
to break that thing on purpose and run it, as the experiment two sections back did with four edits.

## The tests worth deleting

- **A test that cannot fail**, found that way. Fix it so that it can, or delete it.
- **A test that checks what another test already checks**, at the same layer or a cheaper one.
  The second copy doubles the maintenance and catches nothing the first does not. Lesson 21 is
  about moving a check down a layer; once it has moved, the browser's copy can go.
- **A flaky test nobody is going to fix.** Lesson 14 is about what one does: a suite that is red for
  no reason teaches everybody to rerun it, and the run that is red for a real reason gets rerun
  too. A test like that is worse than no test, because no test at least leaves red meaning red.
  Lesson 14's quarantine carries an owner and a date for exactly this reason, and a test still
  there after its date belongs in this list.
- **A test of a feature that is gone.** It passes, or fails, about nothing.

**Delete with a reason, and write the reason where the next person looks**: in the commit that
removes it, say what the test checked, why it goes, and what covers that risk now, even when the
answer is *nothing, on purpose*. The history of the repository keeps the code; only you can keep
the reason, and a deletion with one is a decision somebody can disagree with later.

## The defects this suite documents

Lessons 3, 4, 5, 7 and 13 used `test.fail()` to keep a test for a known defect in the project. Here is
the project at the end of the course, and every place it does that:

```
ana@laptop:~/quitanda$ ls tests
banana.spec.js
basket-api.spec.js
basket-data.spec.js
basket-ui.spec.js
cache.spec.js
conditions.spec.js
contexts.spec.js
deals.spec.js
fixtures.js
headless.spec.js
locators.spec.js
names.spec.js
no-script.spec.js
offline.spec.js
page-object-card.spec.js
page-object.spec.js
responsive.spec.js
search.spec.js
setup-cost.spec.js
signup.spec.js
sleeps.spec.js
smoke.spec.js
spa.spec.js
ssr-html.spec.js
ssr.spec.js
targets.spec.js
toast.spec.js
two-fruit.spec.js
waiting.spec.js
ana@laptop:~/quitanda$ ls tests/*.spec.js | wc -l
28
```

```
ana@laptop:~/quitanda$ grep -rn "test.fail(" tests | wc -l
6
ana@laptop:~/quitanda$ grep -rn "test.fail(" tests
tests/search.spec.js:16:  test.fail();
tests/spa.spec.js:31:  test.fail(true, 'known defect: the server has no fallback for /spa/basket');
tests/conditions.spec.js:23:  test.fail();
tests/cache.spec.js:14:  test.fail(true, 'known flaw: GET /api/offer may be kept for ten minutes');
tests/cache.spec.js:23:  test.fail(true, 'known flaw: GET /api/offer may be kept for ten minutes');
tests/responsive.spec.js:46:    test.fail(overflows.includes(width), 'known defect: .basket is wider than a phone');
```

28 files and 6 lines. The suite run in the next section counts **7 tests
declared to fail**, because lesson 7's line is inside a loop and covers two widths. Each of them
is a promise to do something the day the shop is fixed, and the promise is different for each:

| line | the defect | the day it is fixed |
|---|---|---|
| `search.spec.js:16` (lesson 3) | the answer to *p* arrives last and replaces the list | Playwright reports *Expected to fail, but passed*; delete the line |
| `conditions.spec.js:23` (lesson 13) | the same defect, waited for with `waitForFunction` | the same day, the same red; then **keep one of the two** |
| `spa.spec.js:31` (lesson 5) | `/spa/basket` has no fallback on the server | delete the mark; the test then guards the fallback |
| `cache.spec.js:14` and `:23` (lesson 4) | the offer is sent with `max-age=600` | if the fix is `no-cache`, both pass the same day and both marks go |
| `responsive.spec.js:46` (lesson 7) | `.basket` is wider than a phone | take 360 and 390 out of `overflows`; this lesson's experiment saw that day |

**The second row is the one that asks for judgement.** Lesson 13 wrote its test to show a condition
of your own, and it does that well; as a regression check it watches the same defect as lesson 3's,
through the same page, in the same browser. The day the search is fixed, both go red together,
both marks come off, and the suite has two tests for one behaviour. Keep the one whose failure
message would tell a developer more, and delete the other with that reason in the commit.

**And the fourth row hides a test that is not marked.** `cache.spec.js` also holds *routing hides
the flaw*, which passes because routing turns the browser's cache off. It documents a trap in the
tool, not a defect in the shop, so it does not change when the shop is fixed. It stays as long as
somebody might add `page.route` to a cache test and believe the result.

## A mark that keeps passing for the wrong reason

`test.fail()` has the weakness lessons 3 and 7 named: it accepts any failure. A test declared to
fail on the search defect, which one day fails because the page no longer loads at all, is still
reported as a pass, and the defect it was watching could be fixed without anybody hearing. So the
script in the next section prints, for every declared failure, the first line of the error it
actually had. A list of seven is short enough to read once a month, and **every line should still
name the defect its comment names**.
