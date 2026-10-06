---
title: When the summary and the detail disagree
version: 1
---

An aggregate is a copy, and every copy has to be kept in step with what it was copied from. Suppose a
till error is found: the third line of order 112406 was registered at R$ 10.00 too much, and the fact table
is corrected.

```sql
-- A correction reaches the fact table: one line of order 112406 was
-- registered at the wrong price, and is fixed.
UPDATE fact_sales SET net_cents = net_cents - 1000, gross_cents = gross_cents - 1000
WHERE order_id = 112406 AND line_no = 3;

SELECT (SELECT sum(net_cents) FROM fact_sales)      AS fact_total,
       (SELECT sum(net_cents) FROM agg_sales_month) AS aggregate_total;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < correction.sql
┌────────────┬─────────────────┐
│ fact_total │ aggregate_total │
│   int128   │     int128      │
├────────────┼─────────────────┤
│ 9574388852 │      9574389852 │
└────────────┴─────────────────┘
```

**The fact table now says 9,574,388,852 centavos. The aggregate still says 9,574,389,852.** One report
reads one and another report reads the other, and the manager now has two revenue figures, ten reais
apart, from the same warehouse. Nothing is broken. The aggregate is simply as old as its last rebuild.

The defences are the same as for any derived table:

- **Rebuild it after every change to what it is built from**, as part of the same load and in the same
  transaction where the database allows. Then the window in which the two disagree is zero.
- **Or let the database maintain it.** A materialised view that the database refreshes knows what it was
  built from. How fresh it is depends on the product: some refresh on every change, some on a schedule,
  some only when told.
- **Check it.** A load that finishes by comparing the aggregate's total with the fact table's, and fails
  if they differ, turns a silent disagreement into an error somebody sees.

**What an aggregate costs is the duty to keep it true.** Build one when a measured query
is too slow for the people waiting on it, and not before.
