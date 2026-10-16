---
title: What plain square brackets do, and why that is not enough
version: 1
---

**On a DataFrame, plain square brackets do three different things depending on what you put in
them.** That convenience is why every tutorial starts with them, and the ambiguity is why careful
code moves to `loc` and `iloc` for anything beyond picking columns.

The notebook for this lesson:

```python
import pandas as pd

trips = pd.read_csv("trips.csv")
weather = pd.read_csv("weather.csv", index_col="date")
```

```python
trips["plan"].head(2)
```

```
0       day
1    annual
Name: plan, dtype: str
```

**A name selects a column**, as a Series. A list of names selects several, as a DataFrame. Now a
boolean Series:

```python
trips[trips["plan"] == "day"].shape
```

```
(9899, 7)
```

**A boolean Series selects rows.** Same brackets, other axis. And a slice of numbers:

```python
trips[2:4]
```

```
   trip_id           started_at             ended_at start_station  \
2        3  2025-01-01 03:09:39  2025-01-01 03:36:59           S16   
3        4  2025-01-01 07:17:40  2025-01-01 07:36:13           S14   

  end_station    plan      bike  
2         S03  annual  electric  
3         S05  annual   classic  
```

**A slice selects rows by position**, on a table whose index happens to be 0, 1, 2, so position and
label agree and nobody notices which one was used. On the weather, indexed by date, the same brackets
with a slice of labels select rows by label:

```python
weather["2025-03-21":"2025-03-23"]
```

```
            rain_mm  temp_max
date                         
2025-03-21     14.3      30.8
2025-03-22     45.9      30.0
2025-03-23      0.0      30.3
```

Three behaviours, chosen from the type of what is inside. Code that reads `df[x]` does not say which
one it means, and the reader has to know what `x` is to find out. The two accessors in the next
sections each do one thing:

| you write | it selects | by |
|---|---|---|
| `df.loc[rows, cols]` | rows and columns | **labels**, or a boolean mask |
| `df.iloc[rows, cols]` | rows and columns | **positions**, 0 to n − 1 |

Keep plain brackets for the one case nobody misreads, a column by name, and use `loc` or `iloc`
everywhere else.
