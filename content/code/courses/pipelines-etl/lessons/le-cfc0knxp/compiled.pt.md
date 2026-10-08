---
title: O que o dbt rodou de fato
version: 1
---

O dbt nunca esconde o SQL. Toda execução grava dois arquivos por modelo em `target/`:

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

O `target/compiled` é o modelo depois do Jinja: cada `ref` trocado por um nome completo entre aspas,
`"wh"."dbt_staging"."stg_orders"`, e nada mais mudou. **Este é o arquivo a copiar no `psql` quando
um modelo devolve as linhas erradas**: ele roda do jeito que está, sem o dbt.

O `target/run` é o que o dbt mandou: o mesmo `select` embrulhado no comando que a materialização
pede. Para uma tabela, é `create table … __dbt_tmp as (…)` — uma tabela com um nome provisório.
Quando ela fica pronta, o dbt tira a tabela antiga do caminho com outro nome, põe a nova no lugar
com o nome certo e apaga a antiga, tudo numa transação. **Um relatório lendo o `daily_sales` durante
uma execução vê a tabela antiga ou a nova, nunca uma construída pela metade**, que é a troca que a
lição 7 fez à mão.

Quando um modelo falha, o erro que o dbt imprime nomeia o modelo e a linha, e estes dois arquivos
são onde olhar primeiro. A maior parte dos erros num projeto dbt aparece no SQL compilado antes de
aparecer em qualquer outro lugar: um `ref` para o modelo errado, um `if` de Jinja que foi pelo outro
caminho.
