---
title: Paging on the budget, with two windows
version: 1
---

**An alert on the symptom pages when customers are affected; an alert on the budget pages when they are
affected fast enough to matter.** The pattern Google's SRE workbook made common, and Microsoft's own
guidance on SLO alerts follows, uses two windows over the same burn rate:

- a **long window**, one hour, so that a brief blip does not page anybody;
- a **short window**, five minutes, so that the page stops as soon as the problem does;

and pages only when **both** burn faster than a threshold. 14.4 is the classic one for a one-hour window:
at that rate, a 30-day budget loses 2% in an hour. The shop keeps the number, on its weekly budget, as a
starting point to tune. Evaluated every five minutes over Thursday:

```kql
// two-windows.kql: the page condition, evaluated every 5 minutes: both windows burning over 14.4
let objective = 99.5;
let checkout = AppRequests | where Name == "POST /checkout";
range evaluated from datetime(2026-10-15 17:00) to datetime(2026-10-15 19:00) step 5m
| extend k = 1
| join kind=inner (checkout | extend k = 1) on k
| where TimeGenerated > evaluated - 1h and TimeGenerated <= evaluated
| summarize long_rate = 100.0 * countif(not(Success)) / count(),
    short_rate = 100.0 * countif(not(Success) and TimeGenerated > evaluated - 5m) / max_of(countif(TimeGenerated > evaluated - 5m), 1)
    by evaluated
| extend long_burn = round(long_rate / (100.0 - objective), 1), short_burn = round(short_rate / (100.0 - objective), 1)
| extend page = long_burn > 14.4 and short_burn > 14.4
| project evaluated, long_burn, short_burn, page
| order by evaluated asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < two-windows.kql
evaluated             long_burn  short_burn  page
2026-10-15T17:00:00Z  0.0        0.0         False
2026-10-15T17:05:00Z  0.0        0.0         False
2026-10-15T17:10:00Z  8.0        138.5       False
2026-10-15T17:15:00Z  23.8       163.6       True
2026-10-15T17:20:00Z  36.3       147.4       True
2026-10-15T17:25:00Z  44.1       81.8        True
2026-10-15T17:30:00Z  56.0       137.5       True
2026-10-15T17:35:00Z  73.4       181.0       True
2026-10-15T17:40:00Z  83.7       125.0       True
2026-10-15T17:45:00Z  96.6       133.3       True
2026-10-15T17:50:00Z  98.6       33.3        True
2026-10-15T17:55:00Z  96.7       0.0         False
2026-10-15T18:00:00Z  93.6       0.0         False
2026-10-15T18:05:00Z  99.0       0.0         False
2026-10-15T18:10:00Z  87.9       0.0         False
2026-10-15T18:15:00Z  72.0       0.0         False
2026-10-15T18:20:00Z  59.0       0.0         False
2026-10-15T18:25:00Z  49.8       0.0         False
2026-10-15T18:30:00Z  38.9       0.0         False
2026-10-15T18:35:00Z  21.7       0.0         False
2026-10-15T18:40:00Z  12.5       0.0         False
2026-10-15T18:45:00Z  4.6        17.4        False
2026-10-15T18:50:00Z  1.9        0.0         False
2026-10-15T18:55:00Z  2.0        0.0         False
2026-10-15T19:00:00Z  2.9        10.5        False
```

`range` makes one row per evaluation, and the join with a constant key `k` pairs each evaluation with
every checkout so that each can count its own windows; it is a brute-force way to evaluate a rule at many
moments, fine for a week of data and not how the real alert runs. **Read the `page` column against the
two burn columns.** The short window crossed 14.4 at 17:10, and the long one only at 17:15, so the page
came at 17:15, five minutes later than lesson 12's simple rule: the price of not paging on blips. At
17:55 the short window fell to zero while the long one was still near 97, and the page stopped: the
incident was over, and nobody needs to be woken for the hour's memory of it. At 18:45 a single failure
pushed the short window to 17.4 and the long one stayed at 4.6: no page, which is exactly the blip the long
window exists to ignore.

To put it into production, the query of the last evaluation becomes the query of a log search alert, as
in lesson 12, evaluated every five minutes; a second rule with a six-hour window and a lower threshold,
sent as a ticket rather than a page, catches the slow burns this one ignores.
