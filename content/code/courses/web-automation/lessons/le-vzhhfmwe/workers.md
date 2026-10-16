---
title: Workers, and what runs beside what
version: 1
---

**A Playwright worker is a separate Node process with its own browser, and the runner hands each
worker whole files to run.** Several workers run at the same time, so several files run at the
same time. Inside one file the tests still run one after another, in the order they are written,
in the same worker. The common picture is the other way round: that "parallel" means every test
starts at once. It does not, unless you ask for it.

The runner itself is one more process. It reads the configuration, starts the shop through
`webServer`, finds the tests, and keeps a queue of what is left. A worker that finishes a file
is handed the next one. When the queue is empty the runner stops the workers, stops the shop and
prints the summary.

## How many workers you get

Nothing in `playwright.config.js` says how many, so Playwright decides. The decision is in the
installed package, one line of `node_modules/playwright/lib/common/config.js`:

```
ana@laptop:~/quitanda$ grep -n '"50%"' node_modules/playwright/lib/common/config.js
97:      workers: resolveWorkers(takeFirst(configCLIOverrides.debug ? 1 : void 0, configCLIOverrides.workers, userConfig.workers, "50%")),
```

`--workers` on the command line comes first, then `workers` in the configuration, and if neither
is there, `"50%"`. **Half of the machine's logical processors, rounded down, and never fewer
than one.** The function below it, `resolveWorkers`, turns the percentage into a number with
`os.cpus().length`. The laptop these transcripts come from has four:

```
ana@laptop:~/quitanda$ nproc
4
```

So a plain `npx playwright test` here runs two workers, and a machine with sixteen threads runs
eight. The same suite on two machines is two different runs, which is worth remembering the day a
test fails on one of them only.

## Files in parallel, tests in a file in order

Three files that leave the shop's data alone, `responsive`, `headless` and `deals`, twelve tests
between them, run with four workers allowed:

```
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js tests/headless.spec.js tests/deals.spec.js --workers 4

Running 12 tests using 3 workers

  ✓   1 tests/deals.spec.js:10:3 › an iPhone, emulated in Chromium › gets the page for a phone (234ms)
  ✓   2 tests/headless.spec.js:3:1 › every product is fully on the first screen (308ms)
  ✓   4 tests/deals.spec.js:20:3 › a desktop browser in a phone-sized window › gets the page for a desktop (166ms)
  ✓   3 tests/responsive.spec.js:10:5 › 360 px wide › the links hide behind the Menu button (360ms)
  ✓   5 tests/headless.spec.js:9:1 › the page is the size the test asked for (180ms)
  ✓   7 tests/headless.spec.js:15:1 › a headless desktop browser gets the desktop deals page (133ms)
  ✓   6 tests/responsive.spec.js:10:5 › 600 px wide › the links hide behind the Menu button (265ms)
  ✓   8 tests/responsive.spec.js:27:5 › 601 px wide › the links show and the Menu button does not (167ms)
  ✓   9 tests/responsive.spec.js:27:5 › 1280 px wide › the links show and the Menu button does not (117ms)
  ✘  10 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (153ms)
  ✘  11 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (136ms)
  ✓  12 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (119ms)

  12 passed (2.9s)
```

*Running 12 tests using 3 workers*: four were allowed and three were started, because there were
only three files to hand out. The numbers in the second column are the order the tests were
started in, and the list prints each line when a test finishes, so they arrive out of order as soon
as two workers overlap. The two `responsive` tests that lesson 7 marked with `test.fail()` show
the ✘ mark and still count among the passed: the test failed, which is what it was told to
expect.

`--fully-parallel` changes the unit of work from the file to the test. The same three files:

```
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js tests/headless.spec.js tests/deals.spec.js --workers 4 --fully-parallel

Running 12 tests using 4 workers

  ✓   3 tests/headless.spec.js:9:1 › the page is the size the test asked for (293ms)
  ✓   2 tests/deals.spec.js:10:3 › an iPhone, emulated in Chromium › gets the page for a phone (289ms)
  ✓   4 tests/deals.spec.js:20:3 › a desktop browser in a phone-sized window › gets the page for a desktop (334ms)
  ✓   1 tests/headless.spec.js:3:1 › every product is fully on the first screen (386ms)
  ✓   5 tests/headless.spec.js:15:1 › a headless desktop browser gets the desktop deals page (156ms)
  ✓   8 tests/responsive.spec.js:27:5 › 601 px wide › the links show and the Menu button does not (264ms)
  ✓   6 tests/responsive.spec.js:10:5 › 360 px wide › the links hide behind the Menu button (356ms)
  ✓   9 tests/responsive.spec.js:27:5 › 1280 px wide › the links show and the Menu button does not (266ms)
  ✓   7 tests/responsive.spec.js:10:5 › 600 px wide › the links hide behind the Menu button (376ms)
  ✘  10 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (238ms)
  ✓  12 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (217ms)
  ✘  11 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (290ms)

  12 passed (2.6s)
```

Now all four workers are used, because there are twelve tests to hand out rather than three
files. The setting also exists as `fullyParallel: true` in a configuration, for the whole run or for one
project, and as `test.describe.configure({ mode: 'parallel' })` inside one file. **Whether a file's
tests may run apart from each other is a fact about that file**, which is why the default keeps
them together: a file written as a sequence, where the second test reads what the first one left,
keeps working.

## The whole suite, three ways

The project now holds every test file from lessons 1 to 18. Here is all of it, timed by Playwright
itself, with one, two and four workers on this four-processor machine. The `grep` keeps the line
that says how many workers ran and the summary at the end:

```
ana@laptop:~/quitanda$ npx playwright test --workers 1 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 1 worker
  61 passed (37.0s)
ana@laptop:~/quitanda$ npx playwright test --workers 2 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 2 workers
  3 failed
  1 did not run
  57 passed (28.1s)
ana@laptop:~/quitanda$ npx playwright test --workers 4 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 4 workers
  3 failed
  58 passed (16.7s)
```

The time falls with every worker added, from 37.0 seconds to 28.1 and then 16.7. **And the run
goes red.** With one worker every test passed; with two and with four, three tests that use the
shop failed, and lesson 15 already met the reason. Two workers is also what a plain
`npx playwright test` uses here, so the project's default run is the red one. The next section
reads the failures.
