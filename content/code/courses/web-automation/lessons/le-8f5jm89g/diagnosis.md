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
  ✓   1 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   3 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   4 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✘   2 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (6.1s)
  ✓   5 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   6 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   7 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   8 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓   9 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  10 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  11 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  12 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  13 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  14 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  15 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  16 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  17 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  18 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  19 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  ✓  20 quarantine/typing.spec.js:5:1 › typed at 145 ms a key, the list settles on papaya (1.1s)
  1 failed
  19 passed (23.9s)
```

**Nineteen passed and one failed**, and the failure is easy to find: it took 6.1 s against 1.1 s,
because the check retried for its five seconds against a list that was never going to change. One
failure in twenty is exactly the rate that survives a re-run and reaches the gate.

## Change one thing

The two workers ran the twenty attempts two at a time. The same twenty, one at a time:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 --workers 1 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  8 failed
  12 passed (1.3m)
```

**Eight failures this time, against one.** That is worth reading carefully, because the shared
basket in the previous section also changed its verdict with `--workers`, and the cause here is a
different one. Nothing in this test reaches anything another test touches: the search keeps no
state. What changed is the load on the machine, and with it the schedule on which six requests and
six answers were handled; how exactly it moved them, these two runs do not show. A rate that moves with the number of
workers says *timing or sharing*; what says *sharing* is a received value that is another test's
work, like the count of 2 in the basket's failure.

The other things worth changing one at a time are the speed of the network (lesson 3's
`page.route` delay), the browser, the machine, and the order of the tests. Write down each run's
count, not just *still flaky*.

## What the two runs did differently

The same race, run by lesson 3's `race.mjs` at 145 ms a key, until one run ended on one fruit and
one on three. It took two runs:

```
ana@laptop:~/quitanda$ node race.mjs papaya 145
   62 ms  asked    "p"
  211 ms  asked    "pa"
  362 ms  asked    "pap"
  511 ms  asked    "papa"
  661 ms  asked    "papay"
  819 ms  asked    "papaya"
  820 ms  answered "pa"
  820 ms  answered "p"
  821 ms  answered "papa"
  821 ms  answered "pap"
  823 ms    shows  2 found: Papaya, Passion fruit  (aria-busy=true)
  828 ms  answered "papay"
  829 ms  answered "papaya"
  829 ms    shows  3 found: Papaya, Passion fruit, Pineapple  (aria-busy=true)
  829 ms    shows  1 found: Papaya  (aria-busy=true)
  830 ms    shows  1 found: Papaya  (aria-busy=true)
  831 ms    shows  1 found: Papaya  (aria-busy=true)
  831 ms    shows  1 found: Papaya  (aria-busy=false)
```

```
ana@laptop:~/quitanda$ node race.mjs papaya 145
   72 ms  asked    "p"
  220 ms  asked    "pa"
  369 ms  asked    "pap"
  518 ms  asked    "papa"
  669 ms  asked    "papay"
  818 ms  asked    "papaya"
  824 ms  answered "papa"
  825 ms  answered "papay"
  825 ms  answered "papaya"
  826 ms  answered "pap"
  826 ms  answered "pa"
  828 ms    shows  1 found: Papaya  (aria-busy=true)
  829 ms    shows  1 found: Papaya  (aria-busy=true)
  832 ms    shows  1 found: Papaya  (aria-busy=true)
  832 ms  answered "p"
  833 ms    shows  1 found: Papaya  (aria-busy=true)
  833 ms    shows  2 found: Papaya, Passion fruit  (aria-busy=true)
  833 ms    shows  3 found: Papaya, Passion fruit, Pineapple  (aria-busy=false)
```

The questions left about 150 ms apart in both runs, and **all six answers arrived within about
twelve milliseconds** of each other. In the first run the answers to `papay` and `papaya` landed
last and the list ended on Papaya; on the way it showed three fruit for a moment, which no check
saw. In the second the answer to `p` landed last, at 832 ms, and the list stayed on three.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 372\" role=\"img\" aria-label=\"The same test, typed at 145 milliseconds a key, drawn for two runs. The six questions left about 150 milliseconds apart and all six answers arrived within about twelve milliseconds of each other, between 820 and 832 ms. In run A the answers to papay and papaya arrived last, at 828 and 829 ms, and the list ended on one fruit, so the test passed. In run B the answer to p arrived last, at 832 ms, and the list ended on three fruit, so the test failed.\"><text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">run A: the answer to \"papaya\" lands last</text><text x=\"20\" y=\"50\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"p\"</text><path d=\"M150 46 L530 46\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"238\" cy=\"46\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"68\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pa\"</text><path d=\"M150 64 L530 64\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"238\" cy=\"64\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"86\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pap\"</text><path d=\"M150 82 L530 82\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"260\" cy=\"82\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"104\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papa\"</text><path d=\"M150 100 L530 100\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"260\" cy=\"100\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"122\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papay\"</text><path d=\"M150 118 L530 118\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"414\" cy=\"118\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"140\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papaya\"</text><path d=\"M150 136 L530 136\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"436\" cy=\"136\" r=\"5\" fill=\"var(--phosphor)\"></circle><rect x=\"556\" y=\"82\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"631\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the list ends on 1 found</text><text x=\"631\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">passes</text><text x=\"20\" y=\"184\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">run B: the answer to \"p\" lands last</text><text x=\"20\" y=\"210\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"p\"</text><path d=\"M150 206 L530 206\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"502\" cy=\"206\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"20\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pa\"</text><path d=\"M150 224 L530 224\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"370\" cy=\"224\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"246\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"pap\"</text><path d=\"M150 242 L530 242\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"370\" cy=\"242\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"264\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papa\"</text><path d=\"M150 260 L530 260\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"326\" cy=\"260\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"282\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papay\"</text><path d=\"M150 278 L530 278\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"348\" cy=\"278\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"20\" y=\"300\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"papaya\"</text><path d=\"M150 296 L530 296\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"348\" cy=\"296\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"556\" y=\"242\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"631\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the list ends on 3 found</text><text x=\"631\" y=\"274\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">fails</text><path d=\"M150 324 L530 324\" stroke=\"var(--wire)\"></path><path d=\"M150 324 L150 329\" stroke=\"var(--wire)\"></path><text x=\"150\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">816</text><path d=\"M238 324 L238 329\" stroke=\"var(--wire)\"></path><text x=\"238\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">820</text><path d=\"M326 324 L326 329\" stroke=\"var(--wire)\"></path><text x=\"326\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">824</text><path d=\"M414 324 L414 329\" stroke=\"var(--wire)\"></path><text x=\"414\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">828</text><path d=\"M502 324 L502 329\" stroke=\"var(--wire)\"></path><text x=\"502\" y=\"342\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">832</text><text x=\"150\" y=\"362\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milliseconds on race.mjs’s clock</text></svg>", "caption": "Two runs of the same test, from race.mjs at 145 ms a key. Six answers land within twelve milliseconds, and whichever lands last decides the verdict."}
```

The figure is the whole diagnosis: the test does not vary, the page does not vary, and the order
of six answers that arrive at nearly the same moment does. A test that fails one time in twenty
is usually a race like this one, between two events that are close enough to swap.

## Keep the evidence of the failing attempt

A count tells you how often; it does not tell you what the page looked like when it failed.
Playwright can record a **trace**, a file holding every action, every network request and a
snapshot of the page at each step, and `--trace retain-on-failure` keeps it only for the attempts
that failed. With a test that fails one time in twenty, that is how you get to look at the one.
Lesson 16 is about reading a trace and the screenshots beside it.
