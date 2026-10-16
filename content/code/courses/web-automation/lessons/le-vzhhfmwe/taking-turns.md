---
title: One worker for the tests that share the shop
version: 1
---

Lesson 15 gave `tests/basket-data.spec.js` the line `test.describe.configure({ mode: 'serial' })`
and said what it cannot do: it keeps one file's tests in order, and the other files still run
beside it. **What the shop needs is a rule about a group of files**: these never run at the same
time as each other, and everything else may run in parallel. In Playwright that rule lives on a
**project**.

A project is a named slice of the configuration. Lesson 10 used three of them to run the suite in
three browsers. A project can also say which files it holds, with `testMatch` and `testIgnore`,
and how many workers it may use at once, with `workers`. The run's own `workers` is still the
total; a project's number is meant as a ceiling inside it.

## Which list to write

The obvious list is the files that touch the shop. It is also the wrong one to keep. **A list of
dangerous files fails open**: a new file that resets the basket, written next month by somebody
who never saw the list, runs in parallel by default and turns the suite red on some runs and not
on others. The list of files known to leave the shop alone fails the other way. A new file nobody
classified lands with the tests that take turns, where it is slower and never wrong, and somebody
who wants it faster has to look at it first.

Thirteen of the twenty-five files, thirty of the sixty-one tests, do not reset the shop or write
to it: they read the page, the HTML, the layout or the search, or make customers with names nobody
else uses, as lesson 15's `tests/setup-cost.spec.js` does. The configuration imports the project's own and adds two projects. Save it as
`turns.config.js`:

```javascript
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

// The shop keeps one basket, one offer and one list of customers for
// everybody, and a reset empties all three. Only the files listed here are
// known to leave them alone, so only they run in parallel. Every other file,
// including any file added after this list was written, runs in a project
// with one worker: one test at a time.
const leavesTheShopAlone = [
  'deals.spec.js',
  'headless.spec.js',
  'names.spec.js',
  'no-script.spec.js',
  'offline.spec.js',
  'page-object-card.spec.js',
  'responsive.spec.js',
  'search.spec.js',
  'setup-cost.spec.js',
  'smoke.spec.js',
  'spa.spec.js',
  'ssr-html.spec.js',
  'targets.spec.js',
];

export default defineConfig(base, {
  projects: [
    { name: 'parallel', testMatch: leavesTheShopAlone },
    { name: 'one-at-a-time', testIgnore: leavesTheShopAlone, workers: 1 },
  ],
});
```

A bare file name in `testMatch` is matched anywhere under `testDir`, the way `**/deals.spec.js`
would be. `playwright.config.js` is untouched, so a plain `npx playwright test` still runs the
way the first section showed; this file is used by naming it.

## Checking the ceiling, not the colour

A green run does not prove the rule held. Two shop files can overlap and still not collide, because
a collision needs one to write in the other's window, so the summary is the wrong evidence. The
JSON report has what is needed: for every test, its project, when it started and how long it
took. The program below counts the most tests of one project that were running at the same
moment, and prints how many tests of the run failed. Save it as `at-once.mjs`:

```javascript
// Reads a JSON report from Playwright and prints the most tests of one
// project that were running at the same moment, and how many tests of the
// whole run ended in a way they were not expected to.
import { readFileSync } from 'node:fs';

const [file, project] = process.argv.slice(2);
const report = JSON.parse(readFileSync(file, 'utf8'));
const moments = [];
const visit = (suite) => {
  for (const spec of suite.specs ?? []) {
    for (const test of spec.tests) {
      if (test.projectName !== project) continue;
      for (const result of test.results) {
        if (result.status === 'skipped') continue;
        const start = Date.parse(result.startTime);
        moments.push([start, +1], [start + result.duration, -1]);
      }
    }
  }
  for (const child of suite.suites ?? []) visit(child);
};
report.suites.forEach(visit);

// At the same instant, a test that ends is counted before one that starts.
moments.sort((a, b) => a[0] - b[0] || a[1] - b[1]);
let running = 0;
let most = 0;
for (const [, change] of moments) {
  running += change;
  most = Math.max(most, running);
}
console.log(`${project}: at most ${most} at once; ${report.stats.unexpected} failed`);
```

Every start adds one and every end takes one away; the highest the count reaches is the answer,
and with `workers: 1` it should be 1. Five runs with four workers and five with eight, each
writing its JSON report and checking it:

```
ana@laptop:~/quitanda$ for w in 4 4 4 4 4 8 8 8 8 8; do PLAYWRIGHT_JSON_OUTPUT_FILE=turns.json npx playwright test --config turns.config.js --workers $w --reporter=json > /dev/null; printf "workers %s  " $w; node at-once.mjs turns.json one-at-a-time; done
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 2 at once; 1 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 2 at once; 1 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 3 at once; 2 failed
workers 8  one-at-a-time: at most 3 at once; 1 failed
workers 8  one-at-a-time: at most 3 at once; 2 failed
```

**The ceiling did not hold.** In two of the five runs with four workers the one-at-a-time project
had two tests running at once, and in three of the five with eight it had three; every one of those
runs failed a test, and every run where the count stayed at 1 failed none. A summary would have
shown five green runs and five red ones and no reason. The count says the rule was broken before
anything collided.

## Why, and the arrangement that holds

The reason is in `node_modules/playwright/lib/runner/dispatcher.js`, in `_findFirstJobToRun`. Before
handing out a file from a limited project, the dispatcher counts the busy workers **whose process
already belongs to that project**. A worker that ran a `parallel` file has to be stopped and
replaced before it can run a `one-at-a-time` one, and while that happens it is busy but still
counted as `parallel`. When several workers run out of `parallel` files at once, each is handed a
`one-at-a-time` file, and none of them sees the others. A rule that holds when the timing is kind
makes a suite that fails on some runs and not on others, and lesson 14 is about those.

**The arrangement that holds is to stop the two groups from overlapping in time.** A project can
name another in `dependencies`, and Playwright then runs them in **phases**: every test of the
dependency first, then the project that waits for it. Each phase gets a dispatcher of its own,
starting with no workers, so the count the limit relies on is right from the first file. The same
file, with `dependencies` added to the second project and the comments saying why. Save it as
`turns.config.js`:

```javascript
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

// The shop keeps one basket, one offer and one list of customers for
// everybody, and a reset empties all three. Only the files listed here are
// known to leave them alone, so only they run in parallel. Every other file,
// including any file added after this list was written, runs afterwards in a
// project with one worker: one test at a time.
const leavesTheShopAlone = [
  'deals.spec.js',
  'headless.spec.js',
  'names.spec.js',
  'no-script.spec.js',
  'offline.spec.js',
  'page-object-card.spec.js',
  'responsive.spec.js',
  'search.spec.js',
  'setup-cost.spec.js',
  'smoke.spec.js',
  'spa.spec.js',
  'ssr-html.spec.js',
  'targets.spec.js',
];

export default defineConfig(base, {
  projects: [
    { name: 'parallel', testMatch: leavesTheShopAlone },
    // A phase of its own: workers: 1 alone did not hold beside another
    // project in Playwright 1.56.
    {
      name: 'one-at-a-time',
      testIgnore: leavesTheShopAlone,
      workers: 1,
      dependencies: ['parallel'],
    },
  ],
});
```

The same ten runs:

```
ana@laptop:~/quitanda$ for w in 4 4 4 4 4 8 8 8 8 8; do PLAYWRIGHT_JSON_OUTPUT_FILE=turns.json npx playwright test --config turns.config.js --workers $w --reporter=json > /dev/null; printf "workers %s  " $w; node at-once.mjs turns.json one-at-a-time; done
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
```

At most one at a time in all ten, and nothing failed.

## What it costs

| workers | `playwright.config.js` | `turns.config.js` |
|---|---|---|
| 1 | 37.0 s, every test passed | 37.9 s, every test passed |
| 2 | 28.1 s, 3 failed | 33.0 s, every test passed |
| 4 | 16.7 s, 3 failed | 33.1 s, every test passed |
| 8 | not run | 34.1 s, every test passed |

The left column is the first section's runs; the right one is the same command with
`--config turns.config.js`, one run each:

```
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --workers 1 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 1 worker
  61 passed (37.9s)
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --workers 2 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 2 workers
  61 passed (33.0s)
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --workers 4 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 4 workers
  61 passed (33.1s)
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --workers 8 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 8 workers
  61 passed (34.1s)
```

Green costs time. With four workers the run takes 33.1 seconds instead of 16.7, and it hardly
moves between two workers and eight, because thirty-one of the sixty-one tests run one after
another whatever the count. **The one-at-a-time phase is a floor**: every test in it waits for the one before it,
no number of workers shortens it, and every test added to it raises the floor for everyone.

Phases have a second price. A dependency that fails stops the project waiting for it: the runner's
own code, in `lib/runner/tasks.js`, leaves out every project whose dependencies did not all pass,
so if a test in `parallel` fails, `one-at-a-time` does not run at all. That is the right behaviour
for the setup projects dependencies were designed for, and a nuisance here, where the two groups do
not need each other: a red `parallel` phase hides whether the shop's tests would have passed.

All of this is a cost paid on every run because the shop keeps one basket. The comment at the top
of `turns.config.js` says so; the day the shop gets a basket per visitor, the second project is
what to delete.
