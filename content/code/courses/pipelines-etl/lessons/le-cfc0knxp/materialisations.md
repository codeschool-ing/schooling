---
title: Four materialisations
version: 1
---

How a model's `select` ends up in the warehouse is its **materialisation**, and dbt has four:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l11-materialisations\" aria-label=\"The four materialisations side by side. A view is stored as a query and run whenever it is read. A table is rebuilt whole on every dbt run. Ephemeral leaves nothing in the database and is pasted into the models that use it. Incremental is built whole once and then only has new rows added on each run.\"><text x=\"30.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">materialized=</text><text x=\"200.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">in the database</text><text x=\"400.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">on each dbt run</text><path d=\"M30.0 44.0 L690.0 44.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"30.0\" y=\"56.0\" width=\"140.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">view</text><text x=\"200.0\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a stored query</text><text x=\"400.0\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">redefined; read runs the query</text><rect x=\"30.0\" y=\"102.0\" width=\"140.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">table</text><text x=\"200.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rows</text><text x=\"400.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rebuilt whole</text><rect x=\"30.0\" y=\"148.0\" width=\"140.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ephemeral</text><text x=\"200.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nothing</text><text x=\"400.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pasted into its users as a CTE</text><rect x=\"30.0\" y=\"194.0\" width=\"140.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">incremental</text><text x=\"200.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rows</text><text x=\"400.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">only the new rows, after the first run</text></svg>", "caption": "Where the work happens: when the model is read, when dbt runs, or not at all."}
```

The project sets one per folder, and a model can override it with `{{ config(…) }}` at its top.
Ana's next three files use all four.

An **ephemeral** model for the join both marts need — order lines with their order, sales only:

```
-- Every order line that was a sale, with its order's date, shop and customer.
-- Ephemeral: never built, only pasted into the models that use it.
{{ config(materialized='ephemeral') }}
select o.order_date, o.order_id, l.line_no, o.shop_id, o.customer_id,
       l.book_id, l.quantity, l.line_cents
  from {{ ref('stg_order_lines') }} l
  join {{ ref('stg_orders') }} o using (order_id)
 where o.is_sale
```

`daily_sales`, now reading it instead of repeating the join:

```
-- Books and revenue by day, shop and category: one row per combination that sold anything.
select s.order_date,
       s.shop_id,
       b.category,
       sum(s.quantity)::integer  as books,
       sum(s.line_cents)::bigint as revenue_cents
  from {{ ref('int_sales') }} s
  join {{ ref('stg_books') }} b using (book_id)
 group by 1, 2, 3
```

And `fact_sales`, which is **incremental**, the subject of a section of its own:

```
-- One row per order line sold. Each run replaces the newest day it already
-- has and every day after it, and leaves the older days alone.
{{ config(materialized='incremental',
          incremental_strategy='delete+insert',
          unique_key='order_date') }}
select order_date, order_id, line_no, shop_id, customer_id, book_id, quantity, line_cents
  from {{ ref('int_sales') }}
{% if is_incremental() %}
 where order_date >= (select max(order_date) from {{ this }})
{% endif %}
```

```
ana@vm:~/etl/shop$ dbt run
06:27:03  Running with dbt=1.12.5
06:27:03  Registered adapter: postgres=1.11.0
06:27:04  Found 6 models, 3 sources, 477 macros
06:27:04  
06:27:04  Concurrency: 4 threads (target='dev')
06:27:04  
06:27:04  3 of 5 START sql view model dbt_staging.stg_orders ............................. [RUN]
06:27:04  2 of 5 START sql view model dbt_staging.stg_order_lines ........................ [RUN]
06:27:04  1 of 5 START sql view model dbt_staging.stg_books .............................. [RUN]
06:27:04  3 of 5 OK created sql view model dbt_staging.stg_orders ........................ [CREATE VIEW in 0.18s]
06:27:04  2 of 5 OK created sql view model dbt_staging.stg_order_lines ................... [CREATE VIEW in 0.18s]
06:27:04  1 of 5 OK created sql view model dbt_staging.stg_books ......................... [CREATE VIEW in 0.17s]
06:27:04  4 of 5 START sql table model dbt_marts.daily_sales ............................. [RUN]
06:27:04  5 of 5 START sql incremental model dbt_marts.fact_sales ........................ [RUN]
06:27:04  5 of 5 OK created sql incremental model dbt_marts.fact_sales ................... [SELECT 29947 in 0.13s]
06:27:04  4 of 5 OK created sql table model dbt_marts.daily_sales ........................ [SELECT 6195 in 0.14s]
06:27:04  
06:27:04  Finished running 1 incremental model, 1 table model, 3 view models in 0 hours 0 minutes and 0.43 seconds (0.43s).
06:27:04  
06:27:04  Completed successfully
06:27:04  
06:27:04  Done. PASS=5 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=5
```

Five models in the run, though the project has six: `int_sales` is not in the list, because there
is nothing to build. In the database, three views and two tables, and no `int_sales` anywhere:

```
ana@vm:~/etl$ psql -d wh -c "\dv dbt_staging.*" -c "\dt dbt_marts.*"
              List of relations
   Schema    |      Name       | Type | Owner 
-------------+-----------------+------+-------
 dbt_staging | stg_books       | view | ana
 dbt_staging | stg_order_lines | view | ana
 dbt_staging | stg_orders      | view | ana
(3 rows)

            List of relations
  Schema   |    Name     | Type  | Owner 
-----------+-------------+-------+-------
 dbt_marts | daily_sales | table | ana
 dbt_marts | fact_sales  | table | ana
(2 rows)

ana@vm:~/etl/shop$ sed -n "1,12p" target/compiled/shop/models/marts/daily_sales.sql
with __dbt__cte__int_sales as (
-- Every order line that was a sale, with its order's date, shop and customer.
-- Ephemeral: never built, only pasted into the models that use it.

select o.order_date, o.order_id, l.line_no, o.shop_id, o.customer_id,
       l.book_id, l.quantity, l.line_cents
  from "wh"."dbt_staging"."stg_order_lines" l
  join "wh"."dbt_staging"."stg_orders" o using (order_id)
 where o.is_sale
) -- Books and revenue by day, shop and category: one row per combination that sold anything.
select s.order_date,
       s.shop_id,
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) FROM (TABLE marts.daily_sales EXCEPT TABLE dbt_marts.daily_sales) AS old_only"
 count 
-------
     0
(1 row)
```

The compiled `daily_sales` shows where the ephemeral model went: **pasted in as a CTE** at the top
of every model that refers to it. And the mart still matches the old pipeline's, row for row.

How to choose:

- **view** when the model is cheap and should always be current. Staging is mostly renaming and
  casting, so a view costs nothing to build and nothing to keep fresh — but every read runs the
  query again, and a view sits on top of its tables, which the next section finds out the hard way.
- **table** when it is read far more often than it is built. Marts are queried all day by reports
  and rebuilt once a night.
- **ephemeral** for a step that would only be read by other models, to give it a name without a
  relation in the database. Used too much, it makes compiled SQL long and hard to debug, since
  there is nothing to `select` from in between.
- **incremental** when rebuilding is too slow: a fact table that grows every day, where yesterday's
  rows have no reason to be computed again.
