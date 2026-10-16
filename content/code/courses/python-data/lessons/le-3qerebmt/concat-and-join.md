---
title: concat stacks, and join matches on the index
version: 1
---

**`pd.concat` stacks tables that have the same kind of rows, one under the other.** It matches columns
by name, not rows by key. The usual case is data that arrives in pieces, one file per month:

```python
months = [part for _, part in trips.groupby(trips["started_at"].dt.month)]
len(months), [len(m) for m in months[:3]]
```

```
(12, [2912, 2756, 2831])
```

Twelve tables, one per month. Stacking them back gives the year:

```python
year = pd.concat(months, ignore_index=True)
len(year), year.index[-3:]
```

```
(33337, RangeIndex(start=33334, stop=33337, step=1))
```

`ignore_index=True` numbers the rows afresh, 0 to 33,336. Without it each piece keeps its own labels,
which here happen to be unique because they came from one table; pieces read from twelve files would
each start at 0, and the result would have twelve rows labelled 0, the duplicated index of lesson 9.

When the pieces do not have the same columns, `concat` keeps every column and fills the gaps:

```python
a = pd.DataFrame({"trip_id": [1, 2], "bike": ["classic", "electric"]})
b = pd.DataFrame({"trip_id": [3], "bike": ["classic"], "battery": [0.8]})
pd.concat([a, b], ignore_index=True)
```

```
   trip_id      bike  battery
0        1   classic      NaN
1        2  electric      NaN
2        3   classic      0.8
```

**A column that exists in only some pieces becomes `NaN` in the others**, and a misspelt column name
in one month's file becomes a second column, half empty, beside the right one. After a `concat`,
check `columns` as well as the length.

## join, a merge on the index

`DataFrame.join` is `merge` with the right table's **index** as its key. With a station table indexed
by code, it reads well:

```python
docks = stations.drop_duplicates("station_id").set_index("station_id")[["docks"]]
trips.join(docks, on="start_station")[["trip_id", "start_station", "docks"]].head(3)
```

```
   trip_id start_station  docks
0        1           S07     17
1        2           S20     13
2        3           S16     20
```

`drop_duplicates` is safe here and was not in the last section: both `S07` rows have 17 docks, so
either is right. Joining the docks of the end station too puts a second `docks` column in the same
table, and `join` will not choose a name for you:

```python
trips.join(docks, on="start_station").join(docks, on="end_station")
```

```
ValueError: columns overlap but no suffix specified: Index(['docks'], dtype='str')
```

```python
both = trips.join(docks, on="start_station").join(docks, on="end_station", rsuffix="_end")
both[["start_station", "docks", "end_station", "docks_end"]].head(3)
```

```
  start_station  docks end_station  docks_end
0           S07     17         S05       20.0
1           S20     13         S07       17.0
2           S16     20         S03       20.0
```

`docks_end` is a float because the lost bikes have no end station, and a missing value turns a
column of integers into floats, as lesson 12 showed.

`merge` does the same with `suffixes=("_x", "_y")` by default and **does not** refuse, so a merge of
two tables that share a column name gives you `docks_x` and `docks_y` without asking. Name them
yourself, `suffixes=("_start", "_end")`, so the table still reads in a month.

**`concat` for rows of the same kind, `merge` for a key in a column, `join` for a key in the
index.** All three can lose or multiply rows, and the same habit catches all three: count before and
after.
