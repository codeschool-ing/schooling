---
title: A DataFrame is Series that share an index
version: 1
---

**A DataFrame is a table: several Series side by side, one per column, all sharing one index.**
Each column has its own dtype. The index labels the rows. Read the trips:

```python
trips = pd.read_csv("trips.csv")
trips.head()
```

```
   trip_id           started_at             ended_at start_station  \
0        1  2025-01-01 12:22:38  2025-01-01 12:57:03           S07   
1        2  2025-01-01 20:08:24  2025-01-01 20:25:16           S20   
2        3  2025-01-01 03:09:39  2025-01-01 03:36:59           S16   
3        4  2025-01-01 07:17:40  2025-01-01 07:36:13           S14   
4        5  2025-01-01 22:57:18  2025-01-01 23:04:01           S05   

  end_station    plan      bike  
0         S05     day  electric  
1         S07  annual  electric  
2         S03  annual  electric  
3         S05  annual   classic  
4         S08  annual  electric  
```

The unnamed column on the left is the index. Nobody asked for one, so pandas made the default, a
**RangeIndex**, the numbers 0, 1, 2 and so on, which are labels that happen to look like positions.
The next section is about the trouble that resemblance causes.

```python
trips.shape, trips.columns.tolist()
```

```
((33337, 7),
 ['trip_id',
  'started_at',
  'ended_at',
  'start_station',
  'end_station',
  'plan',
  'bike'])
```

Thirty-three thousand three hundred and thirty-seven trips, seven columns.

## A column is a Series

```python
plan = trips["plan"]
type(plan), plan.head(3)
```

```
(pandas.Series,
 0       day
 1    annual
 2    annual
 Name: plan, dtype: str)
```

One pair of brackets with a column's name gives that column, as a Series, with the table's index.
Two pairs, with a list inside, give a smaller DataFrame:

```python
trips[["start_station", "end_station"]].head(3)
```

```
  start_station end_station
0           S07         S05
1           S20         S07
2           S16         S03
```

## A new column is one line

Arithmetic on columns is arithmetic on Series, vectorised as lesson 5 taught, and assigning to a
new name adds it:

```python
trips["round_trip"] = trips["start_station"] == trips["end_station"]
trips["round_trip"].sum(), trips["round_trip"].mean().round(4)
```

```
(np.int64(2096), np.float64(0.0629))
```

A boolean column, one value per trip, counted and averaged the same way lesson 5 counted NumPy
booleans. Every row of the new column lines up with its trip through the shared index; the columns
cannot drift apart, which is the advantage over keeping separate arrays.

```python
trips.dtypes
```

```
trip_id          int64
started_at         str
ended_at           str
start_station      str
end_station        str
plan               str
bike               str
round_trip        bool
dtype: object
```

Read the dtypes before anything else. `trip_id` is an integer, `round_trip` a boolean, and the other
six are `str`: **the times are text**. `read_csv` did not recognise `2025-01-01 12:22:38` as a date,
because nothing told it to. You cannot subtract two strings to get a duration, and lesson 12 is about
turning them into real dates. Until then, they are labels that sort in the right order by luck of
their format.
