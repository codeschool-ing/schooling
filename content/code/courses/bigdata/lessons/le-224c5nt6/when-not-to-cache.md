---
title: When not to cache
version: 1
---

**A cache is a decision to spend memory, and most of the time the memory is better spent on the
work.** A few patterns come up again and again in programs that cache too much.

- **Caching everything, just in case.** Each cache takes storage memory away from execution memory,
  and lesson 7 showed what a sort does with less of that: it spills. A program that caches every
  intermediate DataFrame can run slower than one that caches none.
- **Caching what is read once.** The cache's first use does more work than not caching, section
  02's 20.0 task-seconds against 15.2, and with no second use there is nothing to win it back.
- **Caching right after the read.** Parquet files already let Spark skip the columns and the days a
  query does not need, lesson 6. A cache of the raw table saves only the read that Parquet made
  cheap, and holds every column and every day in memory to do it.
- **Caching instead of fixing the plan.** A job that runs a slow join three times because the
  program builds the same DataFrame three ways is better fixed by building it once.
- **Forgetting to unpersist in a loop.** Each iteration's cache stays until it is evicted, and evicted
  partitions are chosen by recency, not by whether the program still needs them.

**When in doubt, measure, as this lesson did**: the time of the actions with and without the cache,
and the size the storage page reports. A cache that does not win back its first use within the program
is one to remove.
