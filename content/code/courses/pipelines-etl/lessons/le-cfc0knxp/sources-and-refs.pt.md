---
title: Fontes, modelos e ref
version: 1
---

Um modelo lê dois tipos de coisa: tabelas que o dbt não construiu, e modelos que ele construiu. Cada
um tem a sua função, e **a função é o que transforma uma dependência em algo que o dbt enxerga**.

As tabelas que o `load_raw.py` preenche são declaradas uma vez, como **fonte** (*source*):

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

Um modelo de staging lê uma fonte com `{{ source('raw', 'orders') }}` — o nome da fonte, depois o
da tabela. É o `staging/orders.sql` da Ana com o `DROP` e o `CREATE` tirados:

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

Os outros dois modelos de staging fazem o mesmo com as linhas e os livros, como
`models/staging/stg_order_lines.sql` e `models/staging/stg_books.sql`:

```sql
-- One row per order line, with what the line was worth.
select order_id,
       line_no,
       book_id,
       quantity,
       unit_price_cents,
       quantity * unit_price_cents as line_cents
  from {{ source('raw', 'order_lines') }}
```

```sql
-- One row per book.
select book_id, isbn, title, category, publisher, list_price_cents
  from {{ source('raw', 'books') }}
```

Um mart lê outros modelos com `{{ ref('…') }}`, pelo nome do modelo, que é o nome do arquivo dele:

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

As chaves duplas são **Jinja**, uma linguagem de templates que o dbt roda sobre todo modelo antes
de o SQL chegar perto do banco. O `ref('stg_orders')` faz duas coisas ao mesmo tempo. Ele é trocado
pelo nome completo da relação que o dbt construiu para o `stg_orders` — seja qual for o banco e o
schema — e **registra que o `daily_sales` depende do `stg_orders`**. Um modelo que nomeia uma tabela
diretamente, como `dbt_staging.stg_orders`, ainda roda, mas o dbt não fica sabendo da dependência:
ele pode construir o `daily_sales` primeiro, contra a view de ontem, e nada reclama.

**Dentro de um projeto dbt, nada é nomeado à mão**: tabelas cruas por `source`, modelos por
`ref`. Toda seta do grafo do projeto é uma das duas.
