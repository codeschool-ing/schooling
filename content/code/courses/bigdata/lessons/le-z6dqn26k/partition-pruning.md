---
title: Partition pruning
version: 1
---

**A filter on a partition column is answered by the directory names, before any file is opened.**
The silver layer is laid out as lesson 3 described, one directory per day, so `day = '2025-03-14'`
names exactly one directory. The planner turns the filter into `PartitionFilters` on the scan, the
listing skips 364 directories, and one file is read: the second scan in the last section.

The numbers from `pruning.py`, side by side:

| | files opened | rows handed on |
|---|---|---|
| all days | 365 | 24,000,000 |
| one day | 1 | 65,753 |

**That is the cheapest optimisation there is**, and it is decided by the layout, not by the query.
Lesson 3's rule of thumb, partition by what queries filter on, is the reason: a query on the clicks
that names a period reads only that period, and nothing else in this lesson saves as much.

Two things make it fail quietly:

- **A filter on something other than the partition column.** `ts` holds the same information as
  `day`, to the second, but a filter on `ts` between two times is not a filter on `day`, and the
  planner does not know that the one implies the other. Every directory is opened. Filter on `day`,
  or on both.
- **A function the planner cannot see through**, which is the next section's example, and the most
  expensive way to write a correct query in this lesson.
