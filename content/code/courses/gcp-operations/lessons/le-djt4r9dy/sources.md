---
title: Where a daily number for the bill comes from
version: 1
---

Lesson 14's alerts watch what customers feel. Some incidents customers never feel: a debug level left on that writes
forty gibibytes of logs a day, a load test nobody stopped, a stolen credential running machines in a region the team
never uses. The service works, and **the bill is the only thing that moves**. It moves at the end of the month unless
something reads it every day. This lesson makes the bill a signal like any other, and the first question is where a
daily number comes from. Neither source runs here: both need a billing account.

## The billing export, by day

Lesson 23's export has a row per resource per SKU per hour of use, so the daily cost of each service is one query. In
BigQuery, against the standard export table, with the dataset and table names your export was given:

```sql
SELECT DATE(usage_start_time) AS day, service.description AS service, ROUND(SUM(cost), 2) AS usd
FROM `planner-billing.billing_export.gcp_billing_export_v1_XXXXXX_XXXXXX_XXXXXX`
WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 DAY)
GROUP BY day, service
ORDER BY day, service
```

**The export is not live.** Lines arrive after the usage that produced them, and a day's total keeps growing for a
while after the day has ended, so today and yesterday are always incomplete. A detector that compared an unfinished
today with complete days before it would report a drop every morning. The program in the next section judges each day
against the fourteen before it, and it should be run on days that are finished.

Scheduled every morning, as a BigQuery scheduled query or a small job, the query writes the 45 rows per service that
the next section reads, as a CSV file.

## The budget's stream, as a pace

Lesson 24's topic is the other source. Each update carries `costAmount`, the spend so far this period, and updates
arrive at regular intervals. Two updates a day apart give the day's spend; a function that keeps the last one it saw
can compare that difference with the usual. It is coarser than the export, since it is one number for the whole
budget, but it needs no BigQuery and it arrives on the topic you already have a function listening to.

| source | grain | delay | needs |
|---|---|---|---|
| billing export | service, SKU, project, label, by hour | hours, and a day keeps growing | BigQuery and a scheduled query |
| budget topic | one number per budget | the same lag as the budget | the budget and a function |

**The export says which service moved; the topic says that something moved.** The shop runs the export every morning
for the detail and lets the forecast rule of lesson 24 catch a month that is going wrong between two mornings.
