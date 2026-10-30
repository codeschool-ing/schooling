---
title: From the bill to the cause
version: 1
---

**A flagged day says that the bill moved; the next question is which meter.** The week before the 9th
against the week after, by meter category:

```kql
// which.kql: the week before the jump against the week after, by meter
CostDaily
| where Date between (datetime(2026-10-02) .. datetime(2026-10-15))
| extend week = iff(Date < datetime(2026-10-09), "before", "after")
| summarize cost = sum(Cost) by MeterCategory, week
| evaluate pivot(week, sum(cost))
| extend change = round(after - before, 2), before = round(before, 2), after = round(after, 2)
| order by change desc
| take 3
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < which.kql
MeterCategory  after  before  change
Log Analytics  89.34  28.12   61.22
SQL Database   105.0  104.55  0.45
Storage        22.21  21.97   0.24
```

`evaluate pivot()` turns the two `week` values into two columns, so the change can be one subtraction.
**Log Analytics went from 28 USD a week to 89**; everything else moved by less than a dollar. The step is
one meter, tripled.

From here the investigation is lessons 9 and 21 in order. In the workspace, the `Usage` table says which
table's ingestion grew on the 9th, and for the shop it would be `AppTraces`: the application's own log
lines. The activity log says what changed on the 8th or 9th, and an application setting changed by a
deployment is in it, as the pipeline's identity writing to `app-shop-api`. The cause, when the team that
owns the meter looked, was the one lesson 9 used as its example: **a log level set to `Debug` for an
investigation and never set back**, multiplying the traces each request writes.

The fix is a setting, and the lesson is the shape of the incident, which is lesson 15's applied to money.
**Detection**: the daily check flagged the first day. **Mitigation**: setting the log level back stops the
cost the next day. **Postmortem, blameless**: why could a debug level reach production with no expiry,
and why did nobody see the bill for a week? The shop's actions were a data collection rule
transformation that drops `Debug` traces in production, lesson 8's tool, and an expiry date on every
temporary log-level change. The cost of the week, about 60 USD, was the price of learning both.

That is where this course ends: the pipeline that ships, the monitoring that notices, the security that
holds, and the bill read as one more signal of what the system is doing.
