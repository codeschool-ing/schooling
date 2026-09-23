---
title: `read_csv`, `dtype`, and the column that came in wrong
version: 2
---

```python
import pandas as pd
df = pd.read_csv("orders.csv")
```

```sh
id,customer,country,cents,paid_at
1,ana,BR,12990,2026-01-04
2,bruno,BR,,2026-01-05          ← one empty cell
```

```sh
>>> df.dtypes
id            int64
customer        str
country         str
cents       float64      ← not int64
paid_at         str
```

**One missing value made the whole column a float.** `cents` holds whole numbers of cents and
pandas read it as `float64`, because the classic integer type has no way to represent a gap.

Nothing warns about this. It surfaces later, as `12990.0` in a report or as a total that will not
compare equal to an integer.

## `dtype`, at read time

```python
df = pd.read_csv("orders.csv", dtype={"cents": "Int64"})
```

```sh
>>> df["cents"].tolist()
[12990, <NA>, 4500, 23000, 4500, 7800, 15000, 3200]
```

`Int64` with a **capital I** is the nullable integer type: whole numbers, with a real `<NA>` for
the gap. `int64` in lower case is the one that cannot hold a missing value.

Declaring `dtype` also stops pandas guessing, which is worth doing for any column whose type you
care about — an id that is all digits becomes an integer and loses its leading zeros otherwise.

## Dates

```python
df = pd.read_csv("orders.csv", parse_dates=["paid_at"])
```

```sh
>>> df["paid_at"].dtype
datetime64[us]
```

Without it, a date is a string and sorting it works by luck — ISO dates happen to sort correctly
as text and nothing else does.

## The arguments worth knowing

```python
pd.read_csv(path,
            sep=";",                # a European CSV
            decimal=",",            # and its decimal comma
            usecols=["id","cents"], # read two columns of forty
            nrows=1000,             # look before loading all of it
            na_values=["", "N/A", "-"])
```

`usecols` and `nrows` are the two that turn an unopenable file into a readable one. Read a
thousand rows first, look at them, then decide what to load.

## And the rest

```python
pd.read_json(path)          # records, or a nested structure
pd.read_excel(path)         # needs openpyxl
pd.read_parquet(path)       # typed, compressed, and much faster
pd.read_sql(query, conn)
```

All of them produce the same DataFrame, and everything after this section is the same whichever
one you used.
