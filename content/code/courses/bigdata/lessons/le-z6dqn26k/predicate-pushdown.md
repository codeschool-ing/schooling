---
title: Predicate pushdown, and what blocks it
version: 1
---

**A filter that the reader can apply is a filter that never leaves the file.** The planner hands
`kind = 'purchase'` to the Parquet reader as `PushedFilters`, in all three scans above. The reader
can then use what each file records about its contents to skip parts of it without decoding them.

Parquet records the smallest and largest value of each column for every *row group*, a block of
rows within a file. A row group whose `kind` runs from `cart` to `view` might contain a purchase, so
it is read; a row group whose values all lie outside the filter is skipped whole. That only helps
when values are grouped: here the events of a day are in time order and every kind appears
throughout, so no row group can be ruled out, and the one-day scan handed on all 65,753 of the day's
rows for the `Filter` above it to sort out. Lesson 10 sorts the data and measures the difference.

## The function that blocks it

The fourth query in `pruning.py` asked for the same day through a Python function:

```python
is_pi_day = F.udf(lambda d: d.month == 3 and d.day == 14, "boolean")
```

**Same answer, and all 365 files opened, about twice the time.** The third scan in the
`scan_plans.py` output has no `PartitionFilters` line at all. The planner knows what
`day == "2025-03-14"` means and can turn it into a directory name; it does not know what a Python
function does, so it can only call it on every row of every day. Lesson 5 said a UDF is expensive
because of the trip to Python. This is the larger cost: it blinds the planner.

The contrast is exact. `F.date_format("day", "MM-dd") == "03-14"` is also a function of the
partition column, and the planner does prune with it: it evaluates the expression on each
directory's value, in Java, before opening anything, and its plan, explained on this lab, lists it under
`PartitionFilters`. A Python UDF cannot be evaluated there without Python, so it is left for
the rows. **Prefer built-in functions in filters**, and above all in filters on partition columns.
