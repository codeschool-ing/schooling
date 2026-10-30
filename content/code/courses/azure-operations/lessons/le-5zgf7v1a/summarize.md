---
title: Summarize, and the average that lies
version: 1
---

**`summarize` turns many rows into few: one per group, with the aggregates you ask for.** It is the
operator most questions end in. A query long enough to want reading twice goes in a file, sent with
`python3 kql.py < file.kql`:

```kql
// thursday.kql: how each route did on Thursday, in São Paulo's day
AppRequests
| where TimeGenerated between (datetime(2026-10-15 03:00) .. 1d)
| summarize requests = count(), failed = countif(not(Success)) by Name
| extend failed_pct = round(100.0 * failed / requests, 2)
| order by failed desc
```

```

```

`count()` and `countif()` aggregate per `Name`; `extend` adds a column computed from the others, and
`100.0` rather than `100` makes the division real rather than integer. Read the answer as an operator
would. Three routes failed at around one request in a thousand or less, which is the background noise
every service has. **Checkout failed 2.6% of the time, over the whole day.** Diluted across 24 hours, a
42-minute outage in which two checkouts in three failed looks like a bad day rather than an incident;
lesson 14 turns that into the difference between an error rate and an error budget.

## Percentiles

Lesson 8 warned that an average hides the slow requests. Here is the week, both ways:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | summarize avg = round(avg(DurationMs), 1), p50 = round(percentile(DurationMs, 50)), p95 = round(percentile(DurationMs, 95)), p99 = round(percentile(DurationMs, 99)) by Name'
Name            avg    p50   p95    p99
GET /cart       103.3  95.0  150.0  756.0
GET /products   103.2  95.0  150.0  154.0
POST /cart      104.1  95.0  150.0  940.0
POST /checkout  118.7  96.0  150.0  997.0
```

Every route's average is about 103 ms and its median about 95. The 95th percentile is 150 for all four:
95 requests in 100 finished within 150 ms. **The 99th is where the routes separate.** One request in a
hundred in `GET /cart`, `POST /cart` and checkout took close to a second, while `GET /products` stayed at
154 ms. Nothing in the averages says so. `percentile()` computes an estimate, very close for this many
rows, and the shop's latency objective in lesson 14 is written as a percentile for exactly this reason:
customers experience the slow tail, not the mean.
