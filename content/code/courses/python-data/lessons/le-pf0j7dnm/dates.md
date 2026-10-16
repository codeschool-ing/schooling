---
title: Dates, from text to datetime
version: 1
---

**A datetime column stores each moment as a number underneath, so it sorts, subtracts and groups
correctly, and has a `.dt` accessor for its parts.** The trips' times have been text since lesson 9.
Convert them, telling pandas the exact format:

```python
fmt = "%Y-%m-%d %H:%M:%S"
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
trips["ended_at"] = pd.to_datetime(trips["ended_at"], format=fmt)
trips[["started_at", "ended_at"]].dtypes
```

```
started_at    datetime64[us]
ended_at      datetime64[us]
dtype: object
```

`datetime64[us]` is a moment to the microsecond. The empty `ended_at` of the lost bikes became `NaT`.
**Give the format.** Without it, pandas infers one from the first value, which works on a clean column
and fails, or worse, guesses wrong, on one where some dates are written `03/04/2025`: the 3rd of April
in Brazil, the 4th of March in the United States, and nothing in the string says which.

```python
pd.to_datetime("03/04/2025", format="%d/%m/%Y"), pd.to_datetime("03/04/2025", format="%m/%d/%Y")
```

```
(Timestamp('2025-04-03 00:00:00'), Timestamp('2025-03-04 00:00:00'))
```

## The parts of a moment

```python
start = trips["started_at"]
start.dt.hour.head(3).tolist(), start.dt.day_name().head(3).tolist(), start.dt.month.value_counts().sort_index().head(3)
```

```
([12, 20, 3],
 ['Wednesday', 'Wednesday', 'Wednesday'],
 started_at
 1    2912
 2    2756
 3    2831
 Name: count, dtype: int64)
```

`.dt.hour`, `.dt.day_name()`, `.dt.month`, `.dt.date` and a dozen more, each a column of the same
length. The trips per month read off directly: January, February and March, each close to 3,000. Lesson 13 groups by these parts, and lesson 16 builds a time series on them.

## Selecting by date

Comparisons with a date written as text work, because pandas converts the text:

```python
carnival = trips[(start >= "2025-03-01") & (start < "2025-03-06")]
len(carnival), carnival["started_at"].min(), carnival["started_at"].max()
```

```
(421, Timestamp('2025-03-01 01:20:23'), Timestamp('2025-03-05 22:16:59'))
```

Carnival in 2025, from Saturday the 1st of March to Ash Wednesday, the 5th, written as a half-open range: from the
first moment of the 1st, up to but not including the 6th. **Use `<` on the day after** rather than
`<=` on the last day, which would stop at midnight at its very start and leave the whole day out.
