---
title: Grouping by several keys, and the index it makes
version: 1
---

**Group by a list of columns and every combination of their values becomes a group.** The result is
indexed by all the keys at once, a **MultiIndex**, and reading or reshaping it is the second half of
this section.

```python
per = trips.groupby(["weekday", "plan"]).size()
per.head(4)
```

```
weekday  plan  
Friday   annual    4087
         day       1266
Monday   annual    4050
         day       1344
dtype: int64
```

One number per weekday and plan. The index has two levels, `weekday` and `plan`, and a row is named by
both. Ask for one weekday and you get its plans:

```python
per.loc["Sunday"]
```

```
plan
annual    1767
day       1708
dtype: int64
```

On Sundays the day passes nearly equal the subscriptions, where on weekdays the subscribers
dominate: the commuters are subscribers, and the leisure riders buy a day.

## From a long result to a table

A result with two keys is easier to read as a table, one key down the side and one across the top.
`unstack` moves the innermost level of the index into the columns:

```python
order = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
table = per.unstack("plan").loc[order]
table
```

```
plan       annual   day
weekday                
Monday       4050  1344
Tuesday      3954  1364
Wednesday    4157  1316
Thursday     3880  1329
Friday       4087  1266
Saturday     1543  1572
Sunday       1767  1708
```

`.loc[order]` puts the weekdays in calendar order, because a groupby sorts its keys alphabetically,
and Friday before Monday is the alphabet's order, not the week's. Lesson 15 is about this reshaping in
full, `unstack` and `pivot_table` and their opposites.

## Keys as columns instead of an index

`as_index=False`, or `reset_index()` afterwards, keeps the keys as ordinary columns, which is the shape
a chart or a join wants:

```python
trips.groupby(["weekday", "plan"], as_index=False).size().head(3)
```

```
  weekday    plan  size
0  Friday  annual  4087
1  Friday     day  1266
2  Monday  annual  4050
```
