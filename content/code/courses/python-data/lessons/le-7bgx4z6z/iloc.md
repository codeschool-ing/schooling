---
title: iloc, by position
version: 1
---

**`iloc` counts rows and columns from zero, exactly like NumPy, whatever the labels say.** Use it
when the question is about position: the first rows, the last column, every tenth row.

```python
trips.iloc[0, 1], trips.iloc[-1, :3].tolist(), trips.iloc[::10000, 0].tolist()
```

```
('2025-01-01 12:22:38',
 [np.int64(33337), '2025-12-31 18:10:12', '2025-12-31 18:20:00'],
 [1, 10001, 20001, 30001])
```

The first trip's second column, the last trip's first three values, and the id of every ten
thousandth trip. Slices stop before the end, as in NumPy.

## Where loc and iloc part company

On the default RangeIndex, the labels are 0, 1, 2, so `trips.loc[5]` and `trips.iloc[5]` are the
same row. Filter the table and they stop being the same:

```python
day = trips[trips["plan"] == "day"]
day.index[:3].tolist(), day.loc[3, "trip_id"] if 3 in day.index else "no label 3", day.iloc[3]["trip_id"]
```

```
([0, 5, 6], 'no label 3', np.int64(12))
```

`day.iloc[3]` is the fourth day-pass trip. `day.loc[3]` would be the trip whose **label** is 3, the
fourth trip of the whole table, and it is only there if that trip was on a day pass. Code written
against the unfiltered table with `loc[3]` means "the fourth row" by accident, and that accident ends
the moment somebody adds a filter above it. **Use `iloc` when you mean position.**

```python
day.loc[3]
```

```
KeyError: 3
```

Here it raised `KeyError`, because trip 4 was on an annual plan. On another filter it would have
returned a row, silently the wrong one.
