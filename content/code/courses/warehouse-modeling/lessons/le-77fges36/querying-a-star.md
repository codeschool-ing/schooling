---
title: Asking a star a question
version: 1
---

The manager wants weekend revenue in 2025, for the physical shops only, by region and department.
Against the star it reads like the sentence:

```sql
-- Revenue in 2025 by region and department, weekends only, physical shops.
SELECT s.region, b.department, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
JOIN dim_book b USING (book_key)
WHERE d.year = 2025 AND d.is_weekend AND s.channel = 'store'
GROUP BY ALL
ORDER BY s.region, revenue_brl DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < star-query.sql
┌───────────┬─────────────┬─────────────┐
│  region   │ department  │ revenue_brl │
│  varchar  │   varchar   │   double    │
├───────────┼─────────────┼─────────────┤
│ South     │ Non-fiction │   933966.85 │
│ South     │ Fiction     │   898410.57 │
│ South     │ Children    │   156987.64 │
│ South     │ Comics      │   109634.74 │
│ Southeast │ Non-fiction │  3587030.82 │
│ Southeast │ Fiction     │  3456519.62 │
│ Southeast │ Children    │   614230.24 │
│ Southeast │ Comics      │   469070.82 │
└───────────┴─────────────┴─────────────┘
```

Every part of the question went somewhere predictable:

| the question says | the query does |
|---|---|
| in 2025, at weekends | filters `dim_date` |
| physical shops | filters `dim_shop` |
| by region | groups by a column of `dim_shop` |
| by department | groups by a column of `dim_book` |
| revenue | sums a measure of `fact_sales` |

**Filters and groupings come from dimensions; sums come from facts.** That is the whole grammar, and
it is why a business user with a report tool can be trusted to build questions on a star: the tool
offers the dimension columns as things to drag onto rows and columns, and the measures as things to
total. The join paths never change, so the tool can write them.

The Southeast sells about four times what the South does at weekends, and the order of the
departments is the same in both regions: Non-fiction, Fiction, Children, Comics. The query took no
more thought than the sentence did, which is the point of the design.
