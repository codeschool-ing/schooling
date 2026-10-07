---
title: Uma tabela grande o bastante para mostrar a diferença
version: 1
---

As trinta mil linhas da loja são poucas demais para as próximas três decisões aparecerem: todo método
termina em milissegundos e as diferenças são ruído. Então, só para esta lição, a Ana faz uma tabela
maior, e diz como:

```
-- Made for this lesson: the real fact table, copied a hundred times, each copy
-- moved back by three weeks more than the last and given order ids of its own.
DROP SCHEMA IF EXISTS big CASCADE;
CREATE SCHEMA big;
CREATE TABLE big.fact_sales AS
SELECT order_date - 21 * k AS order_date, order_id + 1000000 * k AS order_id, line_no,
       shop_id, customer_id, book_id, quantity, line_cents
  FROM dbt_marts.fact_sales, generate_series(0, 99) AS k;
ANALYZE big.fact_sales;
```

A tabela fato de verdade, cem vezes, cada cópia deslocada três semanas mais para trás que a anterior.
As cópias não são vendas de verdade, e nada as lê além desta lição. O que elas guardam dos dados reais
é a forma — os mesmos dias da semana, a mesma mistura de lojas e livros —, para que o que é verdade
sobre lê-las e escrevê-las seja verdade sobre uma tabela real desse tamanho.

```
ana@vm:~/etl$ psql -q -d wh -c "\timing on" -f big.sql
psql:big.sql:3: NOTICE:  schema "big" does not exist, skipping
Time: 0.373 ms
Time: 0.791 ms
Time: 2480.087 ms (00:02.480)
Time: 253.284 ms
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS lines, min(order_date), max(order_date), pg_size_pretty(pg_total_relation_size('big.fact_sales')) AS size FROM big.fact_sales"
  lines  |    min     |    max     |  size  
---------+------------+------------+--------
 3512100 | 2020-04-23 | 2026-03-21 | 202 MB
(1 row)
```

**Três milhões e meio de linhas, seis anos de datas, 202 MB**, feitos em menos de três segundos. Ainda
pequeno perto de um warehouse de verdade, e grande o bastante para que uma consulta que lê tudo leve
uma fração de segundo perceptível, enquanto uma que lê a parte certa não leva.
