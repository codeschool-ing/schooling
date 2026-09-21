---
title: `groupby`, which is `uniq -c` with arithmetic
version: 1
---

```python
df.groupby("country")["cents"].sum()
```

```text
country
BR    23990.0
PT     9000.0
US    38000.0
```

**Split by a column, apply a function to each group, combine the results.** That is the whole
model, and it is the same one as `sort | uniq -c` from the terminal course with the counting
replaced by any arithmetic you like.

## Several aggregations at once

```python
df.groupby("country").agg(
    orders=("id", "count"),
    total=("cents", "sum"),
    avg=("cents", "mean"),
)
```

```text
         orders    total           avg
country
BR            4  23990.0   7996.666667
PT            2   9000.0   4500.000000
US            2  38000.0  19000.000000
```

The keyword form — `name=("column", "function")` — is the one to learn. It names the output
columns, which the older list form does not, and it reads like the table it produces.

## `count` counts what is present

`orders` above is `count` of `id`, which has no gaps. Had it been `count` of `cents`, BR would
say 3 rather than 4 — because one of its orders has no amount.

**That is a feature.** A `count` of the column you are summing tells you how much of each group
the sum is actually made of, and it is free.

## Grouping by more than one

```python
df.groupby(["country", "customer"])["cents"].sum()
```

The result has a two-level index. `.reset_index()` flattens it back into ordinary columns, which
is almost always what you want before writing it out or plotting it.

## `transform`, when the answer belongs beside each row

```python
df["country_total"] = df.groupby("country")["cents"].transform("sum")
```

`agg` gives you one row per group; `transform` gives you one row per **original row**, with the
group's answer repeated. That is how you compute "this order as a share of its country" without a
join.

## And the loop you are not writing

```python
totals = {}
for row in rows:
    totals.setdefault(row["country"], 0)
    totals[row["country"]] += row["cents"]
```

That is lesson 20's `defaultdict(int)`, and it is exactly right in plain Python. `groupby` is the
same idea when the data is already a table — and it gets you `count`, `mean`, `min`, `max` and
the rest without writing any of them.
