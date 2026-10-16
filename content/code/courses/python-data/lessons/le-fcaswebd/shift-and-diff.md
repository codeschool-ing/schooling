---
title: shift, and comparing with yesterday
version: 1
---

**`shift(n)` moves the values of a series `n` steps along its index, so each row can see the row
before it.** Everything that compares a moment with an earlier one is built on it: the change since
yesterday, the growth since last week.

```python
daily.shift(1).head(3)
```

```
started_at
2025-01-01      NaN
2025-01-02    106.0
2025-01-03    108.0
Freq: D, dtype: float64
```

The index stays where it was; the values slid down one place. The first day has nothing before it,
so it gets `NaN`, and the integers became floats to hold that. **A shift always leaves `n` missing
values at the start**, and anything computed from it starts with them too.

The change from the day before is the series minus its shift, and `diff` is the shorter spelling:

```python
pd.DataFrame({"trips": daily, "yesterday": daily.shift(1), "change": daily.diff()}).head(4)
```

```
            trips  yesterday  change
started_at                          
2025-01-01    106        NaN     NaN
2025-01-02    108      106.0     2.0
2025-01-03    115      108.0     7.0
2025-01-04     47      115.0   -68.0
```

`pct_change` divides the change by the earlier value, a relative change:

```python
daily.pct_change().round(3).head(3)
```

```
started_at
2025-01-01      NaN
2025-01-02    0.019
2025-01-03    0.065
Freq: D, dtype: float64
```

## The right thing to compare with

Day against day mixes in the week: a Saturday is quieter than a Friday because it is a Saturday, and
lesson 15's grid showed how much. Comparing each day with **the same weekday a week earlier** takes the
weekly pattern out:

```python
week_change = daily - daily.shift(7)
week_change.head(9)
```

```
started_at
2025-01-01     NaN
2025-01-02     NaN
2025-01-03     NaN
2025-01-04     NaN
2025-01-05     NaN
2025-01-06     NaN
2025-01-07     NaN
2025-01-08    -6.0
2025-01-09   -47.0
Freq: D, dtype: float64
```

Seven days of `NaN` now, because the first week has no week before it. 8 January, a Wednesday, had 6
trips fewer than 1 January, the Wednesday before; 9 January had 47 fewer than 2 January. Which
`shift` to use is a question about the data, not about pandas: daily data with a weekly rhythm wants
7, monthly data with a yearly one wants 12.

**`shift` moves by rows, not by time.** On `daily`, one row is one day, so `shift(7)` is a week. On a
series with days missing, seven rows back can be ten days back, and the comparison is silently wrong.
`shift(freq="7D")` shifts the index by time instead of the values by rows, and the fourth section is
about why a series with missing days needs care everywhere, not only here.
