---
title: A second database, built to be read
version: 2
---

A **data warehouse** is a database whose only job is to answer questions about the business. It is
loaded from the operational systems, on a schedule, and read by people and reports. Nobody types
into it.

Bill Inmon, who coined the term in the early 1990s, gave it four properties, and each one is the
opposite of something in sections 08 and 11:

- **Subject-oriented.** Organised around what the business asks about, such as sales, stock and
  customers, rather than around the screens of the application that wrote the data.
- **Integrated.** One definition of a customer, of a shop, of revenue, even when the data came
  from several systems that disagreed.
- **Time-variant.** Every row knows the period it describes, and the past is kept.
- **Non-volatile.** Loaded and then read. A row is not edited by the people who read it.

Lessons 2 to 5 build one from the shop's database, piece by piece, and lesson 2 ends with a script
that builds all of it. Here it is already built, so that it can be asked section 07's question; you
can type this one once lesson 2 has given you the warehouse.

```sql
-- The same question, asked of the warehouse.
.timer on
SELECT d.year, b.department, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_book b USING (book_key)
GROUP BY ALL
ORDER BY ALL;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < wh-report.sql
┌───────┬─────────────┬─────────────┐
│ year  │ department  │ revenue_brl │
│ int64 │   varchar   │   double    │
├───────┼─────────────┼─────────────┤
│  2024 │ Children    │   2987810.7 │
│  2024 │ Comics      │  2553516.52 │
│  2024 │ Fiction     │ 18389500.17 │
│  2024 │ Non-fiction │ 17796358.42 │
│  2025 │ Children    │  4046265.63 │
│  2025 │ Comics      │  3018557.77 │
│  2025 │ Fiction     │ 22994642.78 │
│  2025 │ Non-fiction │ 23957246.53 │
└───────┴─────────────┴─────────────┘
Run Time (s): real 0.020 user 0.051812 sys 0.013116
```

**The same eight totals, to the cent**, in 0.020 seconds instead of 1.6. DuckDB prints `2987810.7`
where PostgreSQL printed `2987810.70`, because its result is a floating-point number and
PostgreSQL's was an exact decimal; the value is the same.

The query matters more than the speed. It names three tables, joins each to the middle one by a
single key, and the department is a column of the book. Nobody had to know that the category tree
is ragged, that cancelled orders must be left out, or that revenue is quantity times price minus
discount. **The load made those decisions once, and every query after that inherits them.**

These are the tables it holds:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT table_name, estimated_size AS rows FROM duckdb_tables() WHERE schema_name = 'main' ORDER BY table_name"
┌───────────────────────┬────────┐
│      table_name       │  rows  │
│        varchar        │ int64  │
├───────────────────────┼────────┤
│ bridge_book_author    │   3570 │
│ dim_author            │   1800 │
│ dim_book              │   3000 │
│ dim_customer          │  49309 │
│ dim_date              │    732 │
│ dim_promotion         │     11 │
│ dim_shop              │      7 │
│ fact_event_attendance │   2923 │
│ fact_fulfilment       │ 244275 │
│ fact_inventory        │ 197574 │
│ fact_payments         │ 586405 │
│ fact_sales            │ 887477 │
└───────────────────────┴────────┘
  12 rows              2 columns
```

Two kinds of name. The `fact_` tables hold events and measurements: a sale, a month-end stock count,
a payment. The `dim_` tables hold the context those events are described by: the date, the book,
the shop, the customer. That split is **dimensional modelling**, and it is the subject of lesson 2.
