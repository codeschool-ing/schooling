---
title: SettingWithCopyWarning, in the code you will read
version: 1
---

**Most pandas code online was written for pandas 1 and 2, and is full of `.copy()` calls and fixes
for a warning that pandas 3 no longer gives.** Reading that code needs the old rules; running it under
pandas 3 sometimes gives different answers, silently.

The three experiments of the last section, as a script, `cow.py`, saved in `pydata`:

```py
import pandas as pd

trips = pd.read_csv("trips.csv")
print(pd.__version__)
day = trips[trips["plan"] == "day"]
day["price"] = 12
print("A", "price" in day.columns, "price" in trips.columns)
trips["bike"][trips["bike"] == "electric"] = "e-bike"
print("B", (trips["bike"] == "e-bike").sum())
s = trips["plan"]
s.iloc[0] = "X"
print("C", trips.loc[0, "plan"])
```

Run under pandas 2.2.3, in the second environment lesson 3 made, and under this course's pandas:

```
(.venv) ana@lab:~/pydata$ ~/oldpandas/.venv/bin/python cow.py
/home/ana/pydata/cow.py:6: SettingWithCopyWarning: 
A value is trying to be set on a copy of a slice from a DataFrame.
Try using .loc[row_indexer,col_indexer] = value instead

See the caveats in the documentation: https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy
  day["price"] = 12
/home/ana/pydata/cow.py:8: FutureWarning: ChainedAssignmentError: behaviour will change in pandas 3.0!
You are setting values through chained assignment. Currently this works in certain cases, but when using Copy-on-Write (which will become the default behaviour in pandas 3.0) this will never work to update the original DataFrame or Series, because the intermediate object on which we are setting values will behave as a copy.
A typical example is when you are setting values in a column of a DataFrame, like:

df["col"][row_indexer] = value

Use `df.loc[row_indexer, "col"] = values` instead, to perform the assignment in a single step and ensure this keeps updating the original `df`.

See the caveats in the documentation: https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy

  trips["bike"][trips["bike"] == "electric"] = "e-bike"
/home/ana/pydata/cow.py:8: SettingWithCopyWarning: 
A value is trying to be set on a copy of a slice from a DataFrame

See the caveats in the documentation: https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy
  trips["bike"][trips["bike"] == "electric"] = "e-bike"
/home/ana/pydata/cow.py:11: SettingWithCopyWarning: 
A value is trying to be set on a copy of a slice from a DataFrame

See the caveats in the documentation: https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy
  s.iloc[0] = "X"
2.2.3
A True False
B 11655
C X
```

```
(.venv) ana@lab:~/pydata$ python cow.py
/home/ana/pydata/cow.py:8: ChainedAssignmentError: A value is being set on a copy of a DataFrame or Series through chained assignment.
Such chained assignment never works to update the original DataFrame or Series, because the intermediate object on which we are setting values always behaves as a copy (due to Copy-on-Write).

Try using '.loc[row_indexer, col_indexer] = value' instead, to perform the assignment in a single step.

See the documentation for a more detailed explanation: https://pandas.pydata.org/pandas-docs/stable/user_guide/copy_on_write.html#chained-assignment
  trips["bike"][trips["bike"] == "electric"] = "e-bike"
3.0.6
A True False
B 0
C day
```

Read the lines that start with `A`, `B` and `C` first, then the warnings around them.

**A**, a new column on a filtered table: the same answer in both, and pandas 2 warned anyway, with
`SettingWithCopyWarning`, because it could not be sure the filter had made a copy.

**B**, chained assignment: pandas 2 **changed** 11,655 bikes in `trips`, with a `FutureWarning`
announcing that it would stop; pandas 3 changed none and raised `ChainedAssignmentError`. Old code
that relied on this pattern loses its effect under pandas 3, and only the warning tells you.

**C**, writing to a selected Series: pandas 2 **changed the table**, `trips.loc[0, "plan"]` became
`X`, and warned; pandas 3 left it as `day`. This one prints no warning in pandas 3 at all, because under
Copy-on-Write it is not a mistake: it is a change to `s`. Code that counted on it to edit the table
now quietly does not.

## What to do with old code

- **Chained assignment, `df[col][mask] = v`**: rewrite as `df.loc[mask, col] = v`. It works in every
  version.
- **A selection modified to change the original**: the same rewrite, on the original table.
- **`.copy()` added to silence the old warning**: harmless in pandas 3 and no longer needed. Leave it
  if the code must also run on pandas 2.
- **Run old notebooks under pandas 3 and read every `ChainedAssignmentError`**: each one is a line
  whose effect has disappeared.
