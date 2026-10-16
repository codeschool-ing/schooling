---
title: One worker for the tests that share the shop
version: 1
---

Lesson 15 gave `tests/basket-data.spec.js` the line `test.describe.configure({ mode: 'serial' })`
and said what it cannot do: it keeps one file's tests in order, and the other files still run
beside it. **What the shop needs is a rule about a group of files**: these may never run at the
same time as each other, and everything else may run beside them. Playwright has that rule, and it
lives on a **project**.

A project is a named slice of the configuration. Lesson 10 used three of them to run the suite in
three browsers. A project can also say which files it holds, with `testMatch` and `testIgnore`,
and, in the Playwright you installed, how many workers it may use at once, with `workers`. The run's own
`workers` is still the total; a project's number is a ceiling inside it.

## Which list to write

The obvious list is the files that touch the shop. It is also the wrong one to keep. **A list of
dangerous files fails open**: a new file that resets the basket, written next month by somebody
who never saw the list, runs in parallel by default and turns the suite red on some runs and not on others. The
list of files known to leave the shop alone fails the other way. A new file nobody classified
lands with the tests that take turns, where it is slower and never wrong, and somebody who wants
it faster has to look at it first.

Thirteen of the twenty-five files do not reset the shop or write to it: they read the page, the
HTML, the layout or the search, or make customers with names nobody else uses, as lesson 15's
`tests/setup-cost.spec.js` does. The configuration imports the project's own and adds two
projects. Save it as `turns.config.js`:

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
way the last section showed; this file is used by naming it. Four workers, three runs in a row:

```
%%CAP turns4%%
```

@@TURNS@@

## What it bought, and what it did not

@@TURNSTABLE@@

@@TURNSCOST@@ The one-at-a-time project is the longest path through the run, because every
test that touches the shop has to wait for the one before it. **Its total is the floor**: no
number of workers brings the run below it, and every test added to it raises the floor for
everyone.

`--workers 1` on the whole run, the bluntest answer, is also green, and costs the full serial
time on every run. The project rule keeps parallelism for the half of the suite that can have it.
It is still a cost paid on every run, and the comment at the top of `turns.config.js` says why
it is paid; the day the shop gets a basket per visitor, that comment and the second project are
what to delete.
