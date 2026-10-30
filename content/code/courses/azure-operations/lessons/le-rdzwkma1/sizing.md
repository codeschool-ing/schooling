---
title: Sizing a commitment to the floor
version: 1
---

**A commitment should cover the usage that is always there, and nothing above it.** The shop's order
exports run on a scale set of `Standard_D4s_v5` workers that grows in business hours. A month of its
instance count, one row per hour, generated in the shape the scale set's metrics would give and saying
so, goes in `usage.kql`:

```kql
// usage.kql: thirty days of the export workers' scale set, one row per hour, in instances running
.set-or-replace WorkerHours <|
range TimeGenerated from datetime(2026-09-19 03:00) to datetime(2026-10-19 02:00) step 1h
| extend hour = hourofday(TimeGenerated - 3h), weekday = dayofweek(TimeGenerated - 3h) / 1d
| extend busy = hour between (8 .. 19) and weekday between (1 .. 5)
| extend Instances = iff(busy, 4, 2) + iff(busy and abs(hash(TimeGenerated, 10)) < 3, 2, 0)
| project TimeGenerated, Instances, VmSize = "Standard_D4s_v5"
```

Two instances run at all times; on weekdays from 08:00 to 19:00 in São Paulo it runs four, and on a few of
those hours six. Load it and look at the shape before any arithmetic:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'WorkerHours | summarize hours = count(), min = min(Instances), p10 = percentile(Instances, 10), median = percentile(Instances, 50), max = max(Instances), avg = round(avg(Instances), 2)'
hours  min  p10  median  max  avg
720    2    2    2       6    2.87
ana@laptop:~/azure/kusto$ python3 kql.py 'WorkerHours | summarize hours = count() by Instances | order by Instances asc'
Instances  hours
2          480
4          166
6          74
```

**The floor is 2**: the minimum and the 10th percentile agree, and two thirds of the month's 720 hours ran
exactly two. The average, 2.87, is the number people reach for, and it is the wrong one: a commitment of
three would sit partly unused in 480 hours of the month. The median says the same as the floor here; on
spikier usage the 10th percentile is the safer measure than the minimum, which one unusual quiet hour can
pull down.

The data this lesson generates is a month. A real decision uses longer, three months at least, so that a seasonal low is in it. It also asks whether the workload will exist for the length of the term: a
three-year commitment on something being replaced next spring is a bill for something switched off.
