---
title: apply on rows, and what it costs
version: 1
---

**`DataFrame.apply(f, axis=1)` calls a Python function once per row, and each call receives the row
as a new Series.** It reads like the way a person thinks, one trip at a time, and it is the slowest
way pandas has to do almost anything. This lesson measures how slow, and shows what to write instead.

The notebook reads the trips with their times, and nothing else yet:

```python
import numpy as np
import pandas as pd

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
trips["ended_at"] = pd.to_datetime(trips["ended_at"], format=fmt)
stations = pd.read_csv("stations.csv")
```

The length of each trip, written as a function of one row:

```python
def minutes_of(row):
    return (row["ended_at"] - row["started_at"]).total_seconds() / 60

by_row = trips.apply(minutes_of, axis=1)
by_row.head(3)
```

```
0    34.416667
1    16.866667
2    27.333333
dtype: float64
```

It works, and the numbers are right. The same calculation on whole columns, as lesson 12 wrote it:

```python
by_column = (trips["ended_at"] - trips["started_at"]).dt.total_seconds() / 60
by_row.equals(by_column)
```

```
True
```

The same 33,337 values, lost bikes' `NaN` included. Now the time each one takes, with `%timeit` as in
lesson 5:

```python
rows = %timeit -o -q trips.apply(minutes_of, axis=1)
cols = %timeit -o -q (trips["ended_at"] - trips["started_at"]).dt.total_seconds() / 60
round(rows.average * 1000), round(cols.average * 1000, 1), round(rows.average / cols.average)
```

```
(329, 0.7, 479)
```

The first number is milliseconds for the row version, the second for the column version, and the
third how many times slower the row version is. Your numbers will differ; the ratio should still be
in the hundreds, because what makes it is the same on every machine. A third of a second sounds like
nothing until the table has three million rows, or the cell runs in a loop, and then it is the
difference between a notebook you rerun freely and one you are afraid to touch.

## Where the time goes

The column version subtracts two arrays of 33,337 timestamps in compiled code, once. The row version
does, 33,337 times: build a Series for the row, look up two labels in it, subtract two Python
timestamp objects, call a method, divide, and hand the answer back. Every step is ordinary Python,
and the loop around them is Python too. It is lesson 5's loop with a pandas object built on every
pass.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two ways to compute trip lengths. On the left, apply with axis=1 builds a Series for each of the 33,337 rows and calls a Python function on it, one row at a time. On the right, two whole columns are subtracted once, in compiled code.\" data-fig=\"loop\"><defs><marker id=\"loop-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">apply(minutes_of, axis=1)</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">ended_at - started_at</text><rect x=\"20\" y=\"50\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">row 0</text><line x1=\"134\" y1=\"66\" x2=\"196\" y2=\"66\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#loop-ah)\"></line><rect x=\"200\" y=\"50\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">minutes_of(row)</text><rect x=\"20\" y=\"92\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">row 1</text><line x1=\"134\" y1=\"108\" x2=\"196\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#loop-ah)\"></line><rect x=\"200\" y=\"92\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">minutes_of(row)</text><rect x=\"20\" y=\"134\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">row 2</text><line x1=\"134\" y1=\"150\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#loop-ah)\"></line><rect x=\"200\" y=\"134\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">minutes_of(row)</text><text x=\"75\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">… 33,337 times</text><text x=\"180\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a Series built, and a Python call, per row</text><line x1=\"380\" y1=\"40\" x2=\"380\" y2=\"230\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"420\" y=\"60\" width=\"100\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ended_at</text><text x=\"470.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">33,337</text><rect x=\"560\" y=\"60\" width=\"100\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">started_at</text><text x=\"610.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">33,337</text><text x=\"540\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper)\">−</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one subtraction, in compiled code</text></svg>", "caption": "apply with axis=1 is a Python loop that builds a row for every call; a column expression is one call."}
```

**Before writing `apply(..., axis=1)`, ask whether the calculation is the same for every row.** If it
is, it can almost always be written on columns: arithmetic, comparisons, `.dt` and `.str`, `np.where`.
The rest of this lesson takes the common reasons people reach for `apply` one at a time.
