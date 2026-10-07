---
title: A contract for what others read
version: 1
---

The morning report reads `daily_sales`, and it relies on more than the rows: on the columns being
there, with those names, and on `revenue_cents` being an integer number of cents. None of that is
written anywhere the pipeline checks. Any change to the model — a refactor, a "small fix" — can
alter it, and the report finds out by being wrong.

A **contract** writes it down where dbt enforces it. In the model's YAML, the contract is switched
on and every column is given its type:

```
version: 2

models:
  - name: daily_sales
    description: >
      Books and revenue by day, shop and category, counting completed sales only.
      One row per combination that sold anything. Read by the morning report.
    config:
      contract:
        enforced: true            # these columns, with these types, or the build fails
    columns:
      - name: order_date
        data_type: date
        description: The day of the sale in São Paulo, not in UTC.
        constraints:
          - type: not_null
      - name: shop_id
        data_type: integer
      - name: category
        data_type: text
      - name: books
        data_type: integer
      - name: revenue_cents
        data_type: bigint
        description: Sum of quantity times unit price, in cents of a real.
  - name: fact_sales
    description: >
      One row per order line sold. Incremental: each run replaces the last thirty
      days it has, so changes older than that need a full refresh.
    columns:
      - name: customer_id
        description: Null for a sale at a till to nobody, and for a customer erased on request.
```

With the contract enforced, dbt compares the columns the model's `select` produces with the ones
declared, **before** it builds the table. The first build matches and runs. Then somebody decides the
report would be nicer in reais:

```
ana@vm:~/etl/shop$ dbt build -s daily_sales 2>&1 | grep -E " OK | PASS |ERROR|Done"
07:03:43  1 of 1 OK created sql table model dbt_marts.daily_sales ........................ [INSERT 0 7202 in 0.21s]
07:03:43  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1
ana@vm:~/etl$ sed -i 's/sum(s.line_cents)::bigint as revenue_cents/sum(s.line_cents) \/ 100.0 as revenue_cents/' shop/models/marts/daily_sales.sql
ana@vm:~/etl$ grep -n revenue_cents shop/models/marts/daily_sales.sql
6:       sum(s.line_cents) / 100.0 as revenue_cents
ana@vm:~/etl/shop$ dbt build -s daily_sales 2>&1 | grep -vE "^[0-9:]{8}  (Running|Registered|Found|Concurrency|Finished|$)" | grep -v "^$"
07:03:46  1 of 1 START sql table model dbt_marts.daily_sales ............................. [RUN]
07:03:46  1 of 1 ERROR creating sql table model dbt_marts.daily_sales .................... [ERROR in 0.10s]
07:03:46  Completed with 1 error, 0 partial successes, and 0 warnings:
07:03:46  [ERROR]: in model daily_sales (models/marts/daily_sales.sql)
07:03:46    Compilation Error in model daily_sales (models/marts/daily_sales.sql)
  This model has an enforced contract that failed.
  Please ensure the name, data_type, and number of columns in your contract match the columns in your model's definition.
  
  | column_name   | definition_type | contract_type | mismatch_reason    |
  | ------------- | --------------- | ------------- | ------------------ |
  | revenue_cents | DECIMAL         | LONGINTEGER   | data type mismatch |
  
  
  > in macro assert_columns_equivalent (macros/relations/column/columns_spec_ddl.sql)
  > called by macro default__get_assert_columns_equivalent (macros/relations/column/columns_spec_ddl.sql)
  > called by macro get_assert_columns_equivalent (macros/relations/column/columns_spec_ddl.sql)
  > called by macro postgres__create_table_as (macros/adapters.sql)
  > called by macro create_table_as (macros/relations/table/create.sql)
  > called by macro default__get_create_table_as_sql (macros/relations/table/create.sql)
  > called by macro get_create_table_as_sql (macros/relations/table/create.sql)
  > called by macro statement (macros/etc/statement.sql)
  > called by macro materialization_table_default (macros/materializations/models/table.sql)
  > called by model daily_sales (models/marts/daily_sales.sql)
07:03:46    compiled code at target/compiled/shop/models/marts/daily_sales.sql
07:03:46  Done. PASS=0 WARN=0 ERROR=1 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1
ana@vm:~/etl$ sed -i 's/sum(s.line_cents) \/ 100.0 as revenue_cents/sum(s.line_cents)::bigint as revenue_cents/' shop/models/marts/daily_sales.sql
```

The table was not built. dbt names the column, the type the model now produces (`DECIMAL`) and the
type the contract promised (`LONGINTEGER`, its word for `bigint`), and stops. The report goes on
reading yesterday's table with yesterday's meaning, and the person who made the change finds out
from the build rather than from a manager. Ana puts the line back as it was.

Two things a contract is not. It is not a test of the rows: a `bigint` column can still hold wrong
numbers, which is what the tests are for. And it is not permanent: a contract can change, but then it
changes **on purpose**, in the YAML, where a reviewer sees it — and the report's owner can be told
first. Lesson 18 is about how such a change reaches production.

The `not_null` under `order_date` is a **constraint**: dbt adds it to the table it creates, so
PostgreSQL itself refuses a null there, from any writer.
