---
title: Tests are queries that should return nothing
version: 1
---

Lesson 11 ended with a model that was wrong for four days without a single error. dbt's answer is
the **test**: a statement about the data, written next to the model, checked every time the model is
built. Ana starts with the beliefs about the shop's orders that she has carried since lesson 2.
Every order has an id, and only one; every order has a customer; the status is one of three words; every
order line belongs to an order, and is its only line:

```
version: 2

models:
  - name: stg_orders
    columns:
      - name: order_id
        data_tests: [unique, not_null]
      - name: customer_id
        data_tests: [not_null]
      - name: status
        data_tests:
          - accepted_values:
              arguments:
                values: [completed, cancelled, refunded]
  - name: stg_order_lines
    columns:
      - name: order_id
        data_tests:
          - unique
          - relationships:
              arguments:
                to: ref('stg_orders')
                field: order_id
```

`unique`, `not_null`, `accepted_values` and `relationships` are dbt's four **generic tests**, written
once by dbt and applied to any column by naming them. `dbt test` runs them all:

```
ana@vm:~/etl/shop$ dbt test
06:31:06  Running with dbt=1.12.5
06:31:07  Registered adapter: postgres=1.11.0
06:31:08  Found 6 models, 6 data tests, 3 sources, 477 macros
06:31:08  
06:31:08  Concurrency: 4 threads (target='dev')
06:31:08  
06:31:08  3 of 6 START test not_null_stg_orders_order_id ................................. [RUN]
06:31:08  1 of 6 START test accepted_values_stg_orders_status__completed__cancelled__refunded  [RUN]
06:31:08  4 of 6 START test relationships_stg_order_lines_order_id__order_id__ref_stg_orders_  [RUN]
06:31:08  2 of 6 START test not_null_stg_orders_customer_id .............................. [RUN]
06:31:08  1 of 6 PASS accepted_values_stg_orders_status__completed__cancelled__refunded .. [PASS in 0.13s]
06:31:08  2 of 6 FAIL 5809 not_null_stg_orders_customer_id ............................... [FAIL 5809 in 0.13s]
06:31:08  3 of 6 PASS not_null_stg_orders_order_id ....................................... [PASS in 0.14s]
06:31:08  6 of 6 START test unique_stg_orders_order_id ................................... [RUN]
06:31:08  5 of 6 START test unique_stg_order_lines_order_id .............................. [RUN]
06:31:08  4 of 6 PASS relationships_stg_order_lines_order_id__order_id__ref_stg_orders_ .. [PASS in 0.15s]
06:31:08  6 of 6 PASS unique_stg_orders_order_id ......................................... [PASS in 0.04s]
06:31:08  5 of 6 FAIL 7974 unique_stg_order_lines_order_id ............................... [FAIL 7974 in 0.05s]
06:31:08  
06:31:08  Finished running 6 data tests in 0 hours 0 minutes and 0.28 seconds (0.28s).
06:31:08  
06:31:08  Completed with 2 errors, 0 partial successes, and 0 warnings:
06:31:08  
06:31:08  [ERROR]: in test not_null_stg_orders_customer_id (models/staging/schema.yml)
06:31:08    Got 5809 results, configured to fail if != 0
06:31:08  
06:31:08    compiled code at target/compiled/shop/models/staging/schema.yml/not_null_stg_orders_customer_id.sql
06:31:08  
06:31:08  [ERROR]: in test unique_stg_order_lines_order_id (models/staging/schema.yml)
06:31:08    Got 7974 results, configured to fail if != 0
06:31:08  
06:31:08    compiled code at target/compiled/shop/models/staging/schema.yml/unique_stg_order_lines_order_id.sql
06:31:08  
06:31:08  Done. PASS=4 WARN=0 ERROR=2 SKIP=0 NO-OP=0 REUSED=0 TOTAL=6
```

Four beliefs held. Two did not, and by thousands.

**Every test is a `select` that returns the rows that break the rule.** dbt compiles it like a
model, runs it, and counts what comes back: zero is a pass, anything else a failure. The two that
failed, compiled:

```
ana@vm:~/etl/shop$ cat target/compiled/shop/models/staging/schema.yml/not_null_stg_orders_customer_id.sql; echo

    
    



select customer_id
from "wh"."dbt_staging"."stg_orders"
where customer_id is null



ana@vm:~/etl/shop$ cat target/compiled/shop/models/staging/schema.yml/unique_stg_order_lines_order_id.sql; echo

    
    

select
    order_id as unique_field,
    count(*) as n_records

from "wh"."dbt_staging"."stg_order_lines"
where order_id is not null
group by order_id
having count(*) > 1
```

That is all a test is, and it has two useful consequences. A failure can always be looked at: copy
the compiled query into `psql` and the offending rows are right there. And a rule dbt does not ship
is a query anybody can write — section 06 of this lesson writes one.
