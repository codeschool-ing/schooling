---
title: Small files, and the compaction that undoes them
version: 1
---

**A table written often is a table of small files**, whatever its partitioning. The `hourly` layout
of the previous section is what a job that loads every hour leaves behind: the same `dt`
partitions as `by_day`, and seventeen files in each instead of one. Nothing about it is wrong when it
is written, and every question pays for it afterwards.

## What 527 files cost

The two questions of the previous section, asked of `hourly`:

```
ana@laptop:~/azure$ python measure.py lake/hourly "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC" | tail -1
read 3,691,565 bytes from 527 of 527 files
ana@laptop:~/azure$ python measure.py lake/hourly "SELECT count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15'" | tail -1
read 112,456 bytes from 17 of 527 files
```

**The month read 3,691,565 bytes, more than the 3,040,868 the table holds**, for the reason the
31 days did in the previous section, seventeen times over. The day read 112,456 bytes from 17
files, where `by_day` read 73,813 from one: half as much again, for the same 2,999 orders. And bytes
are the smaller half of the cost on a real lake. **Every file opened is at least one read request
to the storage account, and usually two**, the footer and then the columns, and lesson 7 showed
that requests are billed by the ten thousand whatever their size.

## Compaction

**Compaction rewrites the small files of each partition into a few large ones, in one commit.** In
Spark and in Fabric it is the `OPTIMIZE` command; in `deltalake` it is `optimize.compact()`, which
`table.py` calls:

```
ana@laptop:~/azure$ python table.py lake/hourly compact
527 files removed, 31 added; now version 527
ana@laptop:~/azure$ python table.py lake/hourly files
version 527: 31 files, 1,058,322 bytes, 98,727 rows in the log
ana@laptop:~/azure$ python measure.py lake/hourly "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC" | tail -1
read 1,427,062 bytes from 31 of 31 files
ana@laptop:~/azure$ find lake/hourly -name '*.parquet' -not -path '*_delta_log*' | wc -l
558
```

**527 files became 31, one per day, and the month question fell from 3,691,565 bytes to
1,427,062.** The table also shrank, from 3,040,868 bytes to 1,058,322: fewer footers, and the
rewrite used zstd, as the delete of the first section did. Compaction changes no row, and the
commit says so:

```
ana@laptop:~/azure$ jq -r 'select(.add or .remove) | "\(keys[0]) dataChange=\((.add // .remove).dataChange)"' lake/hourly/_delta_log/00000000000000000527.json | sort | uniq -c
     31 add dataChange=false
    527 remove dataChange=false
```

**`dataChange=false` on every action tells a reader that follows the table's changes that nothing
new arrived**: a job that reads only what was added since its last run skips this commit, instead
of reading the whole month again as 31 "new" files.

**The disk now holds 558 Parquet files, the 527 old ones and the 31 new.** Compaction is a commit
like any other, so it removes the small files from the table and leaves them where they were. The
storage bill went up, not down, and it stays up until the last section's vacuum.

## When to compact

**Compaction is a job, and it is scheduled like one**: after the hourly loads of a day are finished,
compact that day's partition, which `optimize.compact(partition_filters=...)` does without touching
the other thirty. Compacting a partition that is still being written is wasted work, because the
next hour adds a small file to it again. Databricks can compact as it writes, and runs maintenance on
its own for some tables, lesson 21's subject; Fabric's Spark runs `OPTIMIZE` when a notebook or a
table's maintenance asks for it.

**The size to aim for is tens to hundreds of megabytes a file.** `deltalake`'s own default target is
100 MB, and Spark's Delta aims higher by default, at files up to about a gigabyte. Quitanda's whole month is a megabyte, so
here one file a day is as large as compaction can make it, and a real lake reaches the target long
before it reaches Quitanda's size in a few years.

**Compaction can also sort.** `optimize.z_order(["neighbourhood"])` rewrites the files so that rows
with close values of the named columns sit in the same files, which makes the statistics of the
previous section skip more for a filter on those columns. Spark's `OPTIMIZE ... ZORDER BY` is the
same idea, and Databricks has a newer way of keeping rows clustered as they are written. It was not
run in this lesson: on a month this small every file already holds a whole day, and there is nothing
for it to show.
