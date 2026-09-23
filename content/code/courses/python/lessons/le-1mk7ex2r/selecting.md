---
title: Columns, `loc`, `iloc`, and the boolean mask
version: 2
---

```python
df["cents"]                 # one column → a Series
df[["customer", "cents"]]   # two columns → a DataFrame
```

The double brackets are a list of column names, not special syntax. Passing one name gives a
Series; passing a list gives a table.

## The mask, which is the idea

```python
df["cents"] > 10000
```

```sh
0     True
1    False
2    False
3     True
...
Name: cents, dtype: bool
```

Comparing a column gives **another column, of booleans**. Indexing a DataFrame with one keeps the
rows where it is `True`:

```python
df[df["cents"] > 10000]
```

That is the whole mechanism, and everything else is combinations of it:

```python
df[(df["country"] == "BR") & (df["cents"] > 5000)]
df[df["country"].isin(["BR", "PT"])]
df[~df["cents"].isna()]
```

**`&`, `|` and `~`, not `and`, `or` and `not`** — the Python keywords work on one truth value and
these work element by element. And the parentheses are required, because `&` binds tighter than
`>`.

## `loc` and `iloc`

```python
df.loc[0, "customer"]                      # by label
df.iloc[0, 1]                              # by position
df.loc[df["country"] == "BR", "cents"]     # a mask and a column
df.iloc[0:2, 1:3]                          # two rows, two columns, by position
```

`loc` takes **labels**: index values and column names. `iloc` takes **positions**: integers, like
a list.

## Why they are not the same thing

```python
us = df[df["country"] == "US"]
```

```sh
   id customer country    cents
3   4    diego      US  23000.0
6   7   gisele      US  15000.0
```

```sh
>>> us.iloc[0]["customer"]
'diego'
>>> us.loc[0]
KeyError: 0
```

**The filtered rows kept their original labels.** There is no row 0 any more, so `loc[0]` raises
and `iloc[0]` gives the first row. That `KeyError` is the most common confusion in the library,
and this is the whole of it.

`df.reset_index(drop=True)` renumbers them when you want the two to agree.

## Assigning

```python
df.loc[df["country"] == "BR", "cents"] = 0      # right
df[df["country"] == "BR"]["cents"] = 0          # wrong: a copy
```

The second one selects, gets a copy, and assigns into the copy — so `df` is unchanged. Measured
on pandas 3: it emits a `ChainedAssignmentError` warning and the four BR rows keep the values they
had. **Write the assignment through `loc`**, always; a warning is easy to miss in a notebook.
