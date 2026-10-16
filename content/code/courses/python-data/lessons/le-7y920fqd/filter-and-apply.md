---
title: filter, and apply for everything else
version: 1
---

**`filter` keeps or drops whole groups by a condition on the group.** It answers questions like "the
trips from stations with fewer than 1,000 trips", where the condition is about the station, not the
trip:

```python
quiet = trips.groupby("start_station").filter(lambda g: len(g) < 1000)
quiet["start_station"].unique().tolist(), len(quiet)
```

```
(['S16', 'S12', 'S06', 'S02', 'S19'], 3834)
```

The function receives each group as a DataFrame and returns `True` to keep it. The result is the
original rows of the kept groups, not one row per group.

## apply, when nothing else fits

`apply` passes each group, as a DataFrame, to any function, and combines whatever comes back. It can
do things the other methods cannot, such as returning several rows per group. The three longest trips
from each of two stations:

```python
some = trips[trips["start_station"].isin(["S01", "S02"])]
some.groupby("start_station")[["trip_id", "minutes"]].apply(lambda g: g.nlargest(3, "minutes")).round(1)
```

```
                     trip_id  minutes
start_station                        
S01           16380    16381     99.0
              32271    32272     64.9
              6415      6416     59.3
S02           2153      2154     83.9
              13176    13177     65.6
              12811    12812     63.9
```

The result keeps the group key as the outer index level and each row's original label inside it.
Selecting the columns before `apply` says exactly which columns each group receives.

**`apply` is the slowest path in `groupby`**: it calls Python once per group, where `agg` and
`transform` with named functions run in compiled code. Use it when the calculation needs the whole
group at once, and nowhere else. Lesson 17 measures the difference.
