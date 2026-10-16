---
title: Split, apply, combine
version: 1
---

**`groupby` splits a table into groups by the values of a column, applies a calculation to each group,
and combines the answers into one result.** It is the single most used operation in pandas, because
nearly every question about data is "this number, per that": trips per station, minutes per plan,
rain per month.

The notebook for this lesson prepares the trips once, with the types lesson 12 gave them:

```python
import numpy as np
import pandas as pd

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
trips["ended_at"] = pd.to_datetime(trips["ended_at"], format=fmt)
trips["minutes"] = (trips["ended_at"] - trips["started_at"]).dt.total_seconds() / 60
trips["hour"] = trips["started_at"].dt.hour
trips["weekday"] = trips["started_at"].dt.day_name()
```

The average trip length on each plan, in one line:

```python
trips.groupby("plan")["minutes"].mean().round(1)
```

```
plan
annual    14.1
day       22.6
Name: minutes, dtype: float64
```

Read the line in the order it works. **Split**: `groupby("plan")` sorts the 33,337 rows into two
groups, by the value of `plan`. **Apply**: `["minutes"].mean()` takes the `minutes` column of each group
and computes its mean. **Combine**: the two means come back as a Series indexed by the group values.
Day passes ride longer, which is what the generator in lesson 8 made them do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Split: the trips table is divided into two groups by plan, annual and day. Apply: the mean of minutes is computed in each group, 14.1 and 22.6. Combine: the two means form one Series indexed by plan.\" data-fig=\"sac\"><defs><marker id=\"sac-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"85\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">split</text><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">apply</text><text x=\"620\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">combine</text><rect x=\"20\" y=\"40\" width=\"130\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">trips</text><text x=\"85.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">33,337 rows</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">plan == annual</text><text x=\"360.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">23,438 rows</text><rect x=\"260\" y=\"150\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">plan == day</text><text x=\"360.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">9,899 rows</text><line x1=\"154\" y1=\"110\" x2=\"256\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#sac-ah)\"></line><line x1=\"154\" y1=\"160\" x2=\"256\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#sac-ah)\"></line><text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mean of minutes</text><rect x=\"540\" y=\"70\" width=\"160\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">annual</text><text x=\"660\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">14.1</text><text x=\"580\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">day</text><text x=\"660\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">22.6</text><line x1=\"464\" y1=\"80\" x2=\"536\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#sac-ah)\"></line><line x1=\"464\" y1=\"190\" x2=\"536\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#sac-ah)\"></line></svg>", "caption": "trips.groupby(\"plan\")[\"minutes\"].mean(): split by plan, a mean per group, one Series."}
```

## The group object

`groupby` on its own computes nothing. It returns an object that knows how the rows are split and
waits for the calculation:

```python
by_plan = trips.groupby("plan")
by_plan.ngroups, by_plan.size()
```

```
(2,
 plan
 annual    23438
 day        9899
 dtype: int64)
```

`size()` counts the rows in each group, including the rows with missing values; `count()` counts the
non-missing values of each column in each group, which is a different number wherever a column has
gaps:

```python
by_plan[["minutes", "end_station"]].count()
```

```
        minutes  end_station
plan                        
annual    23333        23333
day        9858         9858
```

The lost bikes have no `minutes` and no `end_station`, so `count` is lower than `size` for both
plans. **Use `size` to count rows, and `count` to count values.**
