---
title: merge, two tables by a key
version: 1
---

**`merge` puts two tables side by side by matching the values of a key column.** Each row of one
table is paired with the rows of the other whose key is equal, and every pair becomes a row of the
result. It is SQL's `JOIN` with a pandas spelling, and most analyses need one: the trips know a
station's code but not its name, and the days know their trips but not their rain.

The notebook for this lesson reads the three files once:

```python
import numpy as np
import pandas as pd

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
stations = pd.read_csv("stations.csv")
weather = pd.read_csv("weather.csv")
```

Trips per day, with the day as a column, which is what lesson 13 taught:

```python
daily = trips.groupby(trips["started_at"].dt.normalize()).size().rename("trips")
daily = daily.rename_axis("date").reset_index()
daily.head(3)
```

```
        date  trips
0 2025-01-01    106
1 2025-01-02    108
2 2025-01-03    115
```

And the weather beside them, joined on `date`:

```python
daily.merge(weather, on="date")
```

```
ValueError: You are trying to merge on datetime64[us] and str columns for key 'date'. If you wish to proceed you should use pd.concat
```

**The keys have to be the same type.** `daily["date"]` is a datetime, because it came from
`started_at`; `weather["date"]` is text, because nothing told `read_csv` otherwise. A datetime is
never equal to a string, so pandas refuses rather than returning a table where nothing matched. The
fix is the one lesson 12 taught, at the moment of reading:

```python
weather["date"] = pd.to_datetime(weather["date"], format="%Y-%m-%d")
days = daily.merge(weather, on="date", validate="one_to_one")
days.shape
```

```
(365, 4)
```

```python
days.head(3)
```

```
        date  trips  rain_mm  temp_max
0 2025-01-01    106      0.0      29.9
1 2025-01-02    108      6.8      30.0
2 2025-01-03    115      7.9      30.7
```

One row per day, 365 of them, with the trips and the weather of each. `on="date"` names the key,
which has the same name in both tables; when the names differ, `left_on=` and `right_on=` name each
side. `validate="one_to_one"` is a promise checked by pandas: each date appears at most once on each
side. It costs one argument and the section after next is about the day it fails.

The joined table answers a question neither table could alone:

```python
days[["trips", "rain_mm"]].corr().round(2)
```

```
         trips  rain_mm
trips     1.00    -0.56
rain_mm  -0.56     1.00
```

The correlation is negative: wetter days have fewer trips. The program lesson 8 read through cuts a
day's trips to about half when more than 10 mm of rain falls, and the merge is how you see it.
