---
title: Wide and long, and pivot between them
version: 1
---

**The same numbers can be laid out long, one row per observation, or wide, one row per thing with a
column per measurement.** Neither is the right shape in general. Each is the right shape for some
job, and most reshaping in pandas is moving a table from the one it arrived in to the one the next
step wants.

The notebook for this lesson prepares the trips as lesson 13 did, with the month as well:

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
trips["month"] = trips["started_at"].dt.month
order = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
```

Trips per month and plan, in the shape a `groupby` gives:

```python
long = trips.groupby(["month", "plan"]).size().rename("trips").reset_index()
long.head(4)
```

```
   month    plan  trips
0      1  annual   2016
1      1     day    896
2      2  annual   1902
3      2     day    854
```

That is **long**: every row is one observation, a month and a plan and a count, and the column
names say what each value is. It is the shape `groupby`, `merge` and seaborn want, because a
calculation over "every count" is a calculation over one column.

`pivot` turns it **wide**: one value of `index` per row, one value of `columns` per column, and
`values` in the cells:

```python
wide = long.pivot(index="month", columns="plan", values="trips")
wide.head(3)
```

```
plan   annual  day
month             
1        2016  896
2        1902  854
3        1983  848
```

```python
long.shape, wide.shape
```

```
((24, 3), (12, 2))
```

The same 24 numbers, in 24 rows of three columns or in 12 rows of two. Wide is the shape a person
reads, because the two plans of a month sit next to each other, and the shape for arithmetic
**across** the columns of a row:

```python
(wide["day"] / wide.sum(axis=1)).round(3).head(3)
```

```
month
1    0.308
2    0.310
3    0.300
dtype: float64
```

The day passes' share of each month, one division. In the long shape the same answer needs a
`groupby` and a `transform`, which is lesson 13's share within a group.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The same four counts in two shapes. Long: four rows, each with a month, a plan and a number of trips. Wide: two rows, one per month, with a column for each plan. pivot goes from long to wide; melt goes back.\" data-fig=\"shapes\"><defs><marker id=\"shapes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"140\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">long</text><text x=\"570\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">wide</text><rect x=\"20\" y=\"40\" width=\"240\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">month</text><text x=\"140\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">plan</text><text x=\"220\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">trips</text><line x1=\"30\" y1=\"74\" x2=\"250\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"60\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"140\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">annual</text><text x=\"220\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">2016</text><text x=\"60\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"140\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">day</text><text x=\"220\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">896</text><text x=\"60\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><text x=\"140\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">annual</text><text x=\"220\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1902</text><text x=\"60\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><text x=\"140\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">day</text><text x=\"220\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">854</text><rect x=\"450\" y=\"70\" width=\"240\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">month</text><text x=\"580\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">annual</text><text x=\"655\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">day</text><line x1=\"460\" y1=\"106\" x2=\"680\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"500\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"580\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">2016</text><text x=\"655\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">896</text><text x=\"500\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><text x=\"580\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1902</text><text x=\"655\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">854</text><line x1=\"280\" y1=\"110\" x2=\"430\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#shapes-ah)\"></line><text x=\"355\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">pivot</text><line x1=\"430\" y1=\"160\" x2=\"280\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#shapes-ah)\"></line><text x=\"355\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">melt</text><text x=\"355\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the same four numbers</text></svg>", "caption": "Long has a row per observation; wide has a row per month and a column per plan."}
```

## When pivot refuses

`pivot` only moves values. It never combines them, so every pair of `index` and `columns` has to
name at most one row:

```python
trips.pivot(index="month", columns="plan", values="minutes")
```

```
ValueError: Index contains duplicate entries, cannot reshape
```

Each month and plan has thousands of trips, and `pivot` has nowhere to put all their minutes in one
cell. **The error means the table is not yet one row per cell**: aggregate first, with `groupby` as
`long` did, or let `pivot_table` aggregate for you, which is the next section.
