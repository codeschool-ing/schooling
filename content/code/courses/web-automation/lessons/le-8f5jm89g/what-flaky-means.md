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
  42 passed (12.8s)
  42 passed (12.5s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  40 passed (20.2s)
  42 passed (12.5s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  40 passed (20.2s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  40 passed (20.2s)
  42 passed (12.6s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  40 passed (20.3s)
  42 passed (12.4s)
  42 passed (12.5s)
```

**Four runs of ten failed, and the other six passed**, with no edit between any of them. Each
time the same two tests failed together: lesson 4's `a new offer reaches the page` and lesson 6's
`a click on /ssr adds to the basket once the page is ready`. A failing run took about 20 seconds
against about 12.5 for a passing one, because a failing check waits out its five seconds first.

Both tests begin with `POST /api/reset`, and that request resets the whole shop: it empties the
one basket and puts the offer back to Mango. Playwright runs files side by side, in two workers on this four-processor machine, and a reset
sent by one test can arrive in the middle of another. The cache test sets the offer to Banana and
then opens the page; a reset in between leaves Mango on it. Each test is right about a shop it
has to itself. The next section names this cause and shows it on two smaller tests.

## Why it is worse than red

A test that fails every time gets fixed or gets argued about, because nobody can merge past it.
A test that fails four times in ten gets **re-run**. The second run is green, the change goes in,
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

The other half is quieter. The six green runs above were not evidence that the two tests work;
they were runs where the reset happened to land somewhere harmless. The platform's own rules
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
