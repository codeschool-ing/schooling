---
title: Two hundred partitions
version: 1
---

**`spark.sql.shuffle.partitions` sets how many partitions every shuffle produces, and its default,
200, fits almost no job exactly.** It is a single number for every shuffle in every query of the
application, decided before any data is seen.

Before adaptive execution, that number was a tuning job. Too few, and each reduce task is too big
for its memory and spills, or fails; too many, and the job is thousands of tasks reading nothing,
each paying the fixed cost per task, and a write produces thousands of small files. The usual
advice was to size it to the largest shuffle in the job, which made it wrong for every other one.

The grouping by visitor of section 02, with adaptive execution and without:

| | reduce tasks | shuffle read |
|---|---|---|
| adaptive execution on | 3 | 34.6 MiB |
| adaptive execution off | 200 | 34.6 MiB |

**The same data, read by 3 tasks of about 12 MiB each or by 200 tasks of 0.2 MiB each.** With
adaptive execution on, Spark looks at the shuffle's real size once the map side is done and merges
partitions until each is about `spark.sql.adaptive.advisoryPartitionSizeInBytes`, 64 MB by default,
while, by default, keeping at least one partition per core. The second line comes from the last
grouping in `jobs_stages.py`, which switches adaptive execution off on purpose.

So the setting has become a ceiling rather than a guess: **set it high enough for the largest shuffle
you expect, and let adaptive execution merge down.** What adaptive execution cannot do is split a
partition that is too large because one key is too large. That is lesson 8.
