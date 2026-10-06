---
title: Is the one big table faster?
version: 1
---

The wide table removes every join. Does that make questions faster? The same question asked of the
star and of the wide table, revenue of 2025 by department and tier:

```sql
.timer on
SELECT b.department, c.tier, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_book b     USING (book_key)
JOIN dim_customer c USING (customer_key)
JOIN dim_date d     USING (date_key)
WHERE d.year = 2025 AND c.customer_key > 0
GROUP BY ALL ORDER BY ALL;
```

```sql
.timer on
SELECT department, tier, round(sum(net_cents) / 100, 2) AS revenue_brl
FROM sales_wide
WHERE year = 2025 AND tier <> 'none'
GROUP BY ALL ORDER BY ALL;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < q-star.sql
┌─────────────┬─────────┬─────────────┐
│ department  │  tier   │ revenue_brl │
│   varchar   │ varchar │   double    │
├─────────────┼─────────┼─────────────┤
│ Children    │ patron  │    64538.64 │
│ Children    │ reader  │  2673636.49 │
│ Children    │ regular │   270455.42 │
│ Comics      │ patron  │    49897.85 │
│ Comics      │ reader  │  1997493.71 │
│ Comics      │ regular │   208862.41 │
│ Fiction     │ patron  │   385006.81 │
│ Fiction     │ reader  │ 15176024.87 │
│ Fiction     │ regular │  1583683.24 │
│ Non-fiction │ patron  │   398083.85 │
│ Non-fiction │ reader  │ 15842487.94 │
│ Non-fiction │ regular │  1657785.15 │
└─────────────┴─────────┴─────────────┘
  12 rows                   3 columns
Run Time (s): real 0.021 user 0.052665 sys 0.010438
ana@lab:~/wh$ duckdb wh.duckdb < q-wide.sql
┌─────────────┬─────────┬─────────────┐
│ department  │  tier   │ revenue_brl │
│   varchar   │ varchar │   double    │
├─────────────┼─────────┼─────────────┤
│ Children    │ patron  │    64538.64 │
│ Children    │ reader  │  2673636.49 │
│ Children    │ regular │   270455.42 │
│ Comics      │ patron  │    49897.85 │
│ Comics      │ reader  │  1997493.71 │
│ Comics      │ regular │   208862.41 │
│ Fiction     │ patron  │   385006.81 │
│ Fiction     │ reader  │ 15176024.87 │
│ Fiction     │ regular │  1583683.24 │
│ Non-fiction │ patron  │   398083.85 │
│ Non-fiction │ reader  │ 15842487.94 │
│ Non-fiction │ regular │  1657785.15 │
└─────────────┴─────────┴─────────────┘
  12 rows                   3 columns
Run Time (s): real 0.017 user 0.036533 sys 0.007763
```

The same twelve rows. **0.021 seconds through three joins, 0.017 without any**: one run each, on a shared
machine, and the difference is about the size of the noise. The joins were to small dimension tables, and
a columnar engine builds a lookup from each in a fraction of a millisecond and streams the fact table
past them once.

So the speed argument for the wide table is weak in a columnar warehouse at this size. What it does
offer is real, and it is about people and tools rather than milliseconds:

- **No joins to write**, which suits tools that work on one table at a time: some dashboard products,
  a spreadsheet export, a data scientist loading a frame.
- **One object to grant access to**, describe and document.

And its costs:

- **It must be rebuilt, not edited**, as section 04 showed.
- **It is one grain.** A question about stock or payments cannot be answered from a table of sales lines.
- **Every new attribute is a new column on the biggest table**, rebuilt from scratch.

**The common answer is both**: the star as the model, maintained by the load; and a wide table or two
built from it, as views or as tables rebuilt after every load, for the tools that want them. The wide
table is an output of the warehouse, not its foundation.
