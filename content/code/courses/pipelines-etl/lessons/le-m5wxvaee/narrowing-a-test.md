---
title: Saying exactly what is true
version: 1
---

Two corrections. The customer rule applies to the website only, which a test's `where` expresses:
dbt wraps the model in a filter before checking it. The uniqueness rule is about a pair of columns,
and `column_name` can be an expression, so the pair becomes one value to check:

```
version: 2

models:
  - name: stg_orders
    columns:
      - name: order_id
        data_tests: [unique, not_null]
      - name: customer_id
        data_tests:
          - not_null:
              config:
                where: "shop_id = 7"            # the website: a till may sell to nobody
      - name: status
        data_tests:
          - accepted_values:
              arguments:
                values: [completed, cancelled, refunded]
  - name: stg_order_lines
    data_tests:
      - unique:                                 # the grain is the order AND the line
          arguments:
            column_name: "order_id || '-' || line_no"
    columns:
      - name: order_id
        data_tests:
          - relationships:
              arguments:
                to: ref('stg_orders')
                field: order_id
```

This time Ana runs `dbt build`, which the next section is about:

```
ana@vm:~/etl/shop$ dbt build 2>&1 | grep -E "PASS|FAIL|WARN|SKIP|ERROR|Done"
08:48:55  5 of 11 FAIL 7 not_null_stg_orders_customer_id ................................. [FAIL 7 in 0.10s]
08:48:55  4 of 11 PASS accepted_values_stg_orders_status__completed__cancelled__refunded . [PASS in 0.11s]
08:48:55  7 of 11 PASS relationships_stg_order_lines_order_id__order_id__ref_stg_orders_ . [PASS in 0.10s]
08:48:55  6 of 11 PASS not_null_stg_orders_order_id ...................................... [PASS in 0.10s]
08:48:55  9 of 11 PASS unique_stg_orders_order_id ........................................ [PASS in 0.04s]
08:48:55  8 of 11 PASS unique_stg_order_lines_order_id_line_no ........................... [PASS in 0.08s]
08:48:55  11 of 11 SKIP relation dbt_marts.fact_sales due to ephemeral model status 'skipped'  [ERROR SKIP]
08:48:55  10 of 11 SKIP relation dbt_marts.daily_sales due to ephemeral model status 'skipped'  [ERROR SKIP]
08:48:56  [ERROR]: in test not_null_stg_orders_customer_id (models/staging/schema.yml)
08:48:56  Done. PASS=8 WARN=0 ERROR=1 SKIP=2 NO-OP=0 REUSED=0 TOTAL=11
```

`unique_stg_order_lines_order_id_line_no` passes: the grain holds. The customer test still fails,
but now with **7** rows rather than 5,809, and seven is a number a person can read:

```
ana@vm:~/etl$ psql -d wh -c "SELECT order_id, ordered_at, updated_at FROM raw.orders WHERE shop_id = 7 AND customer_id IS NULL ORDER BY 1"
 order_id |       ordered_at       |       updated_at       
----------+------------------------+------------------------
   101204 | 2026-01-05 08:47:56-03 | 2026-02-13 10:18:52-03
   103233 | 2026-01-12 08:04:31-03 | 2026-02-16 15:13:36-03
   104638 | 2026-01-17 08:00:04-03 | 2026-02-20 12:18:12-03
   104990 | 2026-01-18 07:17:34-03 | 2026-02-15 15:15:17-03
   108207 | 2026-01-29 17:10:05-03 | 2026-02-13 10:18:52-03
   108348 | 2026-01-30 07:38:44-03 | 2026-02-20 12:18:12-03
   111384 | 2026-02-09 17:22:36-03 | 2026-02-16 15:13:36-03
(7 rows)
```

Seven web orders whose customer was removed weeks after the sale — the `updated_at` is the day it
happened. These are the customers who asked to be forgotten: the shop's erasure keeps the order,
because the sale happened and the accounts need it, and removes who made it. Lesson 7's
`dim_customer` deletes their rows for the same reason.

So the narrowed rule is still not quite the truth, and the remaining exceptions are not a defect
either: they are **known, explained and lawful**. Making the test pass by adding them to the `where`
would hide the next order that loses its customer for a reason nobody intended. The next section
gives Ana the other tool: a test that is allowed to fail loudly without stopping anything.
