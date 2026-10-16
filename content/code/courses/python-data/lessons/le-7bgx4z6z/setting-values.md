---
title: Setting values in one step
version: 1
---

**To change some values of a table, select the rows and the column with one `loc` on the left of the
`=`.** One step, one set of brackets, on the table you mean to change: that is the whole rule, and it
is the same rule lesson 7 gave for NumPy.

The day passes cost R$ 12 and the annual plan works out at R$ 1.50 a trip. Record a price per trip,
in centavos so it stays exact:

```python
trips["price_cents"] = 150
trips.loc[trips["plan"] == "day", "price_cents"] = 1200
trips.groupby("plan")["price_cents"].first()
```

```
plan
annual     150
day       1200
Name: price_cents, dtype: int64
```

The first line creates the column with one value everywhere. The second selects the day-pass rows
and the `price_cents` column together and assigns into the table itself. The last line checks it,
using `groupby`, which is lesson 13's subject; here it only shows one value per plan.

## A new column from a condition

When the value depends on a condition with two outcomes, `numpy.where`, from lesson 5, builds the whole
column in one expression:

```python
import numpy as np

trips["return"] = np.where(trips["end_station"].isna(), "lost", "docked")
trips["return"].value_counts()
```

```
return
docked    33191
lost        146
Name: count, dtype: int64
```

## Building a modified copy without touching the original

`assign` returns a **new** DataFrame with columns added or replaced, and leaves the original alone.
It is the form to use in a chain of steps:

```python
cheap = trips.assign(price_reais=trips["price_cents"] / 100).loc[lambda d: d["price_reais"] < 5]
cheap.shape, "price_reais" in trips.columns
```

```
((23438, 10), False)
```

The `lambda d:` inside `loc` receives the DataFrame at that point in the chain, the one with the new
column, which the name `trips` would not have. `trips` itself gained no column. Whether to modify a
table or build a new one is a choice; the next section is about the cases where pandas makes it for
you.
