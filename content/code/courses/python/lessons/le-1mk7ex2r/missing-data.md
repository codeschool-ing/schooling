---
title: `NaN`, and the mean that quietly skipped it
version: 1
---

```sh
>>> c = df["cents"]
>>> len(c), c.count(), c.isna().sum()
8, 7, 1
```

```sh
>>> c.mean()
10141.43      ← the sum divided by 7
>>> c.sum() / len(c)
8873.75       ← the sum divided by 8
```

**Fourteen per cent apart, and nothing said so.** `mean()` skips missing values and divides by
what is left, which is the right default and is not what somebody reading "average order value"
assumes.

`sum()` treats them as zero. `count()` counts what is present. Every aggregation has made a
choice on your behalf, and the choices are not the same.

## `NaN` compares false with everything

```sh
>>> np.nan == np.nan
False
>>> (df["cents"] > 0).sum()
7        ← of 8 rows
```

So a mask silently excludes the missing rows, whichever way the comparison points. `x != x` is
the old trick for detecting one, and `isna()` is what to write:

```python
df["cents"].isna()          # True where it is missing
df["cents"].notna()
df["cents"].isna().sum()    # how many
```

## `fillna`

```python
df["cents"].fillna(0)                        # a zero is a real zero
df["country"].fillna("unknown")
df["cents"].fillna(df["cents"].mean())       # the mean of what is there
df["reading"].ffill()                        # carry the last value forward
```

**Each of those is a different claim about the world.** A missing price filled with zero says the
order was free. A missing sensor reading carried forward says nothing changed. Neither is wrong,
and neither is safe to do without saying why.

## `dropna`

```python
df.dropna()                          # any row with ANY gap: 6 of 8 survive
df.dropna(subset=["cents"])          # only where cents is missing: 7 of 8
df.dropna(axis=1)                    # drop the columns instead
```

The bare form is the trap. In the file here it dropped two rows: one missing `cents` and one
missing `paid_at` — and the second had nothing to do with the analysis.

**Always pass `subset`.**

## The rule

Decide per column, before you aggregate, and write it down:

```python
df["cents"] = df["cents"].fillna(0)      # unpaid orders count as zero
df = df.dropna(subset=["country"])       # a row with no country cannot be grouped
```

Two lines and a comment each. The alternative is a number that is fourteen per cent wrong and
looks exactly like a number that is right.
