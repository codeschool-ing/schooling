---
title: Incremental, e o que ele não vê
version: 1
---

O `fact_sales` é o modelo que cresce: todo dia de vendas acrescenta algumas centenas de linhas, e
toda linha anterior já está na tabela. Refazê-lo inteiro toda noite é o que uma `table` faria, e
com alguns anos de vendas essa é a coisa mais lenta do warehouse. **Um modelo incremental constrói a
tabela inteira uma vez, e depois disso só trabalha no que é novo.**

```schooling-example
{
  "language": "sql",
  "file": "shop/models/marts/fact_sales.sql",
  "parts": [
    {
      "code": "-- One row per order line sold. Each run replaces the newest day it already\n-- has and every day after it, and leaves the older days alone.\n",
      "note": "Um comentário para quem ler o modelo depois. O dbt o mantém, e ele vai parar no SQL compilado."
    },
    {
      "code": "{{ config(materialized='incremental',\n          incremental_strategy='delete+insert',\n          unique_key='order_date') }}\n",
      "note": "**A configuração mora no modelo.** Incremental, apagando e depois inserindo, com `order_date` como chave: todo dia presente nas linhas novas é apagado da tabela antes. É a troca de dia da lição 7, escrita pelo dbt."
    },
    {
      "code": "select order_date, order_id, line_no, shop_id, customer_id, book_id, quantity, line_cents\n  from {{ ref('int_sales') }}\n",
      "note": "O modelo continua sendo só um `select`. De onde vêm as linhas é um `ref`, então o dbt sabe que tem de construir antes as entradas do `int_sales`."
    },
    {
      "code": "{% if is_incremental() %}\n where order_date >= (select max(order_date) from {{ this }})\n{% endif %}",
      "note": "**A parte que só existe nas execuções seguintes.** Na primeira execução, e com `--full-refresh`, o `is_incremental()` é falso e todo o histórico é selecionado. Depois disso, só o dia mais novo que a tabela já tem, e o que vier depois dele. O `{{ this }}` é a própria tabela."
    }
  ]
}
```

Com o dia 10 no `raw`, a Ana roda só esse modelo — o `-s` escolhe quais modelos rodar:

```
ana@vm:~/etl/shop$ dbt run -s fact_sales
08:48:28  Running with dbt=1.12.5
08:48:28  Registered adapter: postgres=1.11.0
08:48:28  Found 6 models, 3 sources, 477 macros
08:48:28  
08:48:28  Concurrency: 4 threads (target='dev')
08:48:28  
08:48:28  1 of 1 START sql incremental model dbt_marts.fact_sales ........................ [RUN]
08:48:28  1 of 1 OK created sql incremental model dbt_marts.fact_sales ................... [INSERT 0 797 in 0.18s]
08:48:28  
08:48:28  Finished running 1 incremental model in 0 hours 0 minutes and 0.28 seconds (0.28s).
08:48:29  
08:48:29  Completed successfully
08:48:29  
08:48:29  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM dbt_marts.fact_sales WHERE order_date >= '2026-03-08' GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
 2026-03-08 |   383
 2026-03-09 |   429
 2026-03-10 |   368
(3 rows)

ana@vm:~/etl/shop$ cat target/run/shop/models/marts/fact_sales.sql; echo

      
        
        
        delete from "wh"."dbt_marts"."fact_sales" as DBT_INTERNAL_DEST
        where (order_date) in (
            select distinct order_date
            from "fact_sales__dbt_tmp054828825710" as DBT_INTERNAL_SOURCE
        );

    

    insert into "wh"."dbt_marts"."fact_sales" ("order_date", "order_id", "line_no", "shop_id", "customer_id", "book_id", "quantity", "line_cents")
    (
        select "order_date", "order_id", "line_no", "shop_id", "customer_id", "book_id", "quantity", "line_cents"
        from "fact_sales__dbt_tmp054828825710"
    )
```

`INSERT 0 797`: não a tabela, só o dia mais novo que ela tinha, o 9, e o novo, o 10. O dia 9 foi de
431 linhas para 429, porque no dia 10 duas linhas do dia 9 deixaram de ser vendas — os pedidos
delas cancelados ou reembolsados — e o `delete` tirou a versão antiga antes. O SQL que o dbt rodou é a troca de dia da lição 7 — apagar os
dias sendo carregados, inseri-los de novo — escrita a partir da linha de `config`.

Essa troca só alcança os dias que o `where` escolhe, e **a loja não muda só o seu dia mais novo**.
Um pedido pode ser cancelado ou devolvido uma semana depois de feito, e isso muda um dia para o qual
o modelo incremental nunca mais vai olhar. A Ana confere, com uma consulta que compara a tabela, dia
por dia, com as views de staging de onde ela foi construída:

```
-- Days on which the incremental table and a rebuild from the source disagree.
SELECT order_date, t.lines AS in_table, s.lines AS in_source
  FROM (SELECT order_date, count(*) AS lines FROM dbt_marts.fact_sales GROUP BY 1) AS t
  FULL JOIN (SELECT order_date, count(*) AS lines
               FROM dbt_staging.stg_order_lines
               JOIN dbt_staging.stg_orders USING (order_id)
              WHERE is_sale GROUP BY 1) AS s USING (order_date)
 WHERE t.lines IS DISTINCT FROM s.lines
 ORDER BY 1;
```

```
ana@vm:~/etl$ psql -d wh -f drift.sql
 order_date | in_table | in_source 
------------+----------+-----------
 2026-02-25 |      455 |       453
 2026-03-03 |      472 |       469
 2026-03-04 |      439 |       435
 2026-03-06 |      439 |       437
(4 rows)
```

Quatro dias que a tabela tem errados, o mais antigo no fim de fevereiro: pedidos cancelados ou
reembolsados desde então, cujas linhas a tabela ainda conta como vendas. Nada falhou e nada avisou. São os dados
atrasados da lição 4, chegando na outra ponta do pipeline.

Dois remédios, e projetos de verdade usam os dois. **Uma janela de volta** (*lookback*):
`max(order_date) - 30` em vez de `max(order_date)`, para que cada execução troque o último mês e não
o último dia — mais caro, e certo para qualquer mudança mais nova que a janela. E **uma recarga
completa** de tempos em tempos, que joga a tabela fora e a constrói como a primeira execução fez:

```
ana@vm:~/etl/shop$ dbt run -s fact_sales --full-refresh 2>&1 | grep -E " OK |ERROR"
08:48:31  1 of 1 OK created sql incremental model dbt_marts.fact_sales ................... [SELECT 30302 in 0.20s]
08:48:31  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1
ana@vm:~/etl$ psql -d wh -f drift.sql
 order_date | in_table | in_source 
------------+----------+-----------
(0 rows)
```

`SELECT 30302`, o histórico inteiro, e a comparação agora não acha nada. Uma recarga completa por
semana e uma execução incremental por noite é um arranjo comum: a noturna mantém a tabela fresca e
barata, e a semanal acerta o que escapou da janela.
