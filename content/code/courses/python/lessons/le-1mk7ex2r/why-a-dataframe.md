---
title: A table as one object
version: 2
---

```python
total = 0
for row in rows:                       # a list of dicts
    if row["country"] == "BR":
        total += row["cents"]
```

```python
total = df.loc[df["country"] == "BR", "cents"].sum()
```

**A DataFrame is a table you can speak about as a whole.** A column is an object you can compare,
multiply, filter and group by, and the result of comparing one is another column — of booleans —
which is what the second line is doing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Comparing a whole column produces another whole column, of booleans, and that column is what selects the rows. The loop that would have done it one row at a time never appears.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"155\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the frame</text> <text x=\"60\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">country</text> <text x=\"150\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cents</text> <text x=\"240\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">rate</text> <rect x=\"20\" y=\"58\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"62\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BR</text> <rect x=\"110\" y=\"58\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"152\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12990</text> <rect x=\"200\" y=\"58\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"242\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.00</text> <rect x=\"20\" y=\"96\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"62\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">US</text> <rect x=\"110\" y=\"96\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"152\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">38000</text> <rect x=\"200\" y=\"96\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"242\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5.40</text> <rect x=\"20\" y=\"134\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"62\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BR</text> <rect x=\"110\" y=\"134\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"152\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11000</text> <rect x=\"200\" y=\"134\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"242\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.00</text> <rect x=\"20\" y=\"172\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"62\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PT</text> <rect x=\"110\" y=\"172\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"152\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9000</text> <rect x=\"200\" y=\"172\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"242\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6.20</text> <text x=\"400\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">df[&quot;country&quot;] == &quot;BR&quot;</text> <rect x=\"330\" y=\"58\" width=\"140\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"400\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">True</text> <rect x=\"330\" y=\"96\" width=\"140\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"400\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">False</text> <rect x=\"330\" y=\"134\" width=\"140\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"400\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">True</text> <rect x=\"330\" y=\"172\" width=\"140\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"400\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">False</text> <path d=\"M296 134 L324 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"600\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">.loc[…, &quot;cents&quot;].sum()</text> <rect x=\"530\" y=\"58\" width=\"170\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"615\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12990</text> <rect x=\"530\" y=\"96\" width=\"170\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"615\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11000</text> <path d=\"M476 134 L524 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"530\" y=\"142\" width=\"170\" height=\"2\" rx=\"0\" fill=\"var(--paper-dim)\"></rect> <rect x=\"530\" y=\"152\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"615\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">23990</text> <text x=\"360\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">The loop is still there — it is running in C, over the whole column, once.</text> <text x=\"360\" y=\"239\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">What is gone is the Python call per row, and that is the whole of the difference.</text> </svg>", "caption": "A column is an object you can compare, multiply, filter and group by — and the result of comparing one is another column."}
```

## What it costs to loop instead

```python
df["cents"] * df["rate"]                              # vectorised
df.apply(lambda r: r["cents"] * r["rate"], axis=1)    # a Python call per row
[r["cents"] * r["rate"] for _, r in df.iterrows()]    # a Series built per row
```

```sh
500,000 rows
  iterrows   11.200 s
  apply       2.771 s
  vector      0.002 s
```

**Five thousand times**, measured. The column operation runs in compiled code over a contiguous
block of memory; `iterrows` builds a `Series` object for every row before you touch it.

`apply(axis=1)` looks like the pandas way to do it and is not — it is a Python function call per
row with the object construction still there.

## The two types

```python
df["cents"]              # a Series  — one column, with an index
df[["customer","cents"]] # a DataFrame — two columns
```

A **Series** is one column: values plus an index. A **DataFrame** is a dict of Series sharing one
index. Almost everything you do returns one of the two, and knowing which you are holding
explains most error messages.

## The index

```sh
   id customer country    cents
3   4    diego      US  23000.0
6   7   gisele      US  15000.0
```

After filtering, the rows keep their **original** labels — 3 and 6, not 0 and 1. The index is not
a position, and that is the single most common surprise in pandas. The section on `loc` and
`iloc` is about exactly this.

## When not to use it

A hundred rows read once. A stream you process and discard. Anything where the answer is a single
pass and the data does not fit a table. `pandas` costs a dependency, some memory and a learning
curve, and below a few thousand rows a list of dicts is honestly fine.
