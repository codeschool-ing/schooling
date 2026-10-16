---
title: Reproduce it, then change one thing
version: 1
---

**Diagnosing a flaky test starts with making it fail on purpose, often enough to count.** The
wrong first move is to read the one red run very hard and guess. One run is a sample of one; a
cause you guessed from it is a story. The right move is to run the test many times, measure the
rate, and then change one thing at a time and watch whether the rate moves.

## A test that is right and sometimes red

Lesson 3 worked out when its search defect shows: a key every *k* milliseconds puts the answer to
the *n*-th question at *k*×(*n*−1) + 900 − 150×*n* after the first key. Below 150 ms a key the
answers come back in reverse, and the list ends wrong; above it they come back in order. At 150
ms exactly, every answer is due at the same moment, about 750 ms after the first key, and which
one lands last is down to whatever else the machine is doing. A person typing quickly is not far
from there.

The test below types `papaya` at 145 ms a key, which on this machine is where the verdict splits.
It is a good test: it waits for the page to say it is finished and then checks the one thing a
customer would check. It is also one you should not add to `tests/` while you find out what it
does. Everything in `tests/` is the gate from the first section, and a test you already suspect
would make every run of the gate a coin toss. So it goes into a folder of its own, with a
configuration that reads only that folder and takes everything else from the project's. Save it
as `quarantine.config.js`:

```javascript
// The quarantine: tests known to be flaky, run apart from the gate.
// Everything else comes from the project's own configuration.
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

export default defineConfig({
  ...base,
  testDir: 'quarantine',
});
```

And the test. Save it as `quarantine/typing.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Lesson 3's search, typed just under the speed at which its defect stops
// showing. Whether it shows is decided by a few milliseconds.
test('typed at 145 ms a key, the list settles on papaya', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').pressSequentially('papaya', { delay: 145 });
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});
```

## Run it many times

`--repeat-each 20` runs every test twenty times in one go. The `grep` keeps the line Playwright
prints for each attempt and the summary:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 | grep -E '✓|✘|^  [0-9]+ (failed|flaky|passed)'
  ✘   1 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✘   2 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✓   3 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   4 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.2s)
  ✓   5 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   7 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   8 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✘   6 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✓   9 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  10 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  11 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  12 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  14 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  15 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✘  13 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✓  17 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  18 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✘  16 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✓  19 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  20 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  5 failed
  15 passed (34.1s)
```

**Fifteen passed and five failed**, and the failures are easy to find: each took 6.1 s against
about 1.1 s, because the check retried for its five seconds against a list that was never going to
change. At one failure in four, a single re-run turns the gate green three times out of four.

## Change one thing

The two workers ran the twenty attempts two at a time. The same twenty, one at a time:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 --workers 1 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  6 failed
  14 passed (1.2m)
```

**Six failures against five: the number of workers made almost no difference.** Compare the pair
in the causes section, which went from no failures with one worker to three with two. That
contrast is the diagnosis. Nothing in this test reaches anything another test touches, because the
search keeps no state, so running two attempts at once changes little. A rate that jumps with
`--workers` says *sharing*, and the received value names what was shared: the count of 2 was the
other test's mango. A rate that stays put says the cause lives inside the one test and its page.

The other things worth changing one at a time are the speed of the network (lesson 3's
`page.route` delay), the browser, the machine, and the order of the tests. Write down each run's
count, not just *still flaky*.

## What the two runs did differently

The same race, run by lesson 3's `race.mjs` at 145 ms a key, until one run ended on one fruit and
one on more. It took nine runs:

```
ana@laptop:~/quitanda$ node race.mjs papaya 145
   62 ms  asked    "p"
  212 ms  asked    "pa"
  364 ms  asked    "pap"
  509 ms  asked    "papa"
  658 ms  asked    "papay"
  808 ms  asked    "papaya"
  812 ms  answered "papay"
  813 ms  answered "papa"
  816 ms  answered "papaya"
  816 ms    shows  1 found: Papaya  (aria-busy=true)
  819 ms    shows  1 found: Papaya  (aria-busy=true)
  819 ms    shows  1 found: Papaya  (aria-busy=true)
  820 ms  answered "pa"
  820 ms  answered "p"
  820 ms  answered "pap"
  823 ms    shows  2 found: Papaya, Passion fruit  (aria-busy=true)
  823 ms    shows  3 found: Papaya, Passion fruit, Pineapple  (aria-busy=true)
  823 ms    shows  1 found: Papaya  (aria-busy=false)
```

```
ana@laptop:~/quitanda$ node race.mjs papaya 145
   57 ms  asked    "p"
  206 ms  asked    "pa"
  358 ms  asked    "pap"
  506 ms  asked    "papa"
  654 ms  asked    "papay"
  803 ms  asked    "papaya"
  808 ms  answered "papaya"
  809 ms  answered "papay"
  810 ms  answered "pap"
  810 ms  answered "papa"
  811 ms    shows  1 found: Papaya  (aria-busy=true)
  814 ms  answered "p"
  814 ms    shows  1 found: Papaya  (aria-busy=true)
  815 ms  answered "pa"
  816 ms    shows  1 found: Papaya  (aria-busy=true)
  817 ms    shows  1 found: Papaya  (aria-busy=true)
  817 ms    shows  3 found: Papaya, Passion fruit, Pineapple  (aria-busy=true)
  817 ms    shows  2 found: Papaya, Passion fruit  (aria-busy=false)
```

The questions left about 150 ms apart in both runs, and **all six answers arrived within eight
milliseconds** of each other. In the first run the answers to `pa`, `p` and `pap` all arrived at
820 ms and were drawn in that order: the list went to two fruit, then three, and ended on the
answer to `pap`, which is Papaya alone. In the second the answer to `pa` landed last, at 815 ms,
and the list stayed on two fruit, Papaya and Passion fruit. Neither run is lesson 3's picture of
answers coming back in reverse. They arrive in a heap, and whichever is drawn last decides.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 372\" role=\"img\" aria-label=\"The same test, typed at 145 milliseconds a key, drawn for two runs. The six questions left about 150 milliseconds apart and all six answers arrived within eight milliseconds of each other. In run A the answers to pa, p and pap all arrived at 820 ms and the answer to pap was drawn last, so the list ended on one fruit and the test passed. In run B the answer to pa arrived last, at 815 ms, and the list ended on two fruit, so the test failed.\"><text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">run A: \"pa\", \"p\" and \"pap\" land together, \"pap\" is drawn last</text><text x=\"20\" y=\"50\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"p\"</text><path d=\"M150 46 L530 46\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"502\" cy=\"46\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"68\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pa\"</text><path d=\"M150 64 L530 64\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"502\" cy=\"64\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"86\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pap\"</text><path d=\"M150 82 L530 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"502\" cy=\"82\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"20\" y=\"104\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papa\"</text><path d=\"M150 100 L530 100\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"348\" cy=\"100\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"122\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papay\"</text><path d=\"M150 118 L530 118\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"326\" cy=\"118\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"140\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papaya\"</text><path d=\"M150 136 L530 136\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"414\" cy=\"136\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"556\" y=\"82\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"631\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the list ends on 1 found</text><text x=\"631\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">passes</text><text x=\"20\" y=\"184\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">run B: the answer to \"pa\" lands last</text><text x=\"20\" y=\"210\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"p\"</text><path d=\"M150 206 L530 206\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"370\" cy=\"206\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pa\"</text><path d=\"M150 224 L530 224\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"392\" cy=\"224\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"20\" y=\"246\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pap\"</text><path d=\"M150 242 L530 242\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"282\" cy=\"242\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"264\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papa\"</text><path d=\"M150 260 L530 260\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"282\" cy=\"260\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"282\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papay\"</text><path d=\"M150 278 L530 278\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"260\" cy=\"278\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"300\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papaya\"</text><path d=\"M150 296 L530 296\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"238\" cy=\"296\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"556\" y=\"242\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"631\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the list ends on 2 found</text><text x=\"631\" y=\"274\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">fails</text><path d=\"M150 324 L530 324\" stroke=\"var(--wire)\"></path><path d=\"M150 324 L150 329\" stroke=\"var(--wire)\"></path><text x=\"150\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">804</text><path d=\"M238 324 L238 329\" stroke=\"var(--wire)\"></path><text x=\"238\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">808</text><path d=\"M326 324 L326 329\" stroke=\"var(--wire)\"></path><text x=\"326\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">812</text><path d=\"M414 324 L414 329\" stroke=\"var(--wire)\"></path><text x=\"414\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">816</text><path d=\"M502 324 L502 329\" stroke=\"var(--wire)\"></path><text x=\"502\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">820</text><text x=\"150\" y=\"362\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milliseconds on race.mjs’s clock</text></svg>", "caption": "Two runs of the same test, from race.mjs at 145 ms a key. Six answers land within eight milliseconds, and whichever is drawn last decides the verdict."}
```

The figure is the whole diagnosis: the test does not vary, the page does not vary, and the order
of six answers that arrive at nearly the same moment does. A flaky timing failure is usually a race
like this one, between events close enough to swap.

## Keep the evidence of the failing attempt

A count tells you how often; it does not tell you what the page looked like when it failed.
Playwright can record a **trace**, a file holding every action, every network request and a
snapshot of the page at each step, and `--trace retain-on-failure` keeps it only for the attempts
that failed. With a test that fails one time in four, that is how you look at a failing attempt without re-running
until you catch one.
Lesson 16 is about reading a trace and the screenshots beside it.
