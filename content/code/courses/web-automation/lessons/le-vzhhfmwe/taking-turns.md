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

@@SAFECOUNT@@ The configuration imports the project's own and adds two projects. Save it as
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
way the first section showed; this file is used by naming it. Four workers, three runs in a row:

```
%%CAP turns4-v1%%
```

Green three times. With eight workers:

```
%%CAP turns8-v1%%
```

```
%%CAP overlap8-v1%%
```

@@V1READ@@

## Why, and the arrangement that holds

The reason is in `node_modules/playwright/lib/runner/dispatcher.js`, in `_findFirstJobToRun`. Before
handing out a file from a limited project, the dispatcher counts the busy workers **whose process
already belongs to that project**. A worker that ran a `parallel` file has to be stopped and
replaced before it can run a `one-at-a-time` one, and while that happens it is busy but still
counted as `parallel`. When several workers run out of `parallel` files at once, each is handed a
`one-at-a-time` file, and none of them sees the others. Four workers were green three times, and
the summary cannot say whether two of those files overlapped there without colliding; nothing in
the rule kept them apart. A rule that holds by luck makes a suite that fails on some days and not
on others, and lesson 14 is about those.

**The arrangement that holds is to stop the two groups from overlapping in time.** A project can
name another in `dependencies`, and Playwright then runs them in **phases**: every test of the
dependency first, then the project that waits for it. Each phase gets a dispatcher of its own,
starting with no workers, so the count the limit relies on is right from the first file. The same
file with one line more in the second project. Save it as `turns.config.js`:

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

```
%%CAP turns-v2%%
```

@@V2READ@@

## What it costs

@@TURNSTABLE@@

@@TURNSCOST@@ **The one-at-a-time phase is a floor**: every test in it waits for the one before it,
no number of workers shortens it, and every test added to it raises the floor for everyone.

Phases have a second price. A dependency that fails stops the project waiting for it: the runner's
own code, in `lib/runner/tasks.js`, leaves out every project whose dependencies did not all pass,
so if a test in `parallel` fails, `one-at-a-time` does not run at all. That is the right behaviour for the setup projects dependencies were designed for, and a
nuisance here, where the two groups do not need each other. Read a red run's summary for *did not
run* before deciding what failed.

All of this is a cost paid on every run because the shop keeps one basket. The comment at the top
of `turns.config.js` says so; the day the shop gets a basket per visitor, the second project is
what to delete.
