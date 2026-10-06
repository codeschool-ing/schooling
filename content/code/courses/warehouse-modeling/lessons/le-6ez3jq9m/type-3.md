---
title: Type 3, one step of history in a column
version: 1
---

**Type 3 keeps the previous value in a second column**, beside the current one. One row per customer,
as in type 1, and one step of memory:

```sql
-- Type 3: one extra column holding the value before the latest change.
CREATE TABLE dim_customer_t3 AS
SELECT c.customer_id, c.city,
       (SELECT old_value FROM staging.customer_changes x
         WHERE x.customer_id = c.customer_id AND x.field = 'city'
         ORDER BY x.changed_at DESC LIMIT 1) AS previous_city
FROM staging.customers c;

SELECT * FROM dim_customer_t3 WHERE customer_id IN (1, 2123) ORDER BY customer_id;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < type3.sql
┌─────────────┬──────────┬───────────────┐
│ customer_id │   city   │ previous_city │
│    int64    │ varchar  │    varchar    │
├─────────────┼──────────┼───────────────┤
│           1 │ Recife   │ NULL          │
│        2123 │ Londrina │ Contagem      │
└─────────────┴──────────┴───────────────┘
```

Customer 2123 lives in Londrina and used to live in Contagem. Customer 1 never moved, and has no
previous city.

What type 3 can answer is narrow and real: **a comparison between the arrangement before one change and
the arrangement after it.** Its classic use is a reorganisation. If the shop redrew its sales regions in
2025, a `region` and a `previous_region` column on `dim_shop` would let every report show both the old
and the new arrangement side by side, for every year, while people got used to the new one.

What it cannot do is follow more than one change. A customer who moved twice has lost the first city.
And it does not tie a fact to the version that was true when it happened: every 2024 sale of customer
2123 sees both columns, Londrina and Contagem, and nothing says which one applied on the day.

So type 3 is a presentation device for one specific transition, and rare. When in doubt between type 2
and type 3, type 2 can always produce type 3's columns (the previous version is one row back), and type 3
can never produce type 2's.
