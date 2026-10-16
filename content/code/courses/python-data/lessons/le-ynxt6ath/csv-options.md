---
title: A CSV is text, and read_csv guesses
version: 1
---

**A CSV file carries no types: every value in it is text, and `read_csv` decides what each column
is by looking at it.** Most of the time it guesses well. The options of `read_csv` exist for the
times it does not, and for reading less than the whole file.

This lesson's notebook reads, writes and reads back, in `pydata`:

```python
import os
import sqlite3

import pandas as pd

trips = pd.read_csv("trips.csv")
trips.dtypes.value_counts()
```

```
str      6
int64    1
Name: count, dtype: int64
```

One integer column and six of text, as lesson 9 found. The guess is made per column from all its
values: a column of whole numbers is `int64`, one with a decimal point or an empty field is
`float64`, and anything else is `str`.

## Reading less

```python
small = pd.read_csv("trips.csv", usecols=["trip_id", "plan", "bike"], nrows=1000)
small.shape, small.columns.tolist()
```

```
((1000, 3), ['trip_id', 'plan', 'bike'])
```

`usecols` reads only the named columns and `nrows` stops after that many rows. On a file of a few
megabytes it makes no difference; on one of a few gigabytes it is the difference between loading and
not, and lesson 20 comes back to it.

## Saying what the types are

```python
typed = pd.read_csv("trips.csv", dtype={"trip_id": "int32"}, parse_dates=["started_at", "ended_at"])
typed.dtypes
```

```
trip_id                   int32
started_at       datetime64[us]
ended_at         datetime64[us]
start_station               str
end_station                 str
plan                        str
bike                        str
dtype: object
```

`dtype` fixes the type of a column instead of letting `read_csv` choose: here a smaller integer.
`parse_dates` turns text columns into **datetimes**, the type lesson 12 is about. The empty
`ended_at` of the 146 bikes that never came back became `NaT`, "not a time", which is a datetime's
`NaN`.

## What counts as missing

`read_csv` reads an empty field, `NA`, `NaN`, `null` and a dozen similar spellings as missing. A file
that marks a missing value some other way has to say so:

```python
with open("readings.csv", "w") as f:
    f.write("station,docks\nS01,14\nS02,-\nS03,12\n")
pd.read_csv("readings.csv").dtypes["docks"], pd.read_csv("readings.csv", na_values=["-"])["docks"].tolist()
```

```
(<StringDtype(na_value=nan)>, [14.0, nan, 12.0])
```

With the dash unrecognised, the whole column was read as text, because `-` is not a number; told
that `-` means missing, `read_csv` reads numbers and a `NaN`. **A numeric column that comes back as
`str` almost always has a placeholder like this somewhere in it**, and `value_counts` on that column
finds it.
