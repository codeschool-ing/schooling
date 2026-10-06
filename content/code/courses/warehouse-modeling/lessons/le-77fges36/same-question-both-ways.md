---
title: The same question, both ways
version: 1
---

Section 03's question, asked of the snowflake:

```sql
-- The same question, against the snowflake.
SELECT s.region, dep.department, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_date d         USING (date_key)
JOIN dim_shop s         USING (shop_key)
JOIN sf_book b          USING (book_key)
JOIN sf_category c      USING (category_key)
JOIN sf_subcategory sub USING (subcategory_key)
JOIN sf_department dep  USING (department_key)
WHERE d.year = 2025 AND d.is_weekend AND s.channel = 'store'
GROUP BY ALL
ORDER BY s.region, revenue_brl DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < snow-query.sql
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

**The same eight rows, to the centavo.** The model changed and the meaning did not, which is what a
normalisation is supposed to do.

What changed is the query. To reach the department it now walks three more tables, in a fixed order,
by keys a person has to know the names of: book to category, category to subcategory, subcategory to
department. Ask DuckDB how many joins each query costs:

```
ana@lab:~/wh$ { echo 'EXPLAIN (FORMAT json)'; cat star-query.sql; } | duckdb -list wh.duckdb | grep -o HASH_JOIN | wc -l
3
ana@lab:~/wh$ { echo 'EXPLAIN (FORMAT json)'; cat snow-query.sql; } | duckdb -list wh.duckdb | grep -o HASH_JOIN | wc -l
6
```

Three joins against six. The extra three are cheap here, because the tables they reach have 4, 15
and 28 rows. They are not free in the other sense: **every person who writes a report has to know the
chain**, and somebody who joins `sf_book` to `sf_subcategory` directly, skipping the category, gets an
error at best and a wrong answer at worst.

That is the trade, stated plainly. The snowflake stores each name once. The star asks each reader to
make one join per dimension. The next section puts a number on what the first is worth.
