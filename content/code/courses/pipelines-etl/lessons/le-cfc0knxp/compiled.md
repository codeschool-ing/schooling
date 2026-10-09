---
title: What dbt actually ran
version: 1
---

dbt never hides the SQL. Every run writes two files per model into `target/`:

```
ana@vm:~/etl/shop$ find target -name daily_sales.sql
target/run/shop/models/marts/daily_sales.sql
target/compiled/shop/models/marts/daily_sales.sql
ana@vm:~/etl/shop$ cat target/compiled/shop/models/marts/daily_sales.sql; echo
-- Books and revenue by day, shop and category: one row per combination that sold anything.
select o.order_date,
       o.shop_id,
       b.category,
       sum(l.quantity)::integer  as books,
       sum(l.line_cents)::bigint as revenue_cents
  from "wh"."dbt_staging"."stg_order_lines" l
  join "wh"."dbt_staging"."stg_orders" o using (order_id)
  join "wh"."dbt_staging"."stg_books" b using (book_id)
 where o.is_sale
 group by 1, 2, 3
ana@vm:~/etl/shop$ cat target/run/shop/models/marts/daily_sales.sql; echo

  
    

  create  table "wh"."dbt_marts"."daily_sales__dbt_tmp"
  
  
    as
  
  (
    -- Books and revenue by day, shop and category: one row per combination that sold anything.
select o.order_date,
       o.shop_id,
       b.category,
       sum(l.quantity)::integer  as books,
       sum(l.line_cents)::bigint as revenue_cents
  from "wh"."dbt_staging"."stg_order_lines" l
  join "wh"."dbt_staging"."stg_orders" o using (order_id)
  join "wh"."dbt_staging"."stg_books" b using (book_id)
 where o.is_sale
 group by 1, 2, 3
  );
```

`target/compiled` is the model after Jinja: every `ref` replaced by a quoted, fully qualified name,
`"wh"."dbt_staging"."stg_orders"`, and nothing else changed. **This is the file to copy into
`psql` when a model returns the wrong rows**: it runs as it is, without dbt.

`target/run` is what dbt sent: the same `select` wrapped in the statement the materialisation
needs. For a table, it is `create table … __dbt_tmp as (…)` — a table under a temporary name. Once
it is complete, dbt renames the old table out of the way, renames the new one into place and drops
the old, all in one transaction. **A report reading `daily_sales` during a run sees either the old
table or the new one, never a half-built one**, which is the swap lesson 7 did by hand.

When a model fails, the error dbt prints names the model and the line, and these two files are
where to look first. Most mistakes in a dbt project are visible in the compiled SQL before they are
visible anywhere else: a `ref` to the wrong model, a Jinja `if` that took the other branch.
