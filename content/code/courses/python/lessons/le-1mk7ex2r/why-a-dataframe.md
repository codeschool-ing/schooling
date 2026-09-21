---
title: A table as one object
version: 1
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
