---
title: Aggregates, the most denormalised table of all
version: 1
---

A dashboard that shows revenue by month, shop and department does not need 887,477 sale lines. It needs
their sums. Storing those sums is denormalisation taken all the way: instead of repeating an attribute
on every row, the rows themselves are collapsed into one per group.

```sql
-- A pre-summed table: revenue by month, shop and department.
CREATE TABLE agg_sales_month AS
SELECT d.year, d.month, f.shop_key, b.department,
       sum(f.quantity) AS books, sum(f.net_cents) AS net_cents
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_book b USING (book_key)
GROUP BY ALL;

SELECT (SELECT count(*) FROM fact_sales)      AS fact_rows,
       (SELECT count(*) FROM agg_sales_month) AS aggregate_rows,
       (SELECT sum(net_cents) FROM fact_sales)      AS fact_total,
       (SELECT sum(net_cents) FROM agg_sales_month) AS aggregate_total;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < agg.sql
┌───────────┬────────────────┬────────────┬─────────────────┐
│ fact_rows │ aggregate_rows │ fact_total │ aggregate_total │
│   int64   │     int64      │   int128   │     int128      │
├───────────┼────────────────┼────────────┼─────────────────┤
│    887477 │            616 │ 9574389852 │      9574389852 │
└───────────┴────────────────┴────────────┴─────────────────┘
```

**616 rows instead of 887,477**, and the same total to the centavo. A query for "revenue by month and
department" reads 616 rows instead of nearly 900 thousand, which matters a great deal when the fact table
has billions of rows, and somewhat less at this size.

Kimball calls these **aggregate fact tables**, and they follow three rules:

- **They are derived, never loaded from the source.** Built from the atomic fact table, so the two cannot
  disagree about the data.
- **They are an optimisation, not a model.** Nobody should have to know they exist to get a right answer.
  Some databases, given a materialised view, will rewrite a query against the fact table to read the
  aggregate instead; a report tool can do the same.
- **They keep the same conformed dimensions**, rolled up. `agg_sales_month` points at `shop_key` like
  `fact_sales` does, and its month and department are the same values `dim_date` and `dim_book` hold.

The third rule is why the aggregate is not a new kind of thing: it is a fact table at a coarser grain,
and lesson 4's grain sentence applies to it. "One row per month, shop and department." The next section
is about what happens when the table underneath changes.
