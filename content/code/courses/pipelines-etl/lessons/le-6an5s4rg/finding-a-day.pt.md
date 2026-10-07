---
title: Achar um dia em seis anos
version: 1
---

A troca de dia da lição 7, o `delete+insert` da lição 11 e a janela da lição 15 começam todos do mesmo
jeito: achar as linhas de um dia e apagá-las. Quanto isso leva depende de como o PostgreSQL as acha. O
`EXPLAIN ANALYZE` roda o comando e diz, dentro de uma transação desfeita para que nada seja apagado de
verdade:

```
-- How PostgreSQL finds one day's lines, and how long it takes, without keeping the change.
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
DELETE FROM big.fact_sales WHERE order_date = DATE '2026-03-16';
ROLLBACK;
```

```
ana@vm:~/etl$ psql -q -d wh -f one_day.sql
                       QUERY PLAN                       
--------------------------------------------------------
 Delete on fact_sales (actual rows=0 loops=1)
   ->  Seq Scan on fact_sales (actual rows=446 loops=1)
         Filter: (order_date = '2026-03-16'::date)
         Rows Removed by Filter: 3511654
 Planning Time: 0.251 ms
 Execution Time: 209.122 ms
(6 rows)
```

**`Seq Scan`**: para achar 446 linhas, o PostgreSQL leu cada uma das três milhões e meio e jogou fora
todas menos essas — *Rows Removed by Filter*. Duzentos milissegundos, e isso cresce com a tabela, não
com o dia: uma tabela com o dobro do tamanho leva o dobro para achar as mesmas 446 linhas.

Um **índice** em `order_date` é uma lista ordenada de datas, cada uma apontando para as suas linhas.
Construí-lo custa uma passada pela tabela, uma vez:

```
ana@vm:~/etl$ psql -q -d wh -c "\timing on" -c "CREATE INDEX ON big.fact_sales (order_date)"
Time: 1110.572 ms (00:01.111)
ana@vm:~/etl$ psql -q -d wh -f one_day.sql
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Delete on fact_sales (actual rows=0 loops=1)
   ->  Index Scan using fact_sales_order_date_idx on fact_sales (actual rows=446 loops=1)
         Index Cond: (order_date = '2026-03-16'::date)
 Planning Time: 0.398 ms
 Execution Time: 0.321 ms
(5 rows)
```

**`Index Scan`**: direto às 446 linhas, um terço de milissegundo. O dia foi achado num tempo que não
depende de quantos outros dias existem, e é isso que torna barato trocar um dia de uma tabela grande.

Um índice não é de graça. Ele ocupa espaço — uma cópia da coluna, ordenada — e **todo insert na tabela
também insere no índice**, então uma tabela carregada em lote toda noite paga pelos índices durante a
carga. O arranjo comum para uma tabela fato grande é um índice na coluna pela qual toda carga e todo
relatório filtram, que aqui é a data, e o mínimo de outros que os relatórios de fato precisarem.
