---
title: The small-files problem
version: 1
---

**The namenode keeps every file, every directory and every block in memory**, and that is the limit
HDFS actually meets first. A rule of thumb repeated in Hadoop's own guidance puts each of those
objects at about 150 bytes of the namenode's memory. It is an approximation, and it is enough to
show where the trouble comes from.

Put the clicks into HDFS a second time, as they were written in lesson 1: one small file per day.

```
ana@lab:~/big$ time hdfs dfs -put data/raw/clicks /raw/clicks-daily

real	0m29.725s
user	0m12.072s
sys	0m2.241s
```

Now ask `fsck` about both copies of the same data:

```
ana@lab:~/big$ hdfs fsck /raw/clicks-2025.csv | grep -E 'Total (size|files|blocks)'
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
 Total size:	1291239322 B
 Total files:	1
 Total blocks (validated):	10 (avg. block size 129123932 B)
 Total size:	0 B
 Total files:	0
ana@lab:~/big$ hdfs fsck /raw/clicks-daily | grep -E 'Total (size|files|blocks)'
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-daily
 Total size:	248921266 B
 Total files:	366
 Total blocks (validated):	365 (avg. block size 681976 B)
 Total size:	0 B
 Total files:	0
```

Each answer prints its totals twice, and the second set, all zero, counts files stored with erasure
coding, a space-saving alternative to three copies that this lab does not use.

**Same events. One copy is 10 blocks; the other is 365, each a fraction of a
megabyte** (the daily copy is gzipped, so it is smaller in bytes and larger in everything that
costs). For the namenode, the daily copy is thirty-six times as much to remember. And for Spark,
it will be 365 tasks of a few milliseconds of reading each, against 10 tasks of a full block: lesson
2's fixed cost per task, paid 365 times.

At this size it does not matter. At a large site's size it decides whether the cluster works:

| | objects in the namenode | at about 150 bytes each |
|---|---|---|
| 1 PB in files of 1 GB | 1 million files + 8 million blocks | about 1.4 GB |
| 1 PB in files of 1 MB | 1 billion files + 1 billion blocks | about 300 GB |

The second row is the same petabyte. **No namenode holds 300 GB of metadata comfortably, and the
data did not get any bigger**: it only arrived in smaller pieces. Small files come from jobs that
write often (one file per minute per stream), jobs with too many tasks (each task writes its own
file, and lesson 8 meets one that wrote two hundred), and partitioning by a column with too many
values.

The cure is to write fewer, larger files, either at the source or by a *compaction* job that reads
the small files and rewrites them as large ones. Lesson 11's table formats have compaction built in,
because object stores suffer the same disease in a different organ: they have no namenode, but
every small file is still a request, and a request has a cost and a latency.
