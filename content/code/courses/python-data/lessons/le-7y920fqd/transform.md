---
title: transform, a group's answer for every row
version: 1
---

**An aggregation returns one row per group; `transform` returns one value per original row, the
group's answer broadcast back.** It is how a row is compared with its own group: this trip against the
station's typical trip, this day against its month.

```python
station_median = trips.groupby("start_station")["minutes"].transform("median")
station_median.shape, trips["minutes"].shape
```

```
((33337,), (33337,))
```

Same length as the table, so it can sit beside it as a column. Each trip now carries the median length
of trips from its own start station, and dividing gives a ratio that means the same thing at every
station:

```python
trips["vs_station"] = trips["minutes"] / station_median
trips.loc[trips["vs_station"] > 5, ["start_station", "minutes", "vs_station"]].round(1).head(4)
```

```
     start_station  minutes  vs_station
749            S05     71.1         5.0
1337           S05     72.6         5.1
1523           S05     83.3         5.9
2024           S14     85.4         6.1
```

Trips more than five times their station's median. A rule written against the whole table, "more than
70 minutes", would treat every station alike; a rule written against the group adapts to each one.

## Shares within a group

The other common use is a share: each part over its group's total.

```python
daily = trips.groupby([trips["started_at"].dt.date, "plan"]).size().rename("trips").reset_index()
daily["share_of_day"] = daily["trips"] / daily.groupby("started_at")["trips"].transform("sum")
daily.head(4).round(3)
```

```
   started_at    plan  trips  share_of_day
0  2025-01-01  annual     85         0.802
1  2025-01-01     day     21         0.198
2  2025-01-02  annual     82         0.759
3  2025-01-02     day     26         0.241
```

`daily` has one row per day and plan. `transform("sum")` puts each day's total on both of its rows,
and dividing gives each plan's share of its day. The two shares of a day add up to 1, whatever the
day's size.
