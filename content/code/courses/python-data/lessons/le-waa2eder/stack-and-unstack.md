---
title: stack and unstack, and the cells that were never there
version: 1
---

**`unstack` moves a level of the row index into the columns, and `stack` moves the columns back into
the index.** They are `pivot` and `melt` for a table whose keys are already in its index, which is
what a `groupby` with several keys returns.

The lost bikes, by start station and month:

```python
lost = trips[trips["end_station"].isna()]
per = lost.groupby(["start_station", "month"]).size()
len(per)
```

```
107
```

146 bikes, but only 107 rows: a `groupby` returns the combinations that **occurred**, and most
stations lost no bike in most months. Unstacked into a grid of 20 stations by 12 months, the
combinations that never occurred have to be drawn too:

```python
table = per.unstack("month")
table.iloc[:4, :6]
```

```
month            1    2    3    4    5    6
start_station                              
S01            NaN  NaN  NaN  2.0  NaN  1.0
S02            1.0  NaN  NaN  NaN  1.0  NaN
S03            2.0  1.0  NaN  2.0  1.0  4.0
S04            1.0  NaN  1.0  1.0  NaN  NaN
```

**Every combination that did not occur is `NaN`**, and the counts became floats to hold it, the
lesson 12 rule again. For a count, an absent combination means zero, and `fill_value` says so:

```python
table = per.unstack("month", fill_value=0)
table.iloc[:4, :6]
```

```
month          1  2  3  4  5  6
start_station                  
S01            0  0  0  2  0  1
S02            1  0  0  0  1  0
S03            2  1  0  2  1  4
S04            1  0  1  1  0  0
```

```python
int(table.to_numpy().sum())
```

```
146
```

Still 146, now with an honest 0 in each empty cell. Whether a missing cell is 0 depends on what is
being measured: for a count it is; for a median trip length it is not, because no trips is not a
length of zero.

## Back again

`stack` turns the grid back into a Series with a two-level index:

```python
table.stack().shape, per.unstack("month").stack().shape
```

```
((240,), (240,))
```

Both give 240 rows, one per station and month, where `per` had 107. **Once the grid has drawn the
empty cells, they stay**: as zeros in the first, and as `NaN` rows in the second, because pandas 3's
`stack` keeps missing values rather than dropping them. Earlier versions dropped them by default,
which is one more place a notebook can give a different answer after an upgrade. `.dropna()` after
`stack` returns the 107 that occurred.
