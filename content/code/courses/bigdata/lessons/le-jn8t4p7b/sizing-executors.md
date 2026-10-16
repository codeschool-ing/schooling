---
title: Sizing executors
version: 1
---

**An executor's memory is shared by the tasks it runs at once, one per core.** Lesson 7 measured
what happens when a task's share is too small: it spills to disk, and its time goes up. Its fixes,
in order, were more partitions, fewer columns, and more memory per task, and the last one has a price.

There are two ways to give each task more memory, and they cost different amounts. Take a machine of
4 cores and 16 GB, about 12 GB of it usable by Spark after the operating system and overheads:

| executor layout | tasks at once | memory per task | machines for 40 tasks at once | at US$0.20 an hour |
|---|---|---|---|---|
| 4 cores, 12 GB | 4 | 3 GB | 10 | US$2.00 an hour |
| 2 cores, 12 GB | 2 | 6 GB | 20 | US$4.00 an hour |
| 4 cores, 24 GB, on a memory-optimised machine at an assumed US$0.26 | 4 | 6 GB | 10 | US$2.60 an hour |

**Halving the cores doubles the memory per task and doubles the bill**, because the same work now
needs twice the machines. A machine type with more memory per core gives the same memory per task for
less; cloud providers sell such types at a premium that is usually far below double, and the assumed
30% here is of that order. The cheapest way of all is still the first fix: **more partitions cost
nothing** but some scheduling, and a task with half the rows needs half the memory.

**What to measure before resizing anything**: the `spill` column of the stages, as `history.py`
prints it, and the task time beside it. No spill, and more memory buys nothing. Spill in one task out
of two hundred is lesson 8's skew, and memory for every task is the most expensive way to pay for one.
Spill everywhere, after the partitions are right, is the case for more memory per task, and the table
above is how to choose its price.
