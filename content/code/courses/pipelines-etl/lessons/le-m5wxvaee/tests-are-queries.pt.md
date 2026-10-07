---
title: Testes são consultas que deveriam não devolver nada
version: 1
---

A lição 11 terminou com um modelo que ficou errado por quatro dias sem um único erro. A resposta do
dbt é o **teste**: uma afirmação sobre os dados, escrita ao lado do modelo, conferida toda vez que o
modelo é construído. A Ana começa pelas crenças que carrega desde a lição 2 sobre os pedidos da loja.
Todo pedido tem um id, e só um; todo pedido tem um cliente; o status é uma de três palavras; toda
linha de pedido pertence a um pedido, e é a única linha dele:

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

`unique`, `not_null`, `accepted_values` e `relationships` são os quatro **testes genéricos** do
dbt, escritos uma vez pelo dbt e aplicados a qualquer coluna só de nomeá-los. O `dbt test` roda
todos:

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

Quatro crenças se sustentaram. Duas não, e por milhares.

**Todo teste é um `select` que devolve as linhas que quebram a regra.** O dbt o compila como um
modelo, roda-o e conta o que volta: zero é aprovação, qualquer outra coisa é falha. Os dois que
falharam, compilados:

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

Um teste é só isso, e isso tem duas consequências úteis. Uma falha sempre pode ser examinada: copie
a consulta compilada no `psql` e as linhas culpadas estão ali. E uma regra que o dbt não traz é uma
consulta que qualquer um pode escrever — a seção 06 desta lição escreve uma.
