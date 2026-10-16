---
title: Numbers that arrived as text
version: 1
---

**A numeric column that comes back as `str` has at least one value that is not a number, and
`pd.to_numeric` is how you find out which.** Lesson 10 met the case where the culprit was a known
placeholder. Here it is unknown, which is the usual case.

A meter report with the docks in service, typed in by a person:

```python
report = pd.Series(["14", "20", "12", "n/a", "17", "1O", "10"])
report.dtype
```

```
<StringDtype(na_value=nan)>
```

`astype(int)` fails on the first bad value and stops there, which tells you something is wrong and
not how much:

```python
report.astype(int)
```

```
ValueError: invalid literal for int() with base 10: 'n/a'
```

`pd.to_numeric` with `errors="coerce"` converts what it can and turns the rest into `NaN`, so you can
see every failure at once:

```python
docks = pd.to_numeric(report, errors="coerce")
docks.tolist(), report[docks.isna()].tolist()
```

```
([14.0, 20.0, 12.0, nan, 17.0, nan, 10.0], ['n/a', '1O'])
```

Two values failed: the placeholder, and `1O`, a one followed by the **letter** O, which looks like ten
and is not. **Never coerce and move on.** Coercing is a way to list the problems, and the second
line, the original text of the values that failed, is the list. Some are missing values and some are
typos with a right answer you can still recover; only a person reading them can tell which.

The dtype that comes out is `float64`, because `NaN` is a float. A column of whole numbers with
missing values has a better home, the last section of this lesson.
