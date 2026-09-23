---
title: Five minutes before any analysis
version: 2
---

```python
df.head(3)        # what does a row look like
df.shape          # (8, 5)
df.info()         # types, and how many values are not missing
df.describe()     # ranges, for the numeric columns
df["country"].value_counts()
```

**Run all five before writing anything else.** They take a minute and they catch the things that
otherwise surface as a wrong number three hours later.

## `info()` is the one that earns its place

```sh
 #   Column    Non-Null Count  Dtype
---  ------    --------------  -----
 0   id        8 non-null      int64
 1   customer  8 non-null      str
 2   country   8 non-null      str
 3   cents     7 non-null      float64
 4   paid_at   7 non-null      str
```

Two facts per column: **the type**, and **how many values are actually there**. `cents` is a
float and has seven of eight — both of which are the previous section's problem, visible in one
line.

## `describe()`

```sh
            id         cents
count  8.00000      7.000000
mean   4.50000  10141.428571
min    1.00000   3200.000000
max    8.00000  23000.000000
```

Numeric columns only, by default. Read `count` first: 7 against 8 is the gap again. Then `min`
and `max`, which is where a negative price or a date in 1970 shows up.

`df.describe(include="all")` adds the text columns, with `unique` and `top` instead of `mean`.

## `value_counts()`

```sh
country
BR    4
PT    2
US    2
```

For any column with a small number of distinct values. It is where `"BR"`, `"br"` and `" BR"`
appear as three countries, and where the category nobody knew existed shows up.

```python
df["country"].value_counts(dropna=False)     # counts the missing ones too
```

`dropna=False` is worth making a habit: the default hides exactly the rows you are about to be
surprised by.

## And one more

```python
df["id"].is_unique          # True
df.duplicated().sum()       # how many rows are exact copies
```

Two questions that are cheap to ask and expensive to discover the answer to later.
