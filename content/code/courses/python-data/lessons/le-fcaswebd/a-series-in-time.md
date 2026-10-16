---
title: A series in time
version: 1
---

**A time series is a Series whose index is made of moments, one value per moment, in order.** With a
`DatetimeIndex`, pandas knows the calendar: it can slice by dates written as text, step back a day or
a week, and count in windows of time. This lesson builds one series and asks it the questions every
series over time gets.

The notebook reads the trips once:

```python
import numpy as np
import pandas as pd

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
```

Trips per day, as a series indexed by day:

```python
daily = trips.set_index("started_at").resample("D").size()
daily.head(3)
```

```
started_at
2025-01-01    106
2025-01-02    108
2025-01-03    115
Freq: D, dtype: int64
```

`resample("D")` is a `groupby` on time: it cuts the index into days and counts the rows in each. The
last section of this lesson is about it; for now, the point is the result. The index is one entry per
day, and `Freq: D` under it says pandas knows the entries are one day apart, every one of them:

```python
len(daily), daily.index.min(), daily.index.max()
```

```
(365, Timestamp('2025-01-01 00:00:00'), Timestamp('2025-12-31 00:00:00'))
```

365 days, from the first of January to the last of December. A day with no trips would still be
there, with a count of 0, because the days come from the calendar and not from the data. That
difference is the subject of the fourth section.

## Asking for dates

With a `DatetimeIndex`, a date written as text selects by the calendar. The wettest day of the year,
22 March, and the days around it:

```python
daily["2025-03-20":"2025-03-24"]
```

```
started_at
2025-03-20     56
2025-03-21     90
2025-03-22     43
2025-03-23     63
2025-03-24    106
Freq: D, dtype: int64
```

43 trips on the day 45.9 mm of rain fell, a Saturday, when a dry Saturday has about seventy. Both ends of
the slice are included, as with every `.loc` slice by label. A shorter string selects everything it
covers, so `daily["2025-03"]` is the whole of March:

```python
daily["2025-03"].sum(), daily["2025-03"].idxmin()
```

```
(np.int64(2831), Timestamp('2025-03-22 00:00:00'))
```

The busiest and quietest days of the year are one call each:

```python
daily.idxmax(), daily.max(), daily.idxmin(), daily.min()
```

```
(Timestamp('2025-07-09 00:00:00'),
 np.int64(134),
 Timestamp('2025-05-17 00:00:00'),
 np.int64(28))
```

The quietest is a Saturday in May with nearly 20 mm of rain, both of which cut trips in this data.
A single day is noisy, though: a high or a low tells you about that day, and the questions about the
**trend** need the rest of this lesson.
