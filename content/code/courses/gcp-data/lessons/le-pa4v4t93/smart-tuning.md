---
title: Smart tuning, and the query that reads the view instead
version: 1
---

**A materialised view saves money only if queries read it, and BigQuery can make them read it without
being asked.** Google's documentation calls it **smart tuning**: when a query against the base table can
be answered from a materialised view, BigQuery rewrites the query to read the view, and the dashboard
that still says `FROM quitanda.orders` is served from `daily_sales_mv`. Nobody has to change a report, and
nobody who writes a new one has to know the view exists. None of it can be run here; the measurement
below is of the bytes each version would be billed, computed with lesson 16's `bqbill.py`.

## When a query can be rewritten

**A query can be answered from the view when everything it needs is in the view.** The dashboard's
question, sales per district for September, groups by columns the view groups by, filters on a column
the view has, and sums a column the view already sums. A query that asks for sales per store cannot be
rewritten: the view has no `store_id`, and an aggregate cannot be taken apart again. A query that asks
for the average order value can, in principle, since an average is a sum over a count and the view has
both; the documentation lists which aggregates and filters the rewrite handles, and its rule is the one
any reader can apply: the view must hold every column the query touches, at a grain no coarser than the
query asks for.

## The two bills, side by side

**Without the view, the dashboard reads three columns of every order; with it, three columns of 480
rows.** `bqbill.py` works on any folder under `warehouse/` with a `dt`, and `daily_sales` is one:

```
ana@laptop:~/gcp$ python3 bqbill.py orders dt,district,total_cents
3 columns of orders, 0001-01-01 to 9999-12-31
  bytes processed      31,443,638
  bytes billed         31,457,280   0.000322 USD
ana@laptop:~/gcp$ python3 bqbill.py daily_sales dt,district,sales
3 columns of daily_sales, 0001-01-01 to 9999-12-31
  bytes processed          12,120
  bytes billed         10,485,760   0.000107 USD
```

**31,443,638 bytes processed against 12,120.** On Quitanda's table both are billed at least the 10 MB
minimum, and the base table's query costs three times the view's. The 12,120 bytes are 480 rows of
`dt`, `sales` and the district's name, which is the whole aggregate; the base table's 31 MB are every
order's `dt`, `district` and `total_cents`. **At a thousand times Quitanda's size, the base table's query
would be about 30 GB a run and the view's about 12 MB**, because the view grows with the number of days
and districts and not with the number of orders. A dashboard refreshing every hour reads the view 720
times a month for the cost of a handful of base-table scans.

**That is also the honest limit of the comparison.** The view's query, in BigQuery, would read the delta
too, the base rows that arrived since the last refresh; a refresh every hour after an hourly load keeps
that delta to about an hour of orders. And the refreshes themselves are queries: at one a night, each
reading one day of orders, they add a day's bytes to the month for every day of it.

## What breaks the rewrite

**A query the view cannot answer is run against the base table, silently, and billed as such.** There
is no error and no warning on the bill: the query just costs what it would have cost without the view.
So the habit of lesson 16 applies here too: read what the job actually did. In BigQuery the job's
statistics say whether a materialised view was used, and the execution graph reads from the view rather
than from the table when it was. A dashboard that adds one column the view does not have has quietly
gone back to scanning every order.
