---
title: The slow path in groupby
version: 1
---

**In a `groupby`, a named aggregation runs in compiled code, a function runs once per group in
Python, and `apply` runs once per group with a DataFrame built for each.** Lesson 13 promised a
measurement, and this is it. With a handful of groups the difference hides; with a group per day it
does not.

The median trip of each day, three ways:

```python
trips["day"] = trips["started_at"].dt.normalize()
by_day = trips.groupby("day")["minutes"]

named = by_day.median()
lam = by_day.agg(lambda s: s.median())
named.equals(lam), by_day.ngroups
```

```
(True, 365)
```

The same 365 medians. The time each takes:

```python
t_named = %timeit -o -q by_day.median()
t_lam = %timeit -o -q by_day.agg(lambda s: s.median())
t_apply = %timeit -o -q trips.groupby("day")[["minutes"]].apply(lambda g: g["minutes"].median())
round(t_named.average * 1000, 1), round(t_lam.average * 1000, 1), round(t_apply.average * 1000, 1)
```

```
(0.8, 26.0, 46.5)
```

The named median is under a millisecond. The `lambda` calls a Python function 365 times and takes
tens of times longer; `apply` also builds a DataFrame for each group and takes longer again. The
answer is the same in all three, which is what makes the slow ones easy to keep without noticing.

The cost grows with the **number of groups**, not the number of rows. By station, 20 groups, the
`lambda` costs a couple of milliseconds and nobody would notice; by trip, or by station and minute,
it is the row loop of the first section again. **Give `agg` and `transform` the names they know**,
`"median"`, `"mean"`, `"sum"`, `"size"`, `"nunique"`, `"first"`, and keep functions for
calculations no name covers.
