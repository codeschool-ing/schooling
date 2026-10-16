---
title: When to use a cluster
version: 1
---

**The course began with a question, and it has an answer now.** Lesson 1 asked when data stops
fitting on one machine; fourteen lessons later, the measurements say:

- **Below a few hundred gigabytes, one machine wins.** This lab's 400 MB took DuckDB a second and a
  tuned Spark job sixteen. A cluster's coordination, a JVM per executor, a shuffle through files,
  tasks scheduled one by one, is pure overhead until one machine is not enough.
- **A cluster wins when the data or the work is past one machine** in the time there is: terabytes to
  scan, a join of two large tables, an hour-long job that must take five minutes. Then everything
  lessons 2 to 13 measured applies, and each lesson's mistake is multiplied by the number of machines.
- **Most of the speed is in reading less.** Columnar files, pruning, partitions and sort order, lessons
  6 and 10, removed more time than any setting of the cluster.
- **Most of the cost is in time that does nothing.** A cluster kept on, executors held through idle
  hours, a job eight times slower than it needs to be: each is paid for by the hour.

**The habit the course has tried to teach is measuring before believing.** Every claim in it came
with a number from a run you can repeat, including the ones that went against the lesson's own
argument: the cures for skew that were slower here, the speculation that could not help on one
machine, the cluster that lost to a single process. A tuning guide, this one included, is a list of
things worth trying; the stages of your own job are what say which one to try first.
