---
title: Materialised views, and an answer kept ready
version: 1
---

**A materialised view is a query whose result BigQuery stores and keeps up to date.** A plain view is
only a saved query: every time somebody reads it, BigQuery runs it against the base tables and bills
what it reads. A materialised view runs once, stores its result like a table, and from then on keeps
that result current as the base tables change. Quitanda's dashboards ask the same few questions every
hour, sales per district per day above all, and the answer to that question for last month has not
changed since last month. Recomputing it every hour from a million orders is the bill lessons 14 to 16
priced; reading a stored answer of a few hundred rows is almost nothing.

Everything about BigQuery in this section is from Google's documentation, "Introduction to materialized
views" and the pages on creating and managing them, and none of it was run. The next section does the
same idea by hand on DuckDB, and says plainly that it is the idea.

## One, written down

The view for the dashboards, in GoogleSQL, as it would be run and not run:

```sql
CREATE MATERIALIZED VIEW quitanda.daily_sales_mv
PARTITION BY dt
CLUSTER BY district
OPTIONS (enable_refresh = TRUE, refresh_interval_minutes = 60)
AS
SELECT dt, district, COUNT(*) AS orders, SUM(total_cents) AS sales
FROM quitanda.orders
GROUP BY dt, district;
```

**It is partitioned on the same column as its base table**, `dt`, which matters for the next two
paragraphs, and clustered by district, which matters for the dashboards that ask about one. It stores
one row per day and district: 480 rows for the sixty days of lesson 13, where the base table holds
1,245,118.

## Incremental refresh

**BigQuery maintains the view incrementally: when new rows arrive in the base table, it aggregates only
those rows and combines them with what it already stored.** A night's load of 16,359 orders updates
eight rows of the view from 16,359 rows of input, not from 1,245,118. That is the property that makes a
materialised view cheap to keep, and it is why the documentation restricts what a view may contain: an
incremental view must be made of operations that can be combined piece by piece. `COUNT`, `SUM`, `MIN`,
`MAX` and `AVG` qualify, because a sum of the new rows added to the old sum is the new sum. A median does
not, nor does anything that depends on the current time, and the documentation lists the functions and
joins an incremental view supports.

**`enable_refresh` and `refresh_interval_minutes` decide when the stored result catches up.** With
automatic refresh on, BigQuery refreshes the view in the background after its base table changes, and
`refresh_interval_minutes` sets the least time between two refreshes, so a table loaded every minute
does not cause a refresh every minute. **Between refreshes, a query still gets a current answer**:
BigQuery reads the stored result and adds the base-table rows that arrived since, the delta, so the
result is never stale unless the view was created with a `max_staleness` that allows it to be.

**Rows that change, rather than arrive, cost more.** A correction to an order of 15 September is not new
rows to add; it changes a sum already stored. The documentation describes BigQuery invalidating what the
change touched and recomputing it, and a view partitioned like its base table limits that to the
partitions changed. A view over a table that is rewritten every night gains nothing from being
incremental.

## What it costs

**Three lines, all of them familiar.** The view is stored like a table, at lesson 13's rates, and 480
rows of four columns cost nothing that the free 10 GiB would notice. Each refresh is a query, billed on
demand by the bytes it reads or on a reservation by the slots it uses; incremental refreshes read only
the new rows. And a query against the view is billed for the bytes it reads from the view, plus any
delta it has to read from the base table. The saving is the difference between reading a small stored
answer and reading the large table, every time the dashboard asks, and the section after next measures
it.
