---
title: Several calculations at once, with names
version: 1
---

**`agg` applies several calculations to each group in one pass, and named aggregation lets you name
each result column.** It is how a summary table is built: one row per group, one column per
statistic, with names a reader understands.

```python
summary = trips.groupby("start_station").agg(
    trips=("trip_id", "size"),
    median_minutes=("minutes", "median"),
    electric_share=("bike", lambda b: (b == "electric").mean()),
)
summary.sort_values("trips", ascending=False).head(4).round(3)
```

```
               trips  median_minutes  electric_share
start_station                                       
S05             4154          14.117           0.355
S03             2728          14.158           0.341
S07             2636          14.217           0.355
S09             2597          14.267           0.339
```

Each argument is `new_name=(column, function)`. The function can be a name pandas knows, `"size"`,
`"median"`, `"mean"`, `"max"`, `"nunique"`, or any function that takes a Series and returns one value,
like the `lambda` here: the share of each station's trips made on an electric bike. The result is an
ordinary DataFrame, indexed by station, ready to sort.

The busiest station, `S05`, has roughly half as many trips again as the next. Its median trip and its
electric share are close to everyone else's, which says the station is busy, not different.

## A function name or a function

```python
trips.groupby("plan")["minutes"].agg(["mean", "median", "max"]).round(1)
```

```
        mean  median    max
plan                       
annual  14.1    12.4  108.0
day     22.6    19.9  175.1
```

A list of names gives one column per function, named after it. Passing the names as text is not only
shorter than passing `np.mean`: pandas has fast built-in versions of the common ones, and it uses them
when it recognises the name. A `lambda` is called once per group from Python, which is slower, and
lesson 17 is about how much.

## Counting by group is counting categories

```python
trips.groupby("bike").size(), trips["bike"].value_counts()
```

```
(bike
 classic     21682
 electric    11655
 dtype: int64,
 bike
 classic     21682
 electric    11655
 Name: count, dtype: int64)
```

The same counts. `value_counts` is the one-column special case of `groupby(...).size()`, sorted by
count instead of by group.
