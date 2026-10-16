---
title: How many partitions, and who decides
version: 1
---

**A partition is a slice of a dataset that one task handles.** How many there are decides how much
parallelism a stage has, how large each task is, and how many files a write produces. Spark decides
the number in three different places, by three different rules.

**When reading files**, Spark packs them into partitions of about 128 MB,
`spark.sql.files.maxPartitionBytes`, splitting large files and grouping small ones. Each file also
counts as 4 MB more than its size, `spark.sql.files.openCostInBytes`, because opening a file costs
something whatever it holds. The silver clicks are 365 files of about 1.1 MB each:

| | |
|---|---|
| each file, as Spark counts it | 1.1 MB + 4 MB = 5.1 MB |
| 365 files | about 1,850 MB |
| in partitions of 128 MB | about 15 |

**15 partitions**, the number `jobs_stages.py` printed. Lesson 5's `textFile` on the gzipped CSV made
365, one per file, because a gzip file cannot be split and Spark does not group whole files for an
RDD read.

**After a shuffle**, the number is `spark.sql.shuffle.partitions`, 200 by default, whatever the data.
That is the 200 of lesson 6, which adaptive execution then coalesces. Section 07 shows the run
without it.

**When you ask**, with `repartition(n)`, which shuffles into exactly `n` partitions, or
`coalesce(n)`, which merges existing ones without a shuffle. Lesson 8 uses both.

The rule of thumb is **two to four times as many partitions as cores**, each between about 100 MB and
1 GB. Fewer and some cores sit idle in the last wave, as lesson 2 measured; many more and the fixed
cost per task starts to show, along with the small files when the result is written.
