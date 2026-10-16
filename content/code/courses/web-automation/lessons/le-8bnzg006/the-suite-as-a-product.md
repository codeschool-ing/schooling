---
title: The suite as a product
version: 1
---

**A test suite is usually treated as a by-product of the features**, a pile that grows by one
file each time something ships and that nobody in particular looks after. It has users, though:
everybody who waits for it before they merge, and everybody who decides from its colour whether a
release goes out. Anything with users is a product, and a product without an owner, a budget and a
number that says how it is doing gets worse slowly, in a way nobody notices on any single day.

## An owner for every file

When a test goes red, **somebody has to be the person who looks first**, or everybody assumes
somebody else will. The smallest arrangement that works is a name per test file, written where the
tools see it: lesson 14's quarantine wrote an owner into the annotation, and a repository host's
code-owners file can do the same for a folder. Owning a test does not mean writing every fix. It
means answering, within a day, whether a red run is the product, the test or the machine.

## A budget for run time

The people waiting are the cost, so **the run time has a limit somebody chose**, and a test that
pushes the suite over it has to buy its place by speeding up another, moving down a layer, or
running at night instead. You cannot hold a limit you do not measure. Playwright's JSON reporter
writes every test's duration and outcome, and a short script turns it into the few numbers worth
reading. Save it as `slowest.mjs`:

```javascript
import { readFileSync } from 'node:fs';

// Reads the report `--reporter=json` writes, and says where the time went.
const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const tests = [];

function walk(suite) {
  for (const spec of suite.specs ?? []) {
    for (const test of spec.tests) {
      const ms = test.results.reduce((sum, result) => sum + result.duration, 0);
      tests.push({ file: spec.file, title: `${spec.file}:${spec.line} › ${spec.title}`, ms, test });
    }
  }
  for (const child of suite.suites ?? []) walk(child);
}
report.suites.forEach(walk);

const seconds = (ms) => (ms / 1000).toFixed(1).padStart(5) + ' s';
const { expected, unexpected, flaky, skipped, duration } = report.stats;
console.log(`${tests.length} tests, ${seconds(duration).trim()} from start to end`);
console.log(`as declared ${expected}, not as declared ${unexpected}, flaky ${flaky}, skipped ${skipped}`);

const byFile = new Map();
for (const t of tests) byFile.set(t.file, (byFile.get(t.file) ?? 0) + t.ms);
console.log('the five slowest files:');
for (const [file, ms] of [...byFile].sort((a, b) => b[1] - a[1]).slice(0, 5)) {
  console.log(`  ${seconds(ms)}  ${file}`);
}

// A test declared with test.fail() passes on ANY failure, so print the one
// it had: it should still be the defect its comment names.
const declared = tests.filter((t) => t.test.expectedStatus === 'failed');
const spent = declared.reduce((sum, t) => sum + t.ms, 0);
console.log(`declared to fail: ${declared.length} tests, ${seconds(spent).trim()}`);
for (const t of declared) {
  const error = t.test.results.at(-1)?.error?.message ?? 'no error recorded';
  const first = error.replace(/\x1b\[[0-9;]*m/g, '').split('\n')[0];
  console.log(`  ${t.title}\n      ${first}`);
}

for (const t of tests.filter((t) => t.test.status === 'unexpected' || t.test.status === 'flaky')) {
  console.log(`${t.test.status}: ${t.title}`);
}
```

The run that measures the suite uses **one worker**, so that the tests that share the shop's one
basket cannot change each other's results; lesson 19 is about running them apart. Run it from the
project folder:

```
ana@laptop:~/quitanda$ npx playwright test --workers 1 --reporter=json > report.json; echo "exit code $?"
exit code 0
ana@laptop:~/quitanda$ node slowest.mjs report.json
64 tests, 38.1 s from start to end
as declared 64, not as declared 0, flaky 0, skipped 0
the five slowest files:
    6.1 s  search.spec.js
    5.5 s  cache.spec.js
    3.1 s  waiting.spec.js
    3.1 s  toast.spec.js
    2.9 s  conditions.spec.js
declared to fail: 7 tests, 12.4 s
  cache.spec.js:13 › a returning customer sees the new offer
      Error: expect(locator).toContainText(expected) failed
  cache.spec.js:22 › the offer is checked with the server before it is reused
      Error: expect(received).toMatch(expected)
  conditions.spec.js:20 › waitForFunction: typed, the search settles on papaya
      Error: expect(received).toEqual(expected) // deep equality
  responsive.spec.js:45 › nothing scrolls sideways at 360 px
      Error: the page is wider than the window
  responsive.spec.js:45 › nothing scrolls sideways at 390 px
      Error: the page is wider than the window
  search.spec.js:13 › typed key by key, the list settles on papaya
      Error: expect(locator).toHaveText(expected) failed
  spa.spec.js:30 › the basket opens from its own address
      Error: expect(received).toBe(expected) // Object.is equality
```

Every one of the 64 tests did what it was declared to do, in 38.1 seconds, and four facts in
that output are worth a sentence each.

- **The slowest file is `search.spec.js`**, with 6.1 seconds, and most of that is one test:
  the declared failure that waits its whole five seconds for a list that never settles.
- **The seven declared failures cost 12.4 seconds**, about a third of the run. Each waits for its
  expectation's timeout, because a check that is going to fail cannot know it early. Documenting a
  defect has a price in run time, and it is paid on every run until the defect is fixed.
- **Each declared failure prints its own error**, and each still names the defect its comment
  names. That is the monthly check the previous section asked for.
- **Nothing was flaky in this run**, which is one run. One run cannot measure a rate.

## The flaky rate is a number

**The number to track is the share of runs that go red with nothing changed.** It is the one a
person feels: a developer meets a red run, not a red test, and a suite of 64 tests where each one
fails once in a hundred runs is red in about half of them. Run the suite five times as it is, with
Playwright's default number of workers:

```
ana@laptop:~/quitanda$ for i in 1 2 3 4 5; do npx playwright test | grep -E '^  [0-9]+ (failed|flaky|passed)|^    tests/'; done
  3 failed
    tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ────────────────────────────────────────
    tests/conditions.spec.js:30:1 › expect.poll: the server has the banana from /ssr ───────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  60 passed (28.2s)
  4 failed
    tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ────────────────────────────────────────
    tests/conditions.spec.js:40:1 › toPass: the count and the total change together ────────────────
    tests/page-object.spec.js:8:1 › two fruit make two items ───────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  59 passed (31.8s)
  3 failed
    tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ────────────────────────────────────────
    tests/page-object.spec.js:8:1 › two fruit make two items ───────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  60 passed (28.4s)
  1 failed
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  63 passed (22.7s)
  4 failed
    tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ────────────────────────────────────────
    tests/conditions.spec.js:40:1 › toPass: the count and the total change together ────────────────
    tests/page-object.spec.js:8:1 › two fruit make two items ───────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  59 passed (31.9s)
```

**All five runs were red**, with between one and four failures each. The failing tests change from run to run, and every one of them passed in the run with one
worker above. One more run, cut to the errors, shows why:

```
ana@laptop:~/quitanda$ npx playwright test | grep -E 'using [0-9]+ workers|^  [0-9]+\) |Expected:|Received:'
Running 64 tests using 2 workers
  1) tests/basket-data.spec.js:14:1 › a banana costs R$ 5,90 ───────────────────────────────────────
    Expected: "1"
    Received: "2"
  2) tests/page-object.spec.js:8:1 › two fruit make two items ──────────────────────────────────────
    Expected: "1"
    Received: "2"
  3) tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ─────────────
    Expected: "1"
    Received: "2"
```

**Two workers, and the same broken expectation three times: a count that should be 1 and read
2.** Each of those tests puts something in the basket and then counts it, and with two workers
another test is putting things into the same basket at the same moment. It is the shop's one
basket, shared by everybody, which lessons 15 and 19 are about. In each, the cause sits outside the
test that failed: in the other worker, and in a basket neither test owns.

**This is the course's own suite failing, and it is not hidden.** No flag here makes those runs
green: a retry would turn a shared basket into a test reported as *flaky* and leave the cause in
place, which is lesson 14's warning. The honest arrangement for this project, until its tests own
their data the way lesson 15 makes them, is the budget decision the numbers already point at: one
worker, in about forty seconds, green, and a flaky rate measured again each time a file is added.

## What a suite reports about itself

Put together, the numbers a suite should be able to say about itself fit on one line, and every
one of them came from a command in this section:

| tests | run time, one worker | declared failures | their share of the time | red runs in five, default workers |
|---|---|---|---|---|
| 64 | 38.1 s | 7 | 12.4 s | 5 |

Kept somewhere a team looks, week after week, they say whether the suite is getting better or
worse before anybody has to complain about it.
