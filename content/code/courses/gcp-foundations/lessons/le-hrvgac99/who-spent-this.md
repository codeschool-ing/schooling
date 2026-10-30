---
title: Who spent this?
version: 1
---

**Three questions come up every month, and each is one query**: what the bill really is once credits are
subtracted, which team spent it, and what was spent by nobody in particular. All three run against the month
the previous section made, in `~/gcp/export`.

## What the bill really is

`credits` is a list on each row, so the credits of a row are added up inside the row first, with a small query
over its own list, and only then summed across rows. Save as `net.sql`:

```sql
SELECT service.description AS service,
       round(sum(cost), 2) AS gross,
       round(sum((SELECT coalesce(sum(c.amount), 0) FROM unnest(credits) AS t(c))), 2) AS credits,
       round(sum(cost) + sum((SELECT coalesce(sum(c.amount), 0) FROM unnest(credits) AS t(c))), 2) AS net
FROM export
GROUP BY service
ORDER BY net DESC
```

```
ana@laptop:~/gcp/export$ python3 ask.py net.sql
┌────────────────┬────────┬─────────┬────────┐
│    service     │ gross  │ credits │  net   │
│    varchar     │ double │ double  │ double │
├────────────────┼────────┼─────────┼────────┤
│ Compute Engine │ 430.01 │  -66.53 │ 363.48 │
│ Cloud Pub/Sub  │  38.01 │   -1.15 │  36.86 │
│ Networking     │   1.03 │     0.0 │   1.03 │
└────────────────┴────────┴─────────┴────────┘
```

**The net is what the invoice charges; the gross is what the usage would have cost at list price.** Compute
Engine's credits are the sustained use discount of lesson 13, Pub/Sub's the free tier. A report that sums
`cost` alone overstates the bill by every discount the account earned, and the size of that mistake moves
from month to month as discounts start and stop.

## Which team spent it

A label is an entry in a list, so the `team` label is read out of the list with the same kind of small query,
and a row without one gets a name that says so rather than an empty cell. Save as `teams.sql`:

```sql
SELECT coalesce((SELECT l.value FROM unnest(labels) AS t(l) WHERE l.key = 'team'), '(no team)') AS team,
       project.id AS project,
       round(sum(cost), 2) AS gross
FROM export
GROUP BY team, project
ORDER BY gross DESC
```

```
ana@laptop:~/gcp/export$ python3 ask.py teams.sql
┌───────────┬─────────────────┬────────┐
│   team    │     project     │ gross  │
│  varchar  │     varchar     │ double │
├───────────┼─────────────────┼────────┤
│ planner   │ planner-prod    │ 380.19 │
│ data      │ planner-dev     │  38.01 │
│ planner   │ planner-staging │  33.37 │
│ (no team) │ planner-dev     │  16.45 │
│ network   │ planner-network │   1.03 │
└───────────┴─────────────────┴────────┘
```

This is lesson 3's labels paying for themselves. The planner team's two projects are told apart by
`project`, and the data team's Pub/Sub sits in `planner-dev` beside a line that has no team at all.

## What nobody spent

**Unlabelled cost is the first thing to read**, because it is the cost nobody will answer for. Save as
`forgotten.sql`:

```sql
SELECT project.id AS project,
       sku.description AS sku,
       round(sum(usage.amount)) AS hours,
       round(sum(cost), 2) AS gross
FROM export
WHERE len(labels) = 0
GROUP BY project, sku
```

```
ana@laptop:~/gcp/export$ python3 ask.py forgotten.sql
┌─────────────┬───────────────────────────────────────┬────────┬────────┐
│   project   │                  sku                  │ hours  │ gross  │
│   varchar   │                varchar                │ double │ double │
├─────────────┼───────────────────────────────────────┼────────┼────────┤
│ planner-dev │ N2 Instance Core running in Sao Paulo │  366.0 │  16.45 │
└─────────────┴───────────────────────────────────────┴────────┴────────┘
```

About twelve vCPU hours a day, all month, in the development project, on a machine with no label: the first
item of lesson 13's list, *something is running that nobody remembers*. The query does not say which machine
it is, because the standard export has no resource names; the detailed export does, and so does looking in
`planner-dev` for an instance with no `team` label. Sixteen dollars is small. The same query against a real
account with forty projects is how the large ones are found.

## The same questions in BigQuery

DuckDB and BigQuery both speak SQL with nested rows, and differ in a few spellings. Against a real export,
`net.sql` reads like this, where the table's name carries the billing account's id. **This was not run**: there
is no BigQuery in the lab.

```sql
SELECT service.description AS service,
       ROUND(SUM(cost), 2) AS gross,
       ROUND(SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) AS c), 0)), 2) AS credits,
       ROUND(SUM(cost) + SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) AS c), 0)), 2) AS net
FROM `planner-logs.billing_export.gcp_billing_export_v1_012345_6789AB_CDEF01`
WHERE invoice.month = '202610'
GROUP BY service
ORDER BY net DESC
```

Three differences: `UNNEST(credits) AS c` names the element directly where DuckDB names a table and a column,
`IFNULL` is BigQuery's word for `coalesce` (which it also accepts), and `len(labels)` would be
`ARRAY_LENGTH(labels)`. The `WHERE` on `invoice.month` is the one addition that matters with real data: **the
export keeps every month**, and a query without a month in it sums all of them. And because BigQuery bills
queries by the bytes they read, the planner's finance people run these against one month at a time for the
second reason too.
