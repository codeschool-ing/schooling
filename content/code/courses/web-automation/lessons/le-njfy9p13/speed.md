---
title: Is headless faster?
version: 1
---

The usual claim is that headless is much faster, and it is repeated as if it were a measurement.
**It is a direction, and how much it is worth depends on what the suite spends its time on.** A
browser with no window skips putting pixels on a screen; it still parses, runs and lays out every
page, so the saving can only come from the part the screen took. The way to know is to time the
same tests both ways on the same machine.

## The suite

Five of the project's test files, from lessons 1, 2, 3, 5 and 6, run in one worker so that the
browser starts once and the tests run one after another. One run in full, so you can see what is
being timed:

```
ana@laptop:~/quitanda$ npx playwright test --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js

Running 10 tests using 1 worker

  ✓   1 tests/locators.spec.js:7:1 › banana, by its test id (208ms)
  ✓   2 tests/locators.spec.js:12:1 › add a mango, by role and name (210ms)
  ✓   3 tests/locators.spec.js:18:1 › a price, and the space nobody can see (156ms)
  ✓   4 tests/search.spec.js:7:1 › one request: filling the box finds papaya (159ms)
  ✘   5 tests/search.spec.js:13:1 › typed key by key, the list settles on papaya (6.0s)
  ✓   6 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (167ms)
  ✓   7 tests/spa.spec.js:3:1 › Basket opens the basket without loading a page (317ms)
  ✓   8 tests/spa.spec.js:18:1 › Basket opens the basket on a slow network (1.1s)
  ✘   9 tests/spa.spec.js:30:1 › the basket opens from its own address (110ms)
  ✓  10 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready (2.1s)

  10 passed (12.2s)
```

The two `✘` lines are the tests lessons 3 and 5 keep with `test.fail()`, counted among the passes.
The total on the last line is what the next runs compare.

## Three modes, three times each

The same command, in the shell, in new headless through `headless.config.js`, and headed under
Xvfb, repeated three times. `tail -1` keeps the summary line, which carries the run's total:

```
ana@laptop:~/quitanda$ npx playwright test --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (12.1s)
ana@laptop:~/quitanda$ npx playwright test --config headless.config.js --project=new-headless --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (14.2s)
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (15.4s)
ana@laptop:~/quitanda$ npx playwright test --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (12.5s)
ana@laptop:~/quitanda$ npx playwright test --config headless.config.js --project=new-headless --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (14.7s)
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (15.1s)
ana@laptop:~/quitanda$ npx playwright test --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (13.5s)
ana@laptop:~/quitanda$ npx playwright test --config headless.config.js --project=new-headless --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (17.5s)
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (18.0s)
```

**In every round the shell was fastest and the headed run slowest**, with new headless between
them: 12.1, 14.2 and 15.4 seconds in the first round, 12.5, 14.7 and 15.1 in the second. The third
round was slower in every mode, 13.5, 17.5 and 18.0, with nothing in the suite changed, which is why
a measurement is run more than once and read as a pattern rather than a figure.

**Most of the gap is between the two programs, not between a window and none.** New headless is the
same full browser as the headed run, and its times sit close to the headed ones: 1.2, 0.4 and 0.5
seconds apart. The shell, the smaller program, is two to four seconds ahead of both.

## What the number is made of

**Most of these seconds belong to the shop, not to the browser.** The search test waits for slow
answers on purpose (lesson 3), the server-rendered page holds its script back for a second and a
half (lesson 6), and the expected failure in `tests/search.spec.js` spends its whole timeout before
it counts as a pass. None of that gets faster without a window. A suite of a thousand short tests,
each opening a page and clicking once, spends a larger share of its time in the browser, and there
the difference would be larger. A suite like this one, made mostly of waits it means to have,
barely notices.

Two more things decide the time far more than the mode. Workers: lesson 19 runs these files in
parallel, which divides the total in a way no headless switch can. And the browser starting: each
worker starts one browser, so a suite of many small files pays that cost once per worker, not once
per test.

So the case for headless on a build server is mostly not speed. It needs no display, so there is
nothing to install and nothing to break; and it is what everybody else's pipeline runs, so a
failure there is one somebody has seen before. Run headed when you need the window, under Xvfb on
the server, and measure your own suite before you believe anybody's number, this lesson's
included.
