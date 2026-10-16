---
title: Missing values, and what pandas does with them by default
version: 1
---

**pandas has three spellings of "missing": `NaN` for floats and text, `NaT` for datetimes, and
`pd.NA` for the nullable types.** `isna()` finds all three, and the rest of this section is about the
decisions pandas makes for you when it meets them.

```python
trips.isna().sum()
```

```
trip_id            0
started_at         0
ended_at         146
start_station      0
end_station      146
plan               0
bike               0
duration         146
dtype: int64
```

`isna()` gives a table of `True` and `False`, and `.sum()` counts each column's missing values: the
146 lost bikes, in every column that depends on the end of the trip.

## Reductions skip them

```python
weather["rain_mm"].sum(), weather["rain_mm"].mean().round(3), weather["rain_mm"].count()
```

```
(np.float64(1712.8), np.float64(4.771), np.int64(359))
```

**pandas skips missing values in reductions by default**, where NumPy, in lesson 5, returned `nan`.
`sum` is 1712.8 because the six unread days were left out, and `count` says how many values were
used: 359. The NumPy behaviour is one argument away, and it is the honest one when a gap should
make the answer unknown:

```python
weather["rain_mm"].sum(skipna=False), pd.Series([np.nan, np.nan]).sum(), pd.Series([np.nan, np.nan]).sum(min_count=1)
```

```
(np.float64(nan), np.float64(0.0), np.float64(nan))
```

The middle one is the trap: the sum of **no** known values is `0.0`, which reads like a dry week. `min_count=1`
asks for at least one real value and returns `NaN` otherwise.

## Removing or filling

```python
trips.dropna(subset=["end_station"]).shape, weather["rain_mm"].fillna(0).sum()
```

```
((33191, 8), np.float64(1712.8))
```

`dropna(subset=...)` removes the rows missing a value in those columns; `fillna(0)` replaces missing
values with 0. Both are decisions, and the second is a claim: that the six unread days were dry. Write
down why, or do not make it.

## Integers that can be missing

A column of whole numbers with a gap becomes float in NumPy, `14.0` and `nan`. pandas has
**nullable integer types**, written with a capital, that keep integers and hold a missing value:

```python
pd.Series([14, None, 12]).dtype, pd.Series([14, None, 12]).astype("Int64").tolist()
```

```
(dtype('float64'), [14, <NA>, 12])
```

`Int64` holds `14`, `<NA>` and `12`. The same idea gives `boolean` and `Float64`; the text type of the
first section is the same idea for strings.
