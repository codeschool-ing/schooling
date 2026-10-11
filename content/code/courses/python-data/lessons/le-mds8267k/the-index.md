---
title: Choosing an index
version: 1
---

**The index is the column pandas uses to line rows up, and you choose it.** The default RangeIndex
is a placeholder. When a table has a column that names its rows, a date or an id, making it the
index gives every alignment, every lookup and every join something meaningful to work with.

```python
weather = pd.read_csv("weather.csv", index_col="date")
weather.head(3), weather.index[:3]
```

```
(            rain_mm  temp_max
 date                         
 2025-01-01      0.0      29.9
 2025-01-02      6.8      30.0
 2025-01-03      7.9      30.7,
 Index(['2025-01-01', '2025-01-02', '2025-01-03'], dtype='str', name='date'))
```

`index_col` made `date` the index while reading. The same thing on a table already loaded is
`set_index`, and its opposite, `reset_index`, turns the index back into an ordinary column:

```python
by_id = trips.set_index("trip_id")
by_id.loc[1, "start_station"], by_id.reset_index().columns[:3].tolist()
```

```
('S07', ['trip_id', 'started_at', 'ended_at'])
```

## Lookups by label

With dates as the index, a row is asked for by its date and a range of rows by two dates:

```python
weather.loc["2025-03-22"], weather.loc["2025-03-20":"2025-03-23", "rain_mm"]
```

```
(rain_mm     45.9
 temp_max    30.0
 Name: 2025-03-22, dtype: float64,
 date
 2025-03-20    25.0
 2025-03-21    14.3
 2025-03-22    45.9
 2025-03-23     0.0
 Name: rain_mm, dtype: float64)
```

**A label range includes both ends**, unlike a position slice: `"2025-03-20":"2025-03-23"` gives four
days. Lesson 11 makes the difference precise.

## An index that is not unique

Nothing forces an index to be unique, and `stations.csv` shows why that matters:

```python
stations = pd.read_csv("stations.csv", index_col="station_id")
stations.index.is_unique, stations.loc["S07"]
```

```
(False,
                    name  docks  valid_from
 station_id                                
 S07         Rua da Hora     17  2025-01-01
 S07          Espinheiro     17  2025-07-01)
```

Asking for `S07` returns **two rows**, not one: the station was renamed in July, and the file has a
row for each name, each from its own date. Code that expected `stations.loc[code, "name"]` to be one
name gets a Series of two. `is_unique` is the check, and lesson 14 is about what a duplicated key
does to a join, where it does more damage than here.
