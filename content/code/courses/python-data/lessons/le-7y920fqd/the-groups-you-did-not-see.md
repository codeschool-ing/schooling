---
title: The groups you did not see
version: 1
---

**`groupby` drops rows whose key is missing, by default and without a word.** It also keeps or drops
empty categories depending on an argument. Both decide what a summary says, so both deserve a look.

Trips per end station, the obvious way:

```python
by_end = trips.groupby("end_station").size()
by_end.sum(), len(trips)
```

```
(np.int64(33191), 33337)
```

**The total is 146 short.** The lost bikes have no end station, so they belong to no group, and
`groupby` left them out. A report built on this table would quietly lose them. Ask for them:

```python
trips.groupby("end_station", dropna=False).size().tail(2)
```

```
end_station
S20    1982
NaN     146
dtype: int64
```

`dropna=False` makes the missing key a group of its own, `NaN`, and the totals add up again.

## Empty categories

With a categorical key, a category that has no rows can appear as a group of 0 or not, and the
argument is `observed`:

```python
bands = pd.Categorical(np.where(trips["minutes"] > 120, "very long", "normal"),
                       categories=["normal", "long", "very long"])
trips.groupby(bands, observed=False).size(), trips.groupby(bands, observed=True).size()
```

```
(normal       33336
 long             0
 very long        1
 dtype: int64,
 normal       33336
 very long        1
 dtype: int64)
```

No trip fell in the `long` band, because this code never assigns it. And the 146 lost bikes, with no
minutes at all, landed in `normal`: `nan > 120` is `False`, lesson 5's trap in a new place.
`observed=False` shows the band with 0, which is right for a report that must list every band;
`observed=True` shows only the bands that occur. pandas 3 defaults to `True`. **Choose it explicitly whenever the key is categorical**, so the
table says what you meant.

The NaN group and the empty category are two sides of one habit: **after a `groupby`, check that the
groups add up to the table.**
