---
title: Text is a type of its own
version: 1
---

**In pandas 3, a column of text has the dtype `str`, a type that holds only strings and missing
values.** In pandas 1 and 2 it had the dtype `object`, which means "any Python object", and could
hold strings, numbers and lists side by side. Lesson 3 saw the difference in two environments; this
section is what it changes in practice.

The notebook for this lesson:

```python
import numpy as np
import pandas as pd

trips = pd.read_csv("trips.csv")
trips["plan"].dtype, trips["plan"].dtype == object
```

```
(<StringDtype(na_value=nan)>, False)
```

The dtype prints as `StringDtype`, with `nan` as its missing value. It is **not** equal to `object`,
so code that found text columns by comparing with `object` finds nothing in pandas 3. Ask for the
type you mean:

```python
trips.select_dtypes("str").columns.tolist()
```

```
['started_at', 'ended_at', 'start_station', 'end_station', 'plan', 'bike']
```

`select_dtypes("object")` still returns these columns for now, with a warning that it will stop.
**Write `"str"` in new code**, and when old code selects `object` columns, read that warning.

## The `.str` accessor

A text column has a whole set of vectorised string methods behind `.str`, the text equivalent of
lesson 5's ufuncs:

```python
code = trips["start_station"]
code.str.len().unique(), code.str[1:].astype(int).max(), code.str.startswith("S0").mean().round(3)
```

```
(array([3]), np.int64(20), np.float64(0.526))
```

Every code is three characters long; dropping the `S` and converting gives a number, with 20 the
largest; and the share starting `S0` is the stations 1 to 9. `.str.lower`, `.str.contains`,
`.str.replace` and `.str.split` work the same way, element by element, with missing values left
missing instead of raising an error.

## Strings that are not quite the same

Text from people carries spaces and capitals that a computer treats as differences:

```python
messy = pd.Series([" Annual", "annual", "ANNUAL ", "day"])
messy.nunique(), messy.str.strip().str.lower().nunique()
```

```
(4, 2)
```

Four distinct values become two after `strip` and `lower`. **Normalise text before you count or
join on it**; lesson 14 is about what an unnormalised key does to a join.
