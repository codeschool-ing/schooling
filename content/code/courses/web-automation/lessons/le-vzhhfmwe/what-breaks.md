---
title: What breaks when tests run together
version: 1
---

**A test that passes alone and fails beside other tests is reading something another test is
writing.** In this project that something is the shop: one basket, one offer and one list of
customers, held in the server's memory and shared by every browser that opens it. Each worker has
its own browser, and lesson 10 showed that two browser contexts share no cookies and no storage.
They still share the server, and every worker talks to the same one.

The usual first reading of a red parallel run is that the tests are flaky, and that a retry will
see them through. Lesson 14 is about flaky tests, and the difference matters here: a flaky test
fails because of timing inside itself. These fail because of what the **other** tests did, and
which tests fail changes from run to run while the cause stays put.

## Which tests were running at the same moment

The list reporter prints results in the order they came in, which says nothing about what ran
beside what. Playwright's JSON reporter records, for every test, the worker that ran it, when it
started and how long it took. The program below reads that report and, for every test that did
not end the way it was expected to, prints the tests other workers were running at the same time.
Save it as `overlap.mjs`:

```javascript
// Reads a JSON report from Playwright and, for every test that ended in a
// way it was not expected to, names the tests that other workers were
// running in that test's first two seconds.
import { readFileSync } from 'node:fs';

// A test here resets the shop as it starts and checks the result within two
// seconds (the /ssr page of lesson 6 takes one and a half to come alive), so
// what other workers did in those two seconds is the suspect.
const WINDOW = 2000;

const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const runs = [];
const visit = (suite) => {
  for (const spec of suite.specs ?? []) {
    for (const test of spec.tests) {
      for (const result of test.results) {
        const start = Date.parse(result.startTime);
        runs.push({
          name: `${spec.file}:${spec.line} ${spec.title}`,
          worker: result.workerIndex,
          start,
          end: start + result.duration,
          status: result.status,
          expected: test.expectedStatus,
          error: result.error?.message ?? '',
        });
      }
    }
  }
  for (const child of suite.suites ?? []) visit(child);
};
report.suites.forEach(visit);

const zero = Math.min(...runs.map((run) => run.start));
const at = (ms) => `${((ms - zero) / 1000).toFixed(1)}s`;
const plain = (text) => text.replace(/\u001b\[[0-9;]*m/g, '');

for (const run of runs) {
  if (run.status === run.expected || run.status === 'skipped') continue;
  console.log(`${run.name}  worker ${run.worker}  ${at(run.start)} to ${at(run.end)}`);
  const lines = plain(run.error).split('\n');
  console.log(`  ${lines[0]}`);
  for (const line of lines) {
    if (/^(Expected|Received)/.test(line)) console.log(`  ${line}`);
  }
  for (const other of runs) {
    if (other.worker !== run.worker && other.worker >= 0
        && other.start < run.start + WINDOW && other.end > run.start) {
      console.log(`    beside it: ${other.name}  worker ${other.worker}  ${at(other.start)} to ${at(other.end)}`);
    }
  }
}
```

A test the report counts as fine has a `status` equal to its `expectedStatus`: `passed` for most,
`failed` for the ones `test.fail()` marks. A `skipped` test did not run, so it collided with
nothing. Everything else is printed with the `Expected` and `Received` lines of its error, and
the tests whose run overlapped it in time on other workers.

Run the suite with four workers, writing the JSON report to a file, and read it:

```
%%CAP red4%%
```

```
%%CAP overlap1%%
```

@@READ1@@

%%CAP fig-collision%%

The same command again, a minute later:

```
%%CAP red4b%%
```

```
%%CAP overlap2%%
```

@@READ2@@ **The cause did not move; the victims did.** Which test loses depends on which tests
happen to share a second, and that is decided by how long each one took on that run.

## Why the reset at the start does not save them

Every one of those files begins with `request.post('/api/reset')` in a `beforeEach`. Lesson 15
showed why that is not enough: a reset makes the shop empty **at one moment**, and the test then
spends the next few hundred milliseconds assuming it still is. Under four workers any other test
can add a banana, or reset the basket the first one has just filled, inside that window.
`app/store.js` makes the second case wider than it looks, because `reset()` puts back the basket,
the offer and the customers together: a test about the offer empties somebody's basket, and a
test about the basket deletes somebody's new customer.

There are three answers, in order of how much they fix:

| | what it does | what it costs |
|---|---|---|
| `--workers 1` | nothing runs beside anything | the whole suite at the slowest speed |
| the tests that touch the shop take turns | only they lose their parallelism | a list to keep, and the next section is that list |
| a basket per visitor | each test gets its own data | a change to the application, lesson 15's request to the developers |

**The last one is the real fix.** Lesson 15 made the customers unique and asked for a basket per
visitor; until the shop has one, the tests that use the basket cannot be made to stay out of each
other's way from the outside. The middle answer is the one a tester can apply today.
