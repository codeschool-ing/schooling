---
title: Sources, models and ref
version: 1
---

A model reads two kinds of thing: tables that dbt did not build, and models that it did. Each has
its own function, and **the function is what turns a dependency into something dbt can see**.

The tables `load_raw.py` fills are declared once, as a **source**:

```
version: 2

sources:
  - name: raw                   # what load_raw.py copies in: dbt reads it, never writes it
    schema: raw
    tables:
      - name: orders
      - name: order_lines
      - name: books
```

A staging model reads a source with `{{ source('raw', 'orders') }}` — the source's name, then the
table's. It is Ana's `staging/orders.sql` with the `DROP` and the `CREATE` taken out:

```
-- One row per order, as the shop has it, with the shop's own date worked out once.
select order_id,
       shop_id,
       customer_id,
       ordered_at,
       (ordered_at at time zone 'America/Sao_Paulo')::date as order_date,
       status,
       status = 'completed' as is_sale
  from {{ source('raw', 'orders') }}
```

A mart reads other models with `{{ ref('…') }}`, by the model's name, which is its file's name:

```
-- Books and revenue by day, shop and category: one row per combination that sold anything.
select o.order_date,
       o.shop_id,
       b.category,
       sum(l.quantity)::integer  as books,
       sum(l.line_cents)::bigint as revenue_cents
  from {{ ref('stg_order_lines') }} l
  join {{ ref('stg_orders') }} o using (order_id)
  join {{ ref('stg_books') }} b using (book_id)
 where o.is_sale
 group by 1, 2, 3
```

The double braces are **Jinja**, a template language dbt runs over every model before the SQL goes
anywhere near the database. `ref('stg_orders')` does two things at once. It is replaced by the full
name of the relation dbt built for `stg_orders` — whichever database and schema that turns out to
be — and **it records that `daily_sales` depends on `stg_orders`**. A model that names a table
directly, as `dbt_staging.stg_orders`, still runs, but dbt does not know about the dependency: it
may build `daily_sales` first, against yesterday's view, and nothing complains.

**Inside a dbt project, nothing is named by hand**: raw tables through `source`, models through
`ref`. Every arrow in the project's graph is one of the
two.
