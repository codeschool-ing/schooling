---
title: Conditions without apply
version: 1
---

**The most common `apply` in real notebooks is an `if` inside a function: a value goes into one of a
few bands.** pandas and NumPy both have vectorised forms of exactly that, and lesson 5 already met
the NumPy one.

Trips into bands by length, the way it is usually first written:

```python
trips["minutes"] = (trips["ended_at"] - trips["started_at"]).dt.total_seconds() / 60

def band(m):
    if pd.isna(m):
        return "lost"
    if m < 10:
        return "short"
    if m < 30:
        return "normal"
    return "long"

banded = trips["minutes"].apply(band)
banded.value_counts()
```

```
minutes
normal    21473
short      8686
long       3032
lost        146
Name: count, dtype: int64
```

The first test matters. `pd.isna(m)` catches the lost bikes before any comparison, because
`nan < 10` is `False` and a missing length would otherwise fall through every test and come out
`"long"`. That is lesson 5's trap again, and the same order of tests has to survive the rewrite.

`np.select` takes a list of conditions and a list of values, checked in order, with a default:

```python
selected = np.select(
    [trips["minutes"].isna(), trips["minutes"] < 10, trips["minutes"] < 30],
    ["lost", "short", "normal"],
    default="long",
)
(banded == selected).all()
```

```
np.True_
```

The same answer for every trip. `pd.cut` is the other way, when the bands are ranges of one number,
and it returns a categorical with the bands in order, which lesson 12 showed is what a chart and a
`groupby` want:

```python
cut = pd.cut(trips["minutes"], bins=[0, 10, 30, np.inf], right=False,
             labels=["short", "normal", "long"])
cut.value_counts(dropna=False)
```

```
minutes
normal    21473
short      8686
long       3032
NaN         146
Name: count, dtype: int64
```

`right=False` makes each band include its left edge, so a trip of exactly 10 minutes is `normal`, as
in the function. The lost bikes are `NaN` rather than `"lost"`: `cut` has no band for a missing
value, which is honest, and a label for them is one `cat.add_categories` and `fillna` away if a
report needs it.

The three timed:

```python
looped = %timeit -o -q trips["minutes"].apply(band)
sel = %timeit -o -q np.select([trips["minutes"].isna(), trips["minutes"] < 10, trips["minutes"] < 30], ["lost", "short", "normal"], default="long")
binned = %timeit -o -q pd.cut(trips["minutes"], bins=[0, 10, 30, np.inf], right=False, labels=["short", "normal", "long"])
round(looped.average * 1000, 1), round(sel.average * 1000, 1), round(binned.average * 1000, 1)
```

```
(9.9, 0.8, 1.1)
```

**`np.select` for conditions, `pd.cut` for ranges of one number**, and `apply` for neither. The
function stays useful as a specification: write it first if it helps you think, then check the
vectorised version against it, as `(banded == selected).all()` did.
