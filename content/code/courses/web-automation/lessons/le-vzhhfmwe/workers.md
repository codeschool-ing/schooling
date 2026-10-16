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
asks for the next one. When the queue is empty the runner stops the workers, stops the shop and
prints the summary.

## How many workers you get

Nothing in `playwright.config.js` says how many, so Playwright decides. The decision is in the
installed package, one line of `node_modules/playwright/lib/common/config.js`:

```
%%CAP default50%%
```

`--workers` on the command line comes first, then `workers` in the configuration, and if neither
is there, `"50%"`. **Half of the machine's logical processors, rounded down, and never fewer
than one.** The function below it, `resolveWorkers`, turns the percentage into a number with
`os.cpus().length`. The laptop these transcripts come from has four:

```
%%CAP nproc%%
```

So a plain `npx playwright test` here runs two workers, and a machine with sixteen threads runs
eight. The same suite on two machines is two different runs, which is worth remembering the day a
test fails on one of them only.

## Files in parallel, tests in a file in order

Three files that leave the shop's data alone, `responsive`, `headless` and `deals`, nine tests
between them, run with four workers allowed:

```
%%CAP three-files%%
```

*Running 9 tests using 3 workers*: four were allowed and three were started, because there were
only three files to hand out. The numbers in the second column are the order the results came in,
and the four `responsive` tests that were allowed to fail by `test.fail()` in lesson 7 show the
✘ mark while still counting as passed. That mark is the list reporter saying the test failed,
which is what it was told to expect.

`--fully-parallel` changes the unit of work from the file to the test. The same three files:

```
%%CAP three-files-fp%%
```

Now all four workers are used, because there are nine tests to hand out rather than three files.
The setting also exists as `fullyParallel: true` in a configuration, for the whole run or for one
project, and as `test.describe.configure({ mode: 'parallel' })` inside one file. **Whether a file's
tests may run apart from each other is a fact about that file**, which is why the default keeps
them together: a file written as a sequence, where the second test reads what the first one left,
keeps working.

## The whole suite, three ways

The project now holds every test file from lessons 1 to 18. Here is all of it, timed by Playwright
itself, with one, two and four workers on this four-processor machine. The `grep` keeps the line
that says how many workers ran and the summary at the end:

```
%%CAP w1%%
%%CAP w2%%
%%CAP w4%%
```

The time falls with every worker added, from @@T1@@ to @@T4@@. **And the run goes red.** With one
worker every test passed; with two and four, some of the tests that put fruit in the basket
failed, and lesson 15 already met the reason. Two workers is also what a plain
`npx playwright test` uses here, so the project's default run is the red one. The next section
reads the failures.
