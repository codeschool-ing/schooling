---
title: Trunk based: small changes, merged the same day
version: 1
---

*Trunk* is an old name for the main branch. **Trunk-based development means everybody integrates into
`main` at least once a day**, either by committing to it directly or through a branch that lives a few
hours and a pull request reviewed the same day.

It takes the lesson of the last section to its conclusion. If long branches cause big merges, keep
every branch short enough that the merge is always small. Conflicts still happen, but they are the
size of an afternoon's work, and they happen while the work is fresh in everybody's head.

## Merging work that is not finished

The obvious objection: a feature takes two weeks, so how can it be merged every day? The answer is
that **merged is not the same as switched on.** The unfinished work goes into `main` behind a *feature
flag*, a setting the program reads to decide whether to show the new thing:

```conf
# features.conf, read by the app when it starts
sunday_hours = off
pickup_times = on
```

`sunday_hours` is in `main` and in production, switched off. Nobody sees it. It is finished in small
pieces, each one merged and reviewed on its own, and on the day it is done, somebody changes `off` to
`on`, without any merge at all. If something goes wrong, `on` goes back to `off`, which is faster than
any revert.

## What it asks of a team

Trunk-based development does not work everywhere, and it is worth knowing why before choosing it:

- **It needs checks that catch mistakes quickly.** When `main` changes twenty times a day, a broken
  test has to be found in minutes, by a machine, not by a person next week. Lesson 17 is about the
  checks and what *done* means around them.
- **It needs small changes to be possible**, which is a skill of splitting work that takes practice.
- **It needs flags to be removed** once a feature is fully on, or the code fills with switches nobody
  remembers.

What it gives back is the thing most teams want and few get: a `main` that is always close to what is
running, and no merge that anybody dreads.
