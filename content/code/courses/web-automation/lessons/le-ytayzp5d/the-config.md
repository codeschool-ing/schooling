---
title: A configuration that keeps the evidence
version: 1
---

A failed test in the terminal tells you **what** went wrong and rarely **why**. Lesson 6's first
test of the server-rendered page clicked a button as soon as it was drawn, and failed with
*expected "1", received "0"*: the basket count never moved. The call log under that line cannot
tell you which of four stories is true. The click missed the button, or the click landed and
nothing listened, or the request went out and failed, or the server counted wrong. Lesson 6 knew
the answer because it had read the page first. A test that fails in a suite of two hundred comes
with no such knowledge.

On your own computer you would run it again with the window open and watch. **On a build server
nobody watches**, the run that failed is gone, and the next one may pass. The evidence has to be
collected during the run that failed, by the run itself.

## Three settings and a reporter

Playwright collects three kinds of evidence, each switched on by one key under `use`. This course
keeps `playwright.config.js` as lesson 1 wrote it, so the settings go in a second file that imports
it and changes only what this lesson needs. Save it as `evidence.config.js`:

```javascript
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

// The base configuration, plus the evidence a failing test leaves behind.
// It reads its tests from evidence/, where every test fails on purpose.
export default defineConfig({
  ...base,
  testDir: 'evidence',
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    ...base.use,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'retain-on-failure',
  },
});
```

`...base` copies everything lesson 1 set, the shop started by `webServer` included, and the keys
after it replace what they name. `...base.use` keeps the `baseURL` inside `use`, which a bare
`use: {…}` would have thrown away. The three settings:

- **`screenshot: 'only-on-failure'`** takes one picture of the page when a test fails, at the end;
- **`video: 'retain-on-failure'`** films every test and deletes the film of each one that passes;
- **`trace: 'retain-on-failure'`** records a trace, lesson 10's file of actions, snapshots,
  network and console, for every test, and deletes it when the test passes.

The reporter list keeps the `list` lines in the terminal and also writes the HTML report of
lesson 10, with `open: 'never'` so a failing run does not try to open a browser window. You choose
the file with `--config`.

## Where tests that fail on purpose live

This lesson needs tests that fail, because a failure is what it diagnoses, and it must not leave
the project's suite red. Lesson 3 met the same problem and chose `test.fail()`. **Here
`test.fail()` would destroy the very thing the lesson is about.** *Retain on failure* means: keep the
evidence when a test did not do what it was declared to do. A test declared to fail that fails did
exactly that, so Playwright counts it as a pass and throws the trace away. Lesson 3's own file
shows it, run with the trace setting from the command line:

```
%%CAP quarantined%%
```

The second test failed, as its `✘` says, and the only thing left in `test-results/` is the file
Playwright keeps about the last run. A quarantined test leaves no evidence behind, and lesson 14,
which is about quarantine, has to live with that.

So the tests of this lesson go in a folder of their own, `evidence/`, which the base configuration
never reads, since its `testDir` is `tests`. A plain `npx playwright test` stays green; the failures
run only when you ask for them with `--config evidence.config.js`. Each file starts with a comment
saying it fails on purpose, so nobody fixes it by mistake. The first is lesson 6's test, unchanged
apart from its title. Save it as `evidence/ssr.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The basket is shared, so the test starts by emptying it.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

// Fails on purpose: it clicks as soon as the button is drawn, before the
// script that makes the buttons work has arrived (lesson 6).
test('a click on /ssr, at once', async ({ page }) => {
  await page.goto('/ssr');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});
```

```
%%CAP ssr-evidence%%
```

**The top half is lesson 6's failure, and the bottom half is new.** Four things are attached: a
screenshot, a video, an error context and a trace, each with its path under `test-results/`. The
attachments are numbered in the order Playwright collected them; the error context is printed with
a label of its own, which is why the numbering skips 3. The next section opens each one.
