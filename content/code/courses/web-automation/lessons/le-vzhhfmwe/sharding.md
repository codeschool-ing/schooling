---
title: Shards: one suite across several machines
version: 1
---

Workers share one machine, so they share its processors and its memory, and the last section of
this lesson measures where that runs out. **A shard is the other way to split a suite: a slice of
the tests, run on a machine of its own.** `--shard=1/3` means "the first third"; three CI jobs run
`--shard=1/3`, `--shard=2/3` and `--shard=3/3`, each with its own checkout, its own shop started by
`webServer`, and its own workers. Lesson 5 of `testing-cicd` covers how a CI service starts three
jobs at once; what follows is what Playwright does inside each one.

## How the slices are cut

The belief to drop first is that Playwright balances shards by time. It does not know how long a
test takes before running it. The rule is in `node_modules/playwright/lib/runner/testGroups.js`,
in a function called `filterForShard`, and it counts **tests**. The suite is first cut into
groups, the same groups the workers are handed: a whole file, unless the file is fully parallel,
in which case each test is a group of its own. Then the groups are dealt out in order, and a group
goes to the shard where its first test falls when the total is divided by three. **A file is never
split between shards**, because a group is never split.

Asking each shard for its list shows the cut without running anything:

```
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --list --shard=1/3 | tail -1
Total: 42 tests in 17 files
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --list --shard=2/3 | tail -1
Total: 40 tests in 16 files
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --list --shard=3/3 | tail -1
Total: 39 tests in 18 files
```

Sixty-one tests make about twenty a shard, and these shards hold 42, 40 and 39. The next section
shows where the extra came from.

## Shards and phases do not mix

Here the three slices run one after the other on the same laptop, standing in for three machines.
Each also writes a **blob report**, a zip file with everything the reporter saw, so that the three
can become one report afterwards; on a real CI each job uploads its zip and a last job collects
them. `--reporter=list,blob` keeps the list on screen and writes the zip into `blob-report/`. The
blob reporter empties that folder when it starts, so each zip is moved out after its run:

```
ana@laptop:~/quitanda$ mkdir -p all-blob-reports
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --shard=1/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 42 tests using 2 workers, shard 1 of 3
  42 passed (19.0s)
ana@laptop:~/quitanda$ mv blob-report/report-1.zip all-blob-reports/
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --shard=2/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 40 tests using 2 workers, shard 2 of 3
  40 passed (11.7s)
ana@laptop:~/quitanda$ mv blob-report/report-2.zip all-blob-reports/
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --shard=3/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 39 tests using 2 workers, shard 3 of 3
  39 passed (21.3s)
ana@laptop:~/quitanda$ mv blob-report/report-3.zip all-blob-reports/
```

```
ana@laptop:~/quitanda$ npx playwright merge-reports --reporter list all-blob-reports | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 121 tests using 6 workers
  121 passed (21.3s)
```

**The merged report counts 121 tests, and the suite has 61.** Every shard ran the thirty tests of
`parallel` in full and only its own slice of `one-at-a-time`: 30 and 12, 30 and 10, 30 and 9. That is
what `dependencies` means, and `node_modules/playwright/lib/runner/loadUtils.js` does it on purpose:
after the shard filter has picked a slice, every project that a picked project depends on is added
back whole. For a setup project that signs in, running it on every machine is exactly right. For
`parallel`, which is half the suite, it means every machine runs that half again, and the slowest
shard took 21.3 seconds, much of it repeated work.

## One command per phase

The way out is to stop Playwright from adding the dependency back: on each machine, run the two
projects as two commands, each with the same `--shard`. `--project` picks one project, and
`--no-deps` tells Playwright not to run its dependencies, which is safe here because
`one-at-a-time` never needed anything `parallel` did; the dependency only existed to keep the two
apart in time, and two commands in a row do that by themselves. The zips are renamed as they are
moved, because both commands of a shard write a file with the same name:

```
ana@laptop:~/quitanda$ rm -rf all-blob-reports && mkdir all-blob-reports
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project parallel --shard=1/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 10 tests using 2 workers, shard 1 of 3
  10 passed (2.2s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/parallel-1.zip
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project one-at-a-time --no-deps --shard=1/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 12 tests using 1 worker, shard 1 of 3
  12 passed (10.7s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/one-at-a-time-1.zip
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project parallel --shard=2/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 11 tests using 2 workers, shard 2 of 3
  11 passed (8.1s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/parallel-2.zip
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project one-at-a-time --no-deps --shard=2/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 10 tests using 1 worker, shard 2 of 3
  10 passed (3.7s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/one-at-a-time-2.zip
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project parallel --shard=3/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 9 tests using 2 workers, shard 3 of 3
  9 passed (3.5s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/parallel-3.zip
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project one-at-a-time --no-deps --shard=3/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 9 tests using 1 worker, shard 3 of 3
  9 passed (13.0s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/one-at-a-time-3.zip
```

```
ana@laptop:~/quitanda$ npx playwright merge-reports --reporter list all-blob-reports | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 9 workers
  61 passed (13.0s)
```

Sixty-one tests, each run once: 10 and 12 on the first machine, 11 and 10 on the second, 9 and 9
on the third. The time `merge-reports` prints is the longest single run it was given, not a total.
On the machines themselves the two commands took 12.9, 11.8 and 16.5 seconds, plus the start of a
second command, against 19.0, 11.7 and 21.3 before. And eleven tests took 8.1 seconds where ten took
2.2: a count of tests says nothing about time.

**A shard is as long as the tests that landed in it**, and the whole run is as long as the slowest
machine, because the merged report waits for all three. Two things decide the gap. A file is dealt
out whole, so a file with one slow test pulls its whole shard along; and the tests that wait five
seconds on purpose, the `test.fail()` ones from lessons 3 and 4 among them, land wherever their
file does. When one shard is always the slowest, the fix is to split the file that makes it slow,
or to mark it fully parallel so its tests can be dealt out separately.

Each shard ran its own shop, which is the one place sharding helps with this lesson's antagonist:
two machines never share a basket. Inside each shard the workers still share one shop, which is
why the one-at-a-time project is still there.
