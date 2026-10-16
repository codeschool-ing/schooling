---
title: Quarantine, out of the gate and still running
version: 1
---

**A quarantine moves a test that is known to be flaky out of the gate, without deleting it and
without silencing it.** The gate goes back to meaning something: red is a change that broke
something. The test goes on running somewhere else, where its failures are counted rather than
obeyed, and it carries a name, a date and a reason that say who brings it back and when.

The three things people do instead each lose something. Deleting the test loses the defect it
was finding. Skipping it stops it looking, and nothing says when to start again. Retrying it, the
previous section showed, keeps it in the gate and hides it there.

## Where the quarantine lives

There are two common ways to keep a test out of the gate. The first is a **tag**: the test stays
in its file, is labelled `@quarantine`, and the gate runs `npx playwright test --grep-invert
@quarantine`, while a second job runs `npx playwright test --grep @quarantine`. The second is a
**place**: the test moves to a folder the gate never reads, with its own configuration.

This project uses the place, and the reason is the gate itself. Here the gate is the plain
command, `npx playwright test`, and `npm test` is the same command. A tag keeps a test out only
of the runs that remember `--grep-invert`. Every new CI job, every script and every person typing
the command has to remember it, and the first one who does not puts the flaky test back in the
gate. A folder the gate's configuration does not read cannot be forgotten. The tag is kept
as well, on the test itself, because it names the test as quarantined in every report and lets
`--grep @quarantine` find it wherever it ends up. A large suite where moving a file would lose its
place among its neighbours may reasonably choose the tag; it then has to hold the flag in one
shared place rather than in every command.

**A quarantined test carries who owns it, until when, and why.** Playwright lets a test declare
an `annotation`, a type and a description, which its HTML report shows beside the test, its
documentation says. The comment says the rest: what the defect is, and what has to be true for
the test to go back. This replaces the test from the diagnosis section. Save it as
`quarantine/typing.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// QUARANTINED: lesson 3's search defect, at a speed where it shows only some
// of the time. The test is right and the page is wrong. It goes back into
// tests/ when search.js drops answers to questions the box no longer asks.
test('typed at 145 ms a key, the list settles on papaya', {
  tag: '@quarantine',
  annotation: {
    type: 'quarantine',
    description: 'owner: ana; review by 2026-11-10; reported as the search defect',
  },
}, async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').pressSequentially('papaya', { delay: 145 });
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});
```

## The gate and the quarantine job

The gate, as it stands at the end of this lesson:

```
ana@laptop:~/quitanda$ npx playwright test | grep -E '^  [0-9]+ (failed|flaky|passed)'
  1 failed
  50 passed (21.3s)
```

The quarantine job, run the way a quarantine should be run, many times, so the result is a rate:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  8 failed
  12 passed (42.5s)
```

In CI the two are separate jobs. The gate's result decides whether a change goes in; the
quarantine's result decides nothing, and is read for its count. `testing-cicd` lesson 5 is about
building those jobs. The gate above is red, as it was on all ten runs in the first section: the ssr test meets a basket
another test has just added to. Quarantining it would be the wrong answer, because the defect is in
how the tests share data rather than in the test or the page, and lesson 15 fixes it there.

## skip, fixme and fail

Playwright has three annotations that look like they could do a quarantine's job, and each says
something different.

| | runs the test? | what it says |
|---|---|---|
| `test.skip()` | no | this test does not apply here, for example on a browser it cannot run in |
| `test.fixme()` | no | this test is known to be broken and somebody has to fix it |
| `test.fail()` | yes | this test is expected to fail; it is reported as an error if it passes |

**`test.skip` and `test.fixme` stop the test running**, so a skipped test cannot tell you whether
the defect is still there. `test.fixme` at least says why in its name, and neither of them has a
date.

`test.fail()` is what lessons 3, 5 and 7 chose for a known defect that fails **every time**, and
for that it is the right tool: the day the defect is fixed, the test passes and the report turns
red until somebody deletes the annotation. Its weakness, from lesson 3, is that any failure
satisfies it, so a page that stopped loading at all would still count as the expected failure.

For a flaky test it is worse than weak. Here is the quarantined test with `test.fail();` added as
the first line of its body, twenty times:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 | grep -E 'Expected to fail|^  [0-9]+ (failed|flaky|passed)' | sort | uniq -c
     13     Expected to fail, but passed.
      1   13 failed
      1   7 passed (38.6s)
```

**The search defect showed on seven attempts, and those seven passed. On the other thirteen it
did not show, and each was reported as a failure**: *Expected to fail, but passed.* An annotation
that says *this always fails* cannot describe a test that fails sometimes; wrapped in one, the test
is still red, now on the runs where the page behaved. That is the gap a quarantine fills.

## A quarantine needs a way out

The platform you are studying on quarantines its own exam questions, automatically, when the
statistics say its answer key is probably wrong or its prompt ambiguous. Three of its rules carry over to tests
almost word for word. It is decided **by a threshold**, not by somebody's mood on the day, which
for a test means a flaky count over a number of runs. It is **keyed by version**, so fixing the
question is the ordinary way out and nobody has to remember to release anything. And releasing a
question by hand is an override that **needs a reason**.

For a test, the way out is the fix and the move back into `tests/`, and the date in the
annotation is when somebody looks again if neither has happened. A quarantine with no owner and no
date is a deletion done slowly: the test runs, nobody reads it, and the defect it found stays.
