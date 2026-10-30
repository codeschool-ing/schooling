---
title: Bins: the shape of an incident in time
version: 1
---

**`bin()` rounds a value down to a multiple of a size, and grouping by a binned timestamp is how a
query draws time.** Ten-minute bins over Thursday afternoon, checkout only:

```kql
// window.kql: checkout, five minutes at a time, around Thursday afternoon
AppRequests
| where Name == "POST /checkout"
| where TimeGenerated between (datetime(2026-10-15 16:50) .. datetime(2026-10-15 18:00))
| summarize requests = count(), failed = countif(not(Success)), p95 = percentile(DurationMs, 95)
    by bin(TimeGenerated, 10m)
| order by TimeGenerated asc
```

```

```

Read down the table and the incident has a shape: a normal 16:50, failures starting inside the 17:00
bin, two in three checkouts failing for the next half hour, and a normal 17:50 again. The 95th percentile
says the same thing more loudly: from 150 ms to more than three seconds and back. **Two columns, failed
and p95, are the two signals lessons 12 and 14 alert on**, and they moved together here because the
failures were timeouts. They will not always: a fast error, a 500 returned in 20 ms, moves the first and
lowers the second.

The size of the bin is a choice with a cost either way. Ten minutes made the start fuzzy: the first bin
mixes normal minutes with failing ones. One-minute bins would show the start to the minute and turn into
a long table, which in a workspace becomes a chart with `render timechart`. The emulator has no chart,
which is why this course reads bins as tables; a workspace draws the same rows as a line.

Two details matter on real data and not on this tidy week. **Empty bins do not appear**: a minute with
no requests at all is not a row with zero, it is no row, and a chart of it draws a line straight across
the gap. `make-series` fills those with a default, which lesson 25 uses. And bins are aligned to UTC, so
a one-day bin is a UTC day, as lesson 9's size table showed.
