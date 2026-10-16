---
title: The days that are not there
version: 1
---

**A window of seven rows is seven days only when every day has a row.** A count built with `groupby`
has a row only for days when something happened, and a quiet series has gaps. On such a series a
rolling window, a `shift` and a mean are all computed over the wrong days, and none of them says so.

`S12`, the quietest station, counted per day with `groupby`:

```python
s12 = trips[trips["start_station"] == "S12"]
per_day = s12.groupby(s12["started_at"].dt.normalize()).size()
len(per_day), per_day.index.freq
```

```
(326, None)
```

326 rows for a year of 365 days, and no frequency: pandas cannot promise the rows are one day apart,
because they are not. The first days show where:

```python
per_day.head(8)
```

```
started_at
2025-01-01    1
2025-01-02    1
2025-01-03    2
2025-01-04    1
2025-01-06    2
2025-01-08    2
2025-01-09    1
2025-01-10    4
dtype: int64
```

5 and 7 January are missing. Nobody started a trip at `S12` on those days, so `groupby` had nothing
to count and made no row. The right number for those days is 0, and the series does not contain it.

## Two windows, both wrong

A window of 7 rows, and a window of 7 days written as a time, `"7D"`:

```python
pd.DataFrame({"rows": per_day.rolling(7).mean(), "days": per_day.rolling("7D").mean()}).head(10).round(2)
```

```
            rows  days
started_at            
2025-01-01   NaN  1.00
2025-01-02   NaN  1.00
2025-01-03   NaN  1.33
2025-01-04   NaN  1.25
2025-01-06   NaN  1.40
2025-01-08   NaN  1.60
2025-01-09  1.43  1.60
2025-01-10  1.86  2.00
2025-01-11  2.00  2.20
2025-01-12  2.71  3.00
```

The row window on 9 January covers seven rows that reach back to 1 January, nine days. The time
window covers the right days, 3 to 9 January, but it averages only the rows that exist in them, so the
two empty days are left out rather than counted as 0. **A time window fixes the span and not the
missing zeros.** It also answers from the first day, because a window of time needs only one value by
default where a window of rows needs all of them.

## The fix is in the data

`resample` builds the series from the calendar, so every day is there and an empty day counts 0:

```python
full = s12.set_index("started_at").resample("D").size()
len(full), int((full == 0).sum())
```

```
(365, 39)
```

```python
full.rolling(7).mean().loc["2025-01-07":"2025-01-10"].round(2)
```

```
started_at
2025-01-07    1.00
2025-01-08    1.14
2025-01-09    1.14
2025-01-10    1.43
Freq: D, dtype: float64
```

On 9 January the honest mean is 1.14 trips a day, where the row window said 1.43 and the time window
1.60. Over the year the gap is the same shape:

```python
round(per_day.mean(), 2), round(full.mean(), 2)
```

```
(np.float64(2.6), np.float64(2.32))
```

The mean of the days that had trips is not the mean of the days. **Before a window, make sure the
series has a row for every step**, and decide what an empty step is.

That decision depends on what the series measures. A count with no events is 0, so `resample`'s 0 is
right. A **reading** that was not taken is unknown, not 0: the six days with no rain gauge reading in
`weather.csv` are `NaN`, and a rolling rain total either becomes `NaN` around them or, with a time
window or `min_periods`, quietly treats them as dry. The weather has a row for every day; what it
lacks is six values, and lesson 12's question returns, what you want the missing ones to mean.
