---
title: Same code, another verdict
version: 1
---

**A test is flaky when it gives a different verdict on the same code**: nobody changed the shop,
nobody changed the test, the machine is the same, and one run is green while the next is red. The
first belief most people hold about such a test is that it is a small nuisance, better than a test
that fails every time because at least it mostly passes. This lesson argues the opposite. A test
that always fails is information. A test that sometimes fails is noise, and noise teaches the
people who read it to stop reading.

## Your own suite has one

Everything you have saved under `tests/` since lesson 1 is what a plain `npx playwright test`
runs, and that run is what a team would call its gate: the check a change has to pass. Here it
is ten times in a row, with `grep` keeping the summary of each run and the names of any test
that failed:

```
ana@laptop:~/quitanda$ for i in 1 2 3 4 5 6 7 8 9 10; do npx playwright test | grep -E '^  [0-9]+ (failed|flaky|passed)|^    tests/'; done
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  49 passed (24.0s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  49 passed (24.1s)
  1 failed
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  50 passed (21.7s)
  1 failed
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  50 passed (21.3s)
  1 failed
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  50 passed (21.2s)
  1 failed
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  50 passed (21.6s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  49 passed (24.2s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  49 passed (24.0s)
  1 failed
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  50 passed (21.2s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  49 passed (24.4s)
```

**Not one of the ten runs passed, and they did not all fail the same way.** Lesson 6's `a click
on /ssr adds to the basket once the page is ready` failed in all ten. Lesson 4's `a new offer
reaches the page` failed in five of them, runs 1, 2, 7, 8 and 10, and passed in the other five,
with no edit between any of them.

Both tests begin with `POST /api/reset`, and that request resets the whole shop: it empties the
one basket and puts the offer back to Mango. Playwright runs files side by side, in two workers on
this four-processor machine, and a reset or a fruit sent by one test can arrive in the middle of
another. The cache test sets the offer to Banana and then opens the page; a reset in between
leaves Mango on it. The ssr test waits about a second and a half for its page to be ready before
it clicks, which leaves plenty of time for another test to put something in the basket. Each test
is right about a shop it has to itself.

The ssr test's ten failures out of ten look like the other kind of red, a defect in the page. They
are not: the next section runs it with one other test, one at a time, and it passes every time.
**A red that comes back every run is still information**, and here it points at the suite rather
than at the shop.

## Why it is worse than red

A test that fails every time gets fixed or gets argued about, because nobody can merge past it.
A test that fails five times in ten, like the cache test, gets **re-run**. The second run is green, the change goes in,
and the person who pressed the button learns that a red result from this suite means *try
again*. That lesson does not stay with one test. The day a change really does break the cache
test, the red is read the same way, and the defect is merged on the second attempt.

The platform you are studying on writes this down in several places, always for the same reason.
A check of its console's dictionary was written to report suspect entries, and on its first run
it reported ten correct ones. It was cut back, because *a check that cries wolf teaches whoever
reads it to skip the output that would one day name a real one*. Another check is deliberately
loose about the age of a data file, failing only after a year, because a bound of one quarter
would go red every time a quarter ticked over *and be silenced within a week*. **An alarm that
goes off without a fire is an alarm that will be switched off.**

## Green by luck

The other half is quieter. The cache test passed in five of the ten runs, and those passes were not
evidence that it works; they were runs where the reset happened to land somewhere harmless. The platform's own rules
describe one of its test suites the same way: it *passed locally on timing alone*, and that was
called worse than failing, *because it means the suite was green by luck*. A suite that is green
by luck tells you nothing on the days it is green.

## Flaky, or a defect?

Lesson 3 drew one line and this lesson keeps it. Its search test failed **every time**, at the same
line, with the same three fruit: that was a defect in the page, and the test was right. A flaky test
fails **sometimes**. Its cause can sit in the test, in what surrounds it, or in the page, and the
causes section shows a case where the page itself is what flickers. What tells the two apart is
repetition. One run tells you very little. Twenty runs tell you whether you are looking at a
rate.
