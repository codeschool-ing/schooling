---
title: Durations, and the time zone a time is in
version: 1
---

**Subtracting two datetimes gives a timedelta, a length of time, with its own accessor.** The length
of every trip is one line:

```python
trips["duration"] = trips["ended_at"] - trips["started_at"]
trips["duration"].dtype, trips["duration"].head(2).tolist()
```

```
(dtype('<m8[us]'),
 [Timedelta('0 days 00:34:25'), Timedelta('0 days 00:16:52')])
```

```python
minutes = trips["duration"].dt.total_seconds() / 60
minutes.describe().round(1)
```

```
count    33191.0
mean        16.7
std         10.1
min          1.8
25%          9.8
50%         14.2
75%         20.7
max        175.1
Name: duration, dtype: float64
```

`total_seconds()` turns each length into a number, and dividing by 60 gives minutes. The median trip is
about a quarter of an hour, and the longest lasted nearly three. The count is 33,191: the lost bikes
have no end, so no duration, and `describe` skips them.

## Time zones

A datetime with no time zone is **naive**: it says 12:22 without saying where. Recife is three hours
behind UTC, and a system that stores times in UTC, as most servers do, will disagree with these files by
three hours. Attach the zone the times were recorded in, and conversion becomes exact:

```python
local = trips["started_at"].dt.tz_localize("America/Recife")
local.iloc[0], local.dt.tz_convert("UTC").iloc[0]
```

```
(Timestamp('2025-01-01 12:22:38-0300', tz='America/Recife'),
 Timestamp('2025-01-01 15:22:38+0000', tz='UTC'))
```

`tz_localize` states which zone a naive time was in; `tz_convert` expresses the same moment in another
zone. The moment does not change, only the clock it is read on. Recife has had no daylight saving
since 2000, so its offset is a fixed `-03:00`; São Paulo had daylight saving until 2019, and a
naive time there can be ambiguous or not exist at all on the night the clocks changed, which is the
best reason to keep times in UTC and convert only to display them.

**Never compare a naive column with an aware one**: pandas refuses, and the refusal is right, because
it cannot know which zone the naive one meant.
