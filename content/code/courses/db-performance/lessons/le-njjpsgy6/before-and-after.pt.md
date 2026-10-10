---
title: Uma mudança que parece certa
version: 1
---

Toda aula deste curso terminou com algo mais rápido. Esta começa com uma mudança que parece tão
sensata quanto as outras, e faz a pergunta que as outras deram como certa: **valeu a pena?** Não "a
consulta ficou mais rápida" — vai ficar —, mas se o que ela devolveu é maior do que o que custa,
medido em vez de sentido.

O candidato é o comando mais movimentado da carga da aula 2, a lista dos últimos dez pedidos de um
cliente. Metade de cada cem transações é este. Este é o plano dele com o `market` como está:

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=47.99..48.02 rows=10 width=29) (actual time=0.202..0.204 rows=10 loops=1)
   Buffers: shared hit=5 read=11
   ->  Sort  (cost=47.99..48.02 rows=11 width=29) (actual time=0.201..0.202 rows=10 loops=1)
         Sort Key: placed_at DESC
         Sort Method: quicksort  Memory: 25kB
         Buffers: shared hit=5 read=11
         ->  Bitmap Heap Scan on orders  (cost=4.51..47.80 rows=11 width=29) (actual time=0.066..0.151 rows=10 loops=1)
               Recheck Cond: (customer_id = 4242)
               Heap Blocks: exact=10
               Buffers: shared hit=2 read=11
               ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.043..0.043 rows=10 loops=1)
                     Index Cond: (customer_id = 4242)
                     Buffers: shared read=3
 Planning:
   Buffers: shared hit=137 read=4
 Planning Time: 1.001 ms
 Execution Time: 0.261 ms
(17 rows)

Time: 2.704 ms
```

O servidor acha os pedidos do cliente pelo `orders_customer_id_idx`, busca as dez linhas e **as
ordena** por `placed_at` para pegar as dez mais novas. Um índice em `(customer_id, placed_at DESC)`
entregaria as linhas já nessa ordem, então a ordenação some e a varredura para na décima linha. É
conselho de livro, e a aula 10 diria o mesmo. É exatamente o tipo de mudança que entra numa sexta à
tarde porque é obviamente certa.

## Meça o antes, três vezes

Uma execução de qualquer coisa é ruído (aula 1 seção 06). Então o antes são três execuções da carga
inteira, trinta segundos cada, cortadas nos dois scripts que importam — o que a mudança quer
ajudar, e o que grava em `orders` e vai pagar por qualquer índice novo:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1148.472551 (without initial connection time)
SQL script 1: customer-orders.sql
 - 17352 transactions (50.1% of total, tps = 575.862443)
 - latency average = 0.857 ms
 - latency stddev = 1.991 ms
SQL script 4: place-order.sql
 - 3541 transactions (10.2% of total, tps = 117.515497)
 - latency average = 8.251 ms
 - latency stddev = 5.825 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1134.043452 (without initial connection time)
SQL script 1: customer-orders.sql
 - 17249 transactions (50.4% of total, tps = 571.828681)
 - latency average = 0.842 ms
 - latency stddev = 1.953 ms
SQL script 4: place-order.sql
 - 3501 transactions (10.2% of total, tps = 116.063088)
 - latency average = 8.794 ms
 - latency stddev = 8.038 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1151.505363 (without initial connection time)
SQL script 1: customer-orders.sql
 - 17324 transactions (50.1% of total, tps = 577.402498)
 - latency average = 0.836 ms
 - latency stddev = 1.965 ms
SQL script 4: place-order.sql
 - 3494 transactions (10.1% of total, tps = 116.453725)
 - latency average = 8.156 ms
 - latency stddev = 5.331 ms
```

E a visão do próprio servidor sobre o comando nesses noventa segundos, antes de zerar o placar:

```
market=# SELECT calls, round(mean_exec_time::numeric, 3) AS mean_ms, round(total_exec_time) AS total_ms FROM pg_stat_statements WHERE query LIKE 'SELECT id, placed_at%';
 calls | mean_ms | total_ms 
-------+---------+----------
 51928 |   0.107 |     5578
(1 row)

Time: 2.461 ms

market=# SELECT pg_stat_statements_reset();
 pg_stat_statements_reset 
--------------------------
 
(1 row)

Time: 1.172 ms
```

## Faça a mudança, e meça o depois do mesmo jeito

```
market=# CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at DESC);
CREATE INDEX
Time: 1186.757 ms (00:01.187)

market=# SELECT pg_size_pretty(pg_relation_size('orders_customer_placed_idx')) AS new_index, pg_size_pretty(pg_relation_size('orders_customer_id_idx')) AS old_index;
 new_index | old_index 
-----------+-----------
 60 MB     | 18 MB
(1 row)

Time: 0.887 ms
```

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..44.24 rows=10 width=29) (actual time=0.058..0.170 rows=10 loops=1)
   Buffers: shared hit=9 read=4
   ->  Index Scan using orders_customer_placed_idx on orders  (cost=0.43..48.62 rows=11 width=29) (actual time=0.057..0.167 rows=10 loops=1)
         Index Cond: (customer_id = 4242)
         Buffers: shared hit=9 read=4
 Planning:
   Buffers: shared hit=135 read=22
 Planning Time: 0.778 ms
 Execution Time: 0.194 ms
(9 rows)

Time: 2.448 ms
```

O plano é o que o livro prometeu: um `Index Scan using orders_customer_placed_idx`, sem `Sort`, e a
varredura parou em dez linhas. A execução foi de 0,261 para **0,194 milissegundo**, e os buffers de
16 tocados para 13. Depois, as mesmas três execuções:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1200.249639 (without initial connection time)
SQL script 1: customer-orders.sql
 - 17917 transactions (49.7% of total, tps = 596.976176)
 - latency average = 0.796 ms
 - latency stddev = 1.858 ms
SQL script 4: place-order.sql
 - 3636 transactions (10.1% of total, tps = 121.147814)
 - latency average = 8.357 ms
 - latency stddev = 5.404 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1116.698771 (without initial connection time)
SQL script 1: customer-orders.sql
 - 16837 transactions (50.2% of total, tps = 561.132217)
 - latency average = 0.794 ms
 - latency stddev = 1.882 ms
SQL script 4: place-order.sql
 - 3386 transactions (10.1% of total, tps = 112.846332)
 - latency average = 8.332 ms
 - latency stddev = 5.453 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | sed -n -e '/^tps/p' -e '/customer-orders/,/stddev/p' -e '/place-order/,/stddev/p' | grep -v -e weight -e failed
tps = 1150.977750 (without initial connection time)
SQL script 1: customer-orders.sql
 - 17420 transactions (50.4% of total, tps = 580.369711)
 - latency average = 0.800 ms
 - latency stddev = 1.930 ms
SQL script 4: place-order.sql
 - 3485 transactions (10.1% of total, tps = 116.107258)
 - latency average = 8.212 ms
 - latency stddev = 5.261 ms
```

```
market=# SELECT calls, round(mean_exec_time::numeric, 3) AS mean_ms, round(total_exec_time) AS total_ms FROM pg_stat_statements WHERE query LIKE 'SELECT id, placed_at%';
 calls | mean_ms | total_ms 
-------+---------+----------
 52176 |   0.089 |     4632
(1 row)

Time: 1.903 ms
```

## O que os números dizem, antes de decidir o que significam

| | antes | depois |
|---|---|---|
| média do servidor para o comando | 0,107 ms | 0,089 ms |
| latência no pgbench, customer-orders, três execuções | 0,857, 0,842, 0,836 ms | 0,796, 0,794, 0,800 ms |
| latência no pgbench, place-order, três execuções | 8,251, 8,794, 8,156 ms | 8,357, 8,332, 8,212 ms |
| taxa geral, três execuções | 1148, 1134, 1151 | 1200, 1116, 1150 |

O comando ficou mais rápido: pela conta do servidor, **0,018 milissegundo por chamada**, cerca de
um sexto. Cada outra linha da tabela é a pergunta de se essa diferença é real e do que custou — e
são as duas próximas seções.
