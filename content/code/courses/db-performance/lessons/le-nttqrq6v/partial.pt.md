---
title: Um índice parcial: só as linhas que alguém pergunta
version: 1
---

Um índice normalmente guarda uma entrada para cada linha da tabela. Um **índice parcial** guarda
entradas só para as linhas que satisfazem uma cláusula `WHERE` escrita no próprio índice. Quando as
consultas que importam perguntam todas sobre a mesma fatia pequena de uma tabela, o índice pode ser
essa fatia e nada mais. Ele custa uma fração do tamanho e uma fração da manutenção, e é igualmente
rápido para as consultas para as quais foi feito.

## A consulta que motiva

O `pending-count.sql` da aula 2 é a tela de operações, atualizada por todo mundo que a tem aberta:

```sql
SELECT count(*) FROM orders WHERE status = 'pending';
```

Ele ficou em segundo no placar da aula 2 por tempo total, e em primeiro pela média. A aula 7, seção
03, mostrou por que ele merece um índice: `pending` são 7319 de dois milhões de pedidos, **0,37% da
tabela**, e sem índice o servidor lê os dois milhões para contá-los. Medido sozinho, quatro clientes
por dez segundos:

```
ana@vm:~/workload$ pgbench -n -c 4 -j 4 -T 10 -f pending-count.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 255.059 ms
tps = 15.682647 (without initial connection time)
market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                              QUERY PLAN                                                               
---------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28090.76..28090.77 rows=1 width=8) (actual time=90.688..99.611 rows=1 loops=1)
   ->  Gather  (cost=28090.54..28090.75 rows=2 width=8) (actual time=90.535..99.600 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=27090.54..27090.55 rows=1 width=8) (actual time=85.818..85.819 rows=1 loops=3)
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=2750 width=0) (actual time=80.864..85.706 rows=2440 loops=3)
                     Filter: (status = 'pending'::text)
                     Rows Removed by Filter: 664227
 Planning Time: 1.594 ms
 Execution Time: 99.821 ms
(10 rows)

Time: 103.087 ms
```

**255 milissegundos** por contagem sob carga, 100 numa execução com o servidor só para ela. Dois
workers paralelos e o processo líder leem cada um um terço da tabela e jogam fora 664.227 linhas para
ficar com 2440.

## O índice óbvio

```
market=# CREATE INDEX orders_status_idx ON orders (status);
CREATE INDEX
Time: 1241.325 ms (00:01.241)

market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=156.43..156.44 rows=1 width=8) (actual time=0.933..0.934 rows=1 loops=1)
   ->  Index Only Scan using orders_status_idx on orders  (cost=0.43..139.93 rows=6600 width=0) (actual time=0.047..0.615 rows=7319 loops=1)
         Index Cond: (status = 'pending'::text)
         Heap Fetches: 0
 Planning Time: 0.894 ms
 Execution Time: 0.995 ms
(6 rows)

Time: 2.773 ms
```

**De 100 milissegundos para 1,0.** Um `Index Only Scan`: a contagem é respondida só pelas entradas do
índice, sem visitar a tabela, e `Heap Fetches: 0` diz que nenhuma linha precisou ser conferida lá. A
aula 10 trata de quando isso acontece e quando não.

Isso conserta a consulta, e é o índice em que a maioria das pessoas pararia. Mas veja o que ele
guarda: uma entrada para cada um dos dois milhões de pedidos, 1.890.887 delas dizendo `delivered`,
para que a única pergunta que alguém faz, sobre os 7319 pendentes, possa ser respondida.

## O índice parcial

```
market=# CREATE INDEX orders_pending_idx ON orders (placed_at) WHERE status = 'pending';
CREATE INDEX
Time: 225.288 ms

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('orders', 'orders_status_idx', 'orders_pending_idx');
      relname       |  size  
--------------------+--------
 orders             | 130 MB
 orders_status_idx  | 13 MB
 orders_pending_idx | 176 kB
(3 rows)

Time: 1.951 ms
```

**13 MB para o índice completo, 176 kB para o parcial**, umas setenta e cinco vezes menor, e ele
levou 225 milissegundos para ser construído em vez de 1241. O `WHERE status = 'pending'` no fim do
`CREATE INDEX` é a ideia toda: linhas que não estão pendentes não ganham entrada.

A coluna indexada é `placed_at`, e não `status`. Dentro do índice toda linha está pendente, então
indexar `status` guardaria a mesma palavra 7319 vezes; `placed_at` é algo que uma tela de operações
também quer, "os pedidos pendentes mais antigos primeiro", e o índice responde isso de graça.

Com o índice completo apagado, a contagem de novo:

```
market=# DROP INDEX orders_status_idx;
DROP INDEX
Time: 18.428 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                                  QUERY PLAN                                                                  
----------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=195.78..195.79 rows=1 width=8) (actual time=1.274..1.275 rows=1 loops=1)
   ->  Index Only Scan using orders_pending_idx on orders  (cost=0.28..179.28 rows=6600 width=0) (actual time=0.036..0.904 rows=7319 loops=1)
         Heap Fetches: 0
 Planning Time: 0.496 ms
 Execution Time: 1.327 ms
(5 rows)

Time: 2.562 ms
ana@vm:~/workload$ pgbench -n -c 4 -j 4 -T 10 -f pending-count.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 0.735 ms
tps = 5445.029216 (without initial connection time)
```

**1,3 milissegundo**, quase o mesmo que com o índice completo, a partir de uma estrutura setenta e
cinco vezes menor. Sob carga a contagem foi de **255 milissegundos para 0,7**, e o servidor respondeu
5445 delas por segundo em vez de 16.

O planejador usou o índice embora a consulta nem mencione `placed_at`. Ele pode, porque o `WHERE` do
próprio índice é o `WHERE` da consulta: toda linha que a consulta quer está no índice e toda entrada
do índice é uma linha que a consulta quer, então contar as entradas é contar as linhas. Nenhuma
linha `Index Cond` aparece, porque não sobra nada a procurar.

## Quando o planejador pode usá-lo, e quando não

Um índice parcial só pode ser usado quando o planejador consegue **provar pelo texto da consulta**
que toda linha de que ela precisa está dentro do índice. Três consultas testam isso:

```
market=# EXPLAIN SELECT id, placed_at FROM orders WHERE status = 'pending' ORDER BY placed_at LIMIT 20;
                                         QUERY PLAN                                          
---------------------------------------------------------------------------------------------
 Limit  (cost=0.28..1.00 rows=20 width=16)
   ->  Index Scan using orders_pending_idx on orders  (cost=0.28..238.28 rows=6600 width=16)
(2 rows)

Time: 3.089 ms

market=# EXPLAIN SELECT count(*) FROM orders WHERE status = 'shipped';
                                       QUERY PLAN                                        
-----------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28128.39..28128.40 rows=1 width=8)
   ->  Gather  (cost=28128.18..28128.39 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=27128.18..27128.19 rows=1 width=8)
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=17805 width=0)
                     Filter: (status = 'shipped'::text)
(6 rows)

Time: 0.918 ms

market=# PREPARE by_status(text) AS SELECT count(*) FROM orders WHERE status = $1;
PREPARE
Time: 0.487 ms

market=# SET plan_cache_mode = force_generic_plan;
SET
Time: 0.385 ms

market=# EXPLAIN EXECUTE by_status('pending');
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28604.71..28604.72 rows=1 width=8)
   ->  Gather  (cost=28604.50..28604.71 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=27604.50..27604.51 rows=1 width=8)
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=208333 width=0)
                     Filter: (status = $1)
(6 rows)

Time: 0.655 ms
```

- **`status = 'pending'` com `ORDER BY placed_at`** usa o índice para as duas coisas: filtra e ordena,
  e o `Limit` para depois de vinte.
- **`status = 'shipped'`** não pode. Pedidos enviados não têm entradas nele, e o planejador volta ao
  scan sequencial.
- **`status = $1`, preparada com plano genérico**, também não pode, mesmo executada com `'pending'`.
  Um plano genérico é feito uma vez para qualquer valor de `$1`, e para alguns valores o índice
  deixaria linhas de fora, então o planejador não pode usá-lo. Aqui o `plan_cache_mode` forçou isso;
  uma aplicação real chega ao mesmo resultado quando um driver prepara a instrução e o PostgreSQL
  passa para um plano genérico depois de algumas execuções.

A última é a armadilha. O `pg_stat_statements` mostra a instrução como `status = $1` nos dois casos,
porque normaliza as constantes, mas o que importa é o que o planejador viu: um `'pending'` literal no
SQL, ou um parâmetro cujo valor ele viu ao planejar. Se a aplicação passa `status` como parâmetro e o
cache de planos fica genérico, o índice parcial deixa de ser usado em silêncio. O conserto é escrever
a condição de que o índice precisa como literal na consulta, o que para uma tela fixa como esta é
natural de qualquer jeito.

## O que custa, e o que economiza

Todo insert e update de `orders` paga só pelas linhas que estão, ou estavam, pendentes: um pedido
feito como pendente acrescenta uma entrada, o update que o envia não acrescenta nenhuma, e o `VACUUM`
depois limpa a entrada que ficou para trás. Os 1,9 milhão de pedidos entregues não custam nada ao
índice. Essa é a outra metade do ganho, e a aula 11 põe número no que cada índice cobra de toda
escrita. Um índice parcial é o índice mais barato que você pode dar a uma consulta, quando ela
pergunta sempre pelas mesmas linhas.
