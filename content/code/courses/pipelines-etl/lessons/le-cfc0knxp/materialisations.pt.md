---
title: Quatro materializações
version: 1
---

O modo como o `select` de um modelo vai parar no warehouse é a **materialização** dele, e o dbt tem
quatro:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l11-materialisations\" aria-label=\"As quatro materializações lado a lado. Uma view é guardada como consulta e roda sempre que é lida. Uma tabela é refeita inteira a cada dbt run. Efêmero não deixa nada no banco e é colado nos modelos que o usam. Incremental é construído inteiro uma vez e depois só recebe linhas novas a cada execução.\"><text x=\"30.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">materialized=</text><text x=\"200.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">no banco</text><text x=\"400.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">a cada dbt run</text><path d=\"M30.0 44.0 L690.0 44.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"30.0\" y=\"56.0\" width=\"140.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">view</text><text x=\"200.0\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma consulta guardada</text><text x=\"400.0\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">redefinida; ler roda a consulta</text><rect x=\"30.0\" y=\"102.0\" width=\"140.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">table</text><text x=\"200.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">linhas</text><text x=\"400.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">refeita inteira</text><rect x=\"30.0\" y=\"148.0\" width=\"140.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ephemeral</text><text x=\"200.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nada</text><text x=\"400.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">colado em quem o usa, como CTE</text><rect x=\"30.0\" y=\"194.0\" width=\"140.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">incremental</text><text x=\"200.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">linhas</text><text x=\"400.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">só as linhas novas, depois da primeira</text></svg>", "caption": "Onde o trabalho acontece: quando o modelo é lido, quando o dbt roda, ou em lugar nenhum."}
```

O projeto define uma por pasta, e um modelo pode trocá-la com um `{{ config(…) }}` no topo. Os três
próximos arquivos da Ana usam as quatro.

Um modelo **efêmero** para o join de que os dois marts precisam — linhas de pedido com o seu pedido,
só vendas:

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

O `daily_sales`, agora lendo esse modelo em vez de repetir o join:

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

E o `fact_sales`, que é **incremental**, assunto de uma seção própria:

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
08:48:23  Running with dbt=1.12.5
08:48:23  Registered adapter: postgres=1.11.0
08:48:24  Found 6 models, 3 sources, 477 macros
08:48:24  
08:48:24  Concurrency: 4 threads (target='dev')
08:48:24  
08:48:24  3 of 5 START sql view model dbt_staging.stg_orders ............................. [RUN]
08:48:24  2 of 5 START sql view model dbt_staging.stg_order_lines ........................ [RUN]
08:48:24  1 of 5 START sql view model dbt_staging.stg_books .............................. [RUN]
08:48:24  1 of 5 OK created sql view model dbt_staging.stg_books ......................... [CREATE VIEW in 0.21s]
08:48:24  2 of 5 OK created sql view model dbt_staging.stg_order_lines ................... [CREATE VIEW in 0.22s]
08:48:24  3 of 5 OK created sql view model dbt_staging.stg_orders ........................ [CREATE VIEW in 0.23s]
08:48:24  4 of 5 START sql table model dbt_marts.daily_sales ............................. [RUN]
08:48:24  5 of 5 START sql incremental model dbt_marts.fact_sales ........................ [RUN]
08:48:24  5 of 5 OK created sql incremental model dbt_marts.fact_sales ................... [SELECT 29947 in 0.13s]
08:48:24  4 of 5 OK created sql table model dbt_marts.daily_sales ........................ [SELECT 6195 in 0.16s]
08:48:24  
08:48:24  Finished running 1 incremental model, 1 table model, 3 view models in 0 hours 0 minutes and 0.50 seconds (0.50s).
08:48:24  
08:48:24  Completed successfully
08:48:24  
08:48:24  Done. PASS=5 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=5
```

Cinco modelos na execução, embora o projeto tenha seis: o `int_sales` não está na lista, porque não
há nada a construir. No banco, três views e duas tabelas, e nenhum `int_sales` em lugar algum:

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

O `daily_sales` compilado mostra para onde foi o modelo efêmero: **colado como uma CTE** no topo de
cada modelo que o referencia. E o mart continua batendo com o do pipeline antigo, linha por linha.

Como escolher:

- **view** quando o modelo é barato e deve estar sempre atual. Staging é quase só renomear e
  converter tipos, então uma view não custa nada para construir nem para manter fresca — mas toda
  leitura roda a consulta de novo, e uma view fica em cima das suas tabelas, o que a próxima seção
  descobre do jeito difícil.
- **table** quando é lido muito mais vezes do que é construído. Marts são consultados o dia todo por
  relatórios e refeitos uma vez por noite.
- **ephemeral** para um passo que só seria lido por outros modelos, para dar a ele um nome sem uma
  relação no banco. Usado demais, ele deixa o SQL compilado longo e difícil de depurar, já que não há
  nada de onde fazer `select` no meio do caminho.
- **incremental** quando refazer é lento demais: uma tabela fato que cresce todo dia, em que as
  linhas de ontem não têm motivo para ser calculadas de novo.
