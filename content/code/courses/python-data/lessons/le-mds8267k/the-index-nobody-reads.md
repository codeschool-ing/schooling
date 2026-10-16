---
title: The index nobody reads
version: 1
---

**Every DataFrame has an index whether you chose one or not, and it travels with the rows through
every filter and sort.** Most mistakes with it come from code that never looks at it: it is printed
on the left of every table, and it is the column people's eyes skip.

Take the electric trips, and look at the first three:

```python
electric = trips[trips["bike"] == "electric"]
electric.head(3)
```

```
   trip_id           started_at             ended_at start_station  \
0        1  2025-01-01 12:22:38  2025-01-01 12:57:03           S07   
1        2  2025-01-01 20:08:24  2025-01-01 20:25:16           S20   
2        3  2025-01-01 03:09:39  2025-01-01 03:36:59           S16   

  end_station    plan      bike  round_trip  
0         S05     day  electric       False  
1         S07  annual  electric       False  
2         S03  annual  electric       False  
```

The index reads `0, 1, 2`, because the first three trips happen to be electric. Further down the
table it will not be consecutive: **filtering keeps each row's original label**. Sort, and the labels
come along:

```python
last_ids = electric.sort_values("trip_id", ascending=False).head(3)
last_ids
```

```
       trip_id           started_at             ended_at start_station  \
33336    33337  2025-12-31 18:10:12  2025-12-31 18:20:00           S05   
33335    33336  2025-12-31 18:19:41  2025-12-31 18:39:24           S15   
33334    33335  2025-12-31 09:26:11  2025-12-31 09:30:51           S18   

      end_station    plan      bike  round_trip  
33336         S07  annual  electric       False  
33335         S09  annual  electric       False  
33334         S15  annual  electric       False  
```

The labels are now in the 33,000s, because those are the rows' own labels. That is correct, and it is
what makes the next two lines behave differently from what a reader of the code expects.

## Where it bites

A Series built from a list gets a fresh RangeIndex, 0, 1, 2. Assign it to a filtered table, and
pandas aligns by label:

```python
others = trips.iloc[100:103].copy()
others["note"] = pd.Series(["a", "b", "c"])
others[["trip_id", "note"]]
```

```
     trip_id note
100      101  NaN
101      102  NaN
102      103  NaN
```

`others` has the labels 100, 101 and 102; the new Series has 0, 1 and 2. **No label matches, so every
note is missing**, without an error. The fix depends on what you meant. If the three notes belong to
the three rows in order, say "by position" by handing over values with no index of their own:

```python
others["note"] = ["a", "b", "c"]
others[["trip_id", "note"]]
```

```
     trip_id note
100      101    a
101      102    b
102      103    c
```

A plain list has no labels, so it is matched by position. Or throw the old labels away when they no
longer mean anything, with `reset_index(drop=True)`, which numbers the rows 0, 1, 2 again; `drop=True`
stops the old index becoming a column.

The habit that prevents all of this: **when a table has been filtered or sorted, glance at its index
before combining it with anything.** The left column is part of the data.
