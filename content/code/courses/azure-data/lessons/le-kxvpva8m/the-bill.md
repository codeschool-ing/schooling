---
title: The layout, priced
version: 1
---

**A lake's bill has three lines that the file layout sets**: the bytes each question reads, the
files each question opens, and the bytes kept on disk for versions nobody reads. This section puts
the measurements of the lesson into each line. Nothing in it was billed or run on Azure: the counts
are this lesson's, and the prices are **illustrative**, round numbers for doing the sum with, which
lesson 1's price sheet replaces with real ones.

## Bytes: what the partition and the statistics save

The question about one day is the one a dashboard asks, and Quitanda's asks it every ten minutes,
4,464 times in October. At a lake a thousand times this one, each read grows a thousandfold, and at
**an illustrative 5 USD per terabyte processed**, the shape of Synapse's serverless bill from lesson
16:

| layout | read here | one question at ×1,000 | a month of questions | USD a month |
|---|---:|---:|---:|---:|
| `one`: one file, no partitions | 372,157 bytes | 372.2 MB | 1,661.3 GB | 8.31 |
| `by_day`: partitioned by day | 73,813 bytes | 73.8 MB | 329.5 GB | 1.65 |
| `daily`: one file per day, no partitions | 74,167 bytes | 74.2 MB | 331.1 GB | 1.66 |

**The partition and the statistics each cut the bill to a fifth, and they cut it by the same
amount.** What they both buy is a reader that knows, before opening anything, which file holds the
fifteenth. The month question gets nothing from either, because it needs every day; what helps it
is the column format, which read 396,833 of the one file's 1,205,188 bytes.

## Files: a count that does not grow with the data

**The number of files is set by how often the table is written, not by how much is in it.** At a
thousand times the orders, an hourly load still writes 17 files a day; they are bigger, and there are
just as many. So the cost of small files is best counted in files opened. Each one is at least two
read requests to the storage account, one for the footer and one for the columns:

| question | layout | files opened | read requests a month, at 4,464 questions |
|---|---|---:|---:|
| one day | `by_day` | 1 | 8,928 |
| one day | `hourly` | 17 | 151,776 |
| the month | `by_day` | 31 | 276,768 |
| the month | `hourly`, before compaction | 527 | 4,705,056 |

At **an illustrative 0.005 USD per 10,000 read operations**, the last line is 2.35 USD a month and the
one above it 0.14: small money for one table and one dashboard, and seventeen times as much for the
same answers. It grows with every table written that way and every question asked of it, and it
is not the only cost. On Fabric each file opened is also capacity time, and lesson 17's Direct Lake
counts files against its guardrails. A writer that commits every minute leaves 1,440 files a day in
each partition it touches, and that is where a lake becomes slow without becoming large.

## Versions: the storage nobody reads

**Before its vacuum, the `hourly` table kept 4,099,190 bytes on disk for a table of 1,058,322**, nearly
four times its size, all of it the past: the 527 small files the compaction replaced. Every rewrite
leaves the old files behind until the retention runs out:

- a nightly compaction rewrites the day it compacts, so seven days of retention keep about a week of
  those rewrites;
- a delete rewrites every file that held a deleted row, which is the whole table when there is one
  file and one day when the table is split by day, 98,726 rows copied against 2,998 in this lesson;
- a privacy erasure, the deletion of one customer's orders, touches every day the customer ordered
  on, and the old files still hold the customer's rows until vacuum removes them.

That last point is the one that is not about money. **A deleted row is gone from the table at once
and from the disk only after vacuum.** A company that must erase a person's data within a deadline
has to vacuum within it, and a retention of seven days is seven days in which the old files can be
read by anyone who reads the folder or travels back in time.

## What Quitanda's lake should be

The measurements give one answer for the orders table:

- **one file per day, written in order**, either partitioned by `dt` or appended a day at a time; at
  Quitanda's size the statistics skip as well as the folders do, and a partition column is worth
  having when a tool that reads only folders, not the log, will read the table;
- **compaction of each day after its last load**, so that hourly or streaming writes never reach the
  readers as hundreds of files;
- **vacuum every night with the seven-day default**, which keeps a week of time travel and bounds
  both the storage and how long an erased row survives;
- **nothing read from the folder by a tool that does not read the log**, because that tool counts
  every version at once.

Each of those is decided when the table is written and paid for every time it is read, which is
why the next three lessons, about the jobs that write the lake, keep coming back to them.
