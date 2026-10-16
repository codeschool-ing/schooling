---
title: resample, a groupby on the calendar
version: 1
---

**`resample` groups a time series into periods of the calendar, a day, a week, a month, and
aggregates each.** It is how a daily series becomes a weekly or monthly one, and like any `groupby` it
needs a calculation after it.

Weekly totals:

```python
weekly = daily.resample("W").sum()
weekly.head(3)
```

```
started_at
2025-01-05    431
2025-01-12    565
2025-01-19    649
Freq: W-SUN, dtype: int64
```

```python
weekly.tail(2)
```

```
started_at
2025-12-28    609
2026-01-04    342
Freq: W-SUN, dtype: int64
```

**The first and last weeks are short.** `"W"` cuts weeks that end on Sunday and labels each with its
Sunday, so the week labelled 5 January holds only 1 to 5 January, five days, and the one labelled 4
January 2026 holds 29 to 31 December, three. Their totals of 431 and 342 are not low weeks; they are
partial ones. A chart of weekly totals dips at both ends of every year for this reason, and the fix is
to drop the partial periods or to show a mean per day instead of a sum.

## The label of a period

A month can be labelled by its first day or by its last, and the two spellings say which:

```python
daily.resample("MS").sum().head(3), daily.resample("ME").sum().head(3)
```

```
(started_at
 2025-01-01    2912
 2025-02-01    2756
 2025-03-01    2831
 Freq: MS, dtype: int64,
 started_at
 2025-01-31    2912
 2025-02-28    2756
 2025-03-31    2831
 Freq: ME, dtype: int64)
```

The same totals, labelled `2025-01-01` with `"MS"`, month start, and `2025-01-31` with `"ME"`, month
end. Neither is wrong, but a table labelled by month end and joined to one labelled by month start
matches nothing, and lesson 14 showed how quietly that goes. **Choose one labelling for a project
and write it down.**

## Sum or mean

What to compute per period depends on what the values are. Trips per day are counts, so a week's
total is their sum. Temperatures are readings, so a month's temperature is their mean; summing them
gives a number that grows with the length of the month:

```python
weather = pd.read_csv("weather.csv")
weather["date"] = pd.to_datetime(weather["date"], format="%Y-%m-%d")
temp = weather.set_index("date")["temp_max"]
temp.resample("MS").mean().round(1).head(3), temp.resample("MS").sum().round(1).head(3)
```

```
(date
 2025-01-01    30.3
 2025-02-01    30.5
 2025-03-01    30.4
 Freq: MS, Name: temp_max, dtype: float64,
 date
 2025-01-01    940.4
 2025-02-01    854.7
 2025-03-01    943.7
 Freq: MS, Name: temp_max, dtype: float64)
```

February's sum is lower than January's only because February is shorter. **Counts and totals add up
over time; levels and rates do not**, and that distinction decides `sum` or `mean` for every
`resample` and every rolling window in this lesson.
