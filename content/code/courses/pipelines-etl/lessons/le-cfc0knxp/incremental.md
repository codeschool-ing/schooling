---
title: Incremental, and what it does not see
version: 1
---

`fact_sales` is the model that grows: every day of trade adds a few hundred lines, and every line
before it is already in the table. Rebuilding it whole each night is what a `table` would do, and
on a few years of sales that is the slowest thing in the warehouse. **An incremental model builds
the whole table once, and after that only works on what is new.**

```schooling-example
{
  "language": "sql",
  "file": "shop/models/marts/fact_sales.sql",
  "parts": [
    {
      "code": "-- One row per order line sold. Each run replaces the newest day it already\n-- has and every day after it, and leaves the older days alone.\n",
      "note": "A comment for whoever reads the model next. dbt keeps it, and it ends up in the compiled SQL."
    },
    {
      "code": "{{ config(materialized='incremental',\n          incremental_strategy='delete+insert',\n          unique_key='order_date') }}\n",
      "note": "**The configuration lives in the model.** Incremental, by deleting and then inserting, with `order_date` as the key: every day present in the new rows is deleted from the table first. That is lesson 7's day replace, written by dbt."
    },
    {
      "code": "select order_date, order_id, line_no, shop_id, customer_id, book_id, quantity, line_cents\n  from {{ ref('int_sales') }}\n",
      "note": "The model is still only a `select`. Where its rows come from is a `ref`, so dbt knows to build `int_sales`'s inputs first."
    },
    {
      "code": "{% if is_incremental() %}\n where order_date >= (select max(order_date) from {{ this }})\n{% endif %}",
      "note": "**The part that only exists on later runs.** On the first run, and with `--full-refresh`, `is_incremental()` is false and the whole history is selected. After that, only the newest day the table already has, and anything after it. `{{ this }}` is the table itself."
    }
  ]
}
```

With the 10th in `raw`, Ana runs only that model — `-s` selects which models to run:

```
ana@vm:~/etl/shop$ dbt run -s fact_sales
08:48:28  Running with dbt=1.12.5
08:48:28  Registered adapter: postgres=1.11.0
08:48:28  Found 6 models, 3 sources, 477 macros
08:48:28  
08:48:28  Concurrency: 4 threads (target='dev')
08:48:28  
08:48:28  1 of 1 START sql incremental model dbt_marts.fact_sales ........................ [RUN]
08:48:28  1 of 1 OK created sql incremental model dbt_marts.fact_sales ................... [INSERT 0 797 in 0.18s]
08:48:28  
08:48:28  Finished running 1 incremental model in 0 hours 0 minutes and 0.28 seconds (0.28s).
08:48:29  
08:48:29  Completed successfully
08:48:29  
08:48:29  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM dbt_marts.fact_sales WHERE order_date >= '2026-03-08' GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
 2026-03-08 |   383
 2026-03-09 |   429
 2026-03-10 |   368
(3 rows)

ana@vm:~/etl/shop$ cat target/run/shop/models/marts/fact_sales.sql; echo

      
        
        
        delete from "wh"."dbt_marts"."fact_sales" as DBT_INTERNAL_DEST
        where (order_date) in (
            select distinct order_date
            from "fact_sales__dbt_tmp054828825710" as DBT_INTERNAL_SOURCE
        );

    

    insert into "wh"."dbt_marts"."fact_sales" ("order_date", "order_id", "line_no", "shop_id", "customer_id", "book_id", "quantity", "line_cents")
    (
        select "order_date", "order_id", "line_no", "shop_id", "customer_id", "book_id", "quantity", "line_cents"
        from "fact_sales__dbt_tmp054828825710"
    )
```

`INSERT 0 797`: not the table, only the newest day it had, the 9th, and the new one, the 10th. The
9th went from 431 lines to 429, because on the 10th two of the 9th's lines stopped being sales —
their orders cancelled or refunded — and the `delete` took the old version out first. The SQL dbt ran is lesson 7's day
replace — delete the days being loaded, insert them again — written from the `config` line.

That replace only reaches the days the `where` picks, and **the shop does not only change its
newest day**. An order can be cancelled or returned a week after it was placed, and that changes a
day the incremental model will never look at again. Ana checks, with a query that compares the
table day by day against the staging views it was built from:

```
-- Days on which the incremental table and a rebuild from the source disagree.
SELECT order_date, t.lines AS in_table, s.lines AS in_source
  FROM (SELECT order_date, count(*) AS lines FROM dbt_marts.fact_sales GROUP BY 1) AS t
  FULL JOIN (SELECT order_date, count(*) AS lines
               FROM dbt_staging.stg_order_lines
               JOIN dbt_staging.stg_orders USING (order_id)
              WHERE is_sale GROUP BY 1) AS s USING (order_date)
 WHERE t.lines IS DISTINCT FROM s.lines
 ORDER BY 1;
```

```
ana@vm:~/etl$ psql -d wh -f drift.sql
 order_date | in_table | in_source 
------------+----------+-----------
 2026-02-25 |      455 |       453
 2026-03-03 |      472 |       469
 2026-03-04 |      439 |       435
 2026-03-06 |      439 |       437
(4 rows)
```

Four days the table has wrong, the oldest at the end of February: orders cancelled or refunded
since, whose lines the table still counts as sales. Nothing failed and nothing warned. This is lesson 4's late
data, arriving at the other end of the pipeline.

Two remedies, and real projects use both. **A lookback**: `max(order_date) - 30` instead of
`max(order_date)`, so that each run replaces the last month rather than the last day — dearer, and
correct for any change younger than the window. And **a full refresh** from time to time, which
throws the table away and builds it as the first run did:

```
ana@vm:~/etl/shop$ dbt run -s fact_sales --full-refresh 2>&1 | grep -E " OK |ERROR"
08:48:31  1 of 1 OK created sql incremental model dbt_marts.fact_sales ................... [SELECT 30302 in 0.20s]
08:48:31  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1
ana@vm:~/etl$ psql -d wh -f drift.sql
 order_date | in_table | in_source 
------------+----------+-----------
(0 rows)
```

`SELECT 30302`, the whole history, and the comparison now finds nothing. A weekly full refresh and
a nightly incremental run is a common arrangement: the nightly run keeps the table fresh and cheap,
and the weekly one puts right whatever slipped past the window.
