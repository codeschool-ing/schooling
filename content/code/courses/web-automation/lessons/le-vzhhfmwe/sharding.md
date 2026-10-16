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
%%CAP shard-lists%%
```

@@SHARDLIST@@

## Shards and phases do not mix

Here the three slices run one after the other on the same laptop, standing in for three machines.
Each also writes a **blob report**, a zip file with everything the reporter saw, so that the three
can become one report afterwards; on a real CI each job uploads its zip and a last job collects
them. `--reporter=list,blob` keeps the list on screen and writes the zip into `blob-report/`, which
the blob reporter empties when it starts, so each zip is moved out after its run:

```
%%CAP shards%%
```

```
%%CAP merge%%
```

@@SHARDDUP@@

## One command per phase

The way out is to stop Playwright from adding the dependency back: on each machine, run the two
projects as two commands, each with the same `--shard`. `--project` picks one project, and
`--no-deps` tells Playwright not to run its dependencies, which is safe here because
`one-at-a-time` never needed anything `parallel` did; the dependency only existed to keep the two
apart in time, and two commands in a row do that by themselves. The zips are renamed as they are
moved, because both commands of a shard write a file with the same name:

```
%%CAP shards-split%%
```

```
%%CAP merge-split%%
```

@@SPLITREAD@@

**A shard is as long as the tests that landed in it**, and the whole run is as long as the slowest
machine, because the merged report waits for all three. Two things decide the gap. A file is dealt
out whole, so a file with one slow test pulls its whole shard along; and the tests that wait five
seconds on purpose, the `test.fail()` ones from lessons 3 and 4 among them, land wherever their
file does. When one shard is always the slowest, the fix is to split the file that makes it slow,
or to mark it fully parallel so its tests can be dealt out separately.

Each shard ran its own shop, which is the one place sharding helps with this lesson's antagonist:
two machines never share a basket. Inside each shard the workers still share one shop, which is
why the one-at-a-time project is still there.
