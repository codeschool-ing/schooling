---
title: The layer, seen from Metabase
version: 1
---

Start a question: **New**, then **Question**, then pick the data — **Lantern**, then **Orders**.
Metabase shows the layer's views under business names it makes from the view names, and the comments
from `semantic.sql` as their descriptions. What it read during the sync, for `orders`:

```
Orders | One row per order, without the test account. Money in reais.
   Order Date | The day the order was placed, in São Paulo, whatever the session's time zone.
   Net Revenue | Net revenue: gross minus discount for paid orders, zero for refunded ones. Sum it.
```

**Nobody typed those descriptions into Metabase.** They came from the database, where lesson 2 put
the habit and this lesson put the text, so the person choosing a column in a menu reads the same
sentence as the person reading the SQL.

Now ask the question the whole course has been circling. In the editor:

1. Under **Summarize**, choose **Sum of ...**, then **Net Revenue**.
2. Under **by**, choose **Order Date**. Metabase groups a date by month unless told otherwise, and
   says so: *Order Date: Month*.
3. **Visualize**.

A bar per month, from January 2025 to June 2026. The editor has a **View SQL** button, which shows
the query Metabase built from those three choices:

```
SELECT
  CAST(
    DATE_TRUNC('month', "semantic"."orders"."order_date") AS date
  ) AS "order_date",
  SUM("semantic"."orders"."net_revenue") AS "sum"
FROM
  "semantic"."orders"
GROUP BY
  CAST(
    DATE_TRUNC('month', "semantic"."orders"."order_date") AS date
  )
ORDER BY
  CAST(
    DATE_TRUNC('month', "semantic"."orders"."order_date") AS date
  ) ASC
```

Saved as `metabase.sql` and run from the shell as the same role Metabase uses, it gives the numbers
under the bars:

```
ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -f metabase.sql
 order_date |    sum    
------------+-----------
 2025-01-01 |    855.24
 2025-02-01 |   2970.23
 2025-03-01 |   9769.26
 2025-04-01 |  10706.84
 2025-05-01 |  21811.31
 2025-06-01 |  25889.76
 2025-07-01 |  29827.53
 2025-08-01 |  38485.73
 2025-09-01 |  52364.26
 2025-10-01 |  58003.23
 2025-11-01 |  90630.78
 2025-12-01 |  75501.85
 2026-01-01 |  87883.56
 2026-02-01 |  88361.90
 2026-03-01 | 117964.14
 2026-04-01 | 119821.78
 2026-05-01 | 140097.06
 2026-06-01 |  75811.94
(18 rows)
```

January, February and March 2026 add up to R$ 294,209.60 — finance's figure again, now reached by
somebody who chose three things from a menu and wrote no SQL at all. That is what the layer bought.
The menu offered `Net Revenue`, and summing it was the definition.

Two things in the output are worth recognising, because they come back in later lessons. June 2026
is low because it holds 17 days, and the layer's `calendar` has a `month_is_complete` column that
lesson 6 uses to say so on a chart. And the bar for August 2025 is short by the day that never
arrived: the layer can correct a fault it understands, like the mis-priced lines, and it cannot
invent a day of orders nobody loaded.
