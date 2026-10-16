---
title: crosstab, counts of two categories
version: 1
---

**`pd.crosstab` counts how often each pair of values of two columns occurs, as a grid.** It is the
shortest way to ask whether two categories go together, and with `normalize` it answers in shares.

```python
pd.crosstab(trips["plan"], trips["bike"])
```

```
bike    classic  electric
plan                     
annual    15226      8212
day        6456      3443
```

The same counts a `groupby(["plan", "bike"]).size().unstack()` would give, in one call that reads like
the question. The raw counts mostly repeat that there are more subscribers than day passes. The
question is whether the two kinds of rider choose bikes differently, and that needs each row as
shares:

```python
pd.crosstab(trips["plan"], trips["bike"], normalize="index").round(3)
```

```
bike    classic  electric
plan                     
annual    0.650     0.350
day       0.652     0.348
```

`normalize="index"` divides each row by its total, so each row adds to 1. Both plans take an electric
bike about 35% of the time: **plan and bike are independent here**, which is what the generator
did, choosing the bike without looking at the plan. `normalize="columns"` would divide by column
totals instead, answering "of the electric trips, what share were day passes", and `normalize=True`
divides by the grand total.

**Which way to normalise is the question you are asking.** "Do day riders prefer electric bikes?"
compares the rows, so it divides by the row totals; "who rides the electric bikes?" compares the
columns. The two tables come from the same counts and answer different questions.

`margins=True` adds the totals:

```python
pd.crosstab(trips["weekday"], trips["plan"], margins=True).loc[order + ["All"]]
```

```
plan       annual   day    All
weekday                       
Monday       4050  1344   5394
Tuesday      3954  1364   5318
Wednesday    4157  1316   5473
Thursday     3880  1329   5209
Friday       4087  1266   5353
Saturday     1543  1572   3115
Sunday       1767  1708   3475
All         23438  9899  33337
```

The weekday-by-plan table of lesson 13, with its totals, and the same Saturday and Sunday where the
day passes outnumber or nearly match the subscribers.
