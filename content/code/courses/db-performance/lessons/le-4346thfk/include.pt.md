---
title: INCLUDE: carregando colunas que a busca não usa
version: 1
---

Um **índice de cobertura** é um índice que guarda todas as colunas de que uma consulta específica
precisa, para que ela possa ser respondida por um index-only scan. As colunas que uma consulta usa
fazem dois trabalhos diferentes, e uma B-tree pode guardá-las de dois jeitos diferentes:

| trabalho | exemplo | onde fica no índice |
|---|---|---|
| buscada ou ordenada | `WHERE customer_id = …`, `ORDER BY placed_at` | **colunas-chave**, entre os parênteses |
| só devolvida | `status`, `total_cents` na lista do `SELECT` | **`INCLUDE`**, depois da chave |

As colunas-chave são aquilo pelo qual a árvore está ordenada, então são o que uma busca pode usar. As
colunas do `INCLUDE` vão junto nas entradas do fundo da árvore e em nenhuma outra parte dela. Não dá
para buscar nem ordenar por elas; elas estão ali para serem **lidas**.

## A consulta: os últimos dez pedidos de um cliente

O `customer-orders.sql` da aula 2 é metade das chamadas da carga: um cliente abre "meus pedidos" e vê
os dez últimos.

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=48.00..48.03 rows=10 width=29) (actual time=0.257..0.259 rows=10 loops=1)
   Buffers: shared hit=8 read=8
   ->  Sort  (cost=48.00..48.03 rows=11 width=29) (actual time=0.256..0.257 rows=10 loops=1)
         Sort Key: placed_at DESC
         Sort Method: quicksort  Memory: 25kB
         Buffers: shared hit=8 read=8
         ->  Bitmap Heap Scan on orders  (cost=4.51..47.81 rows=11 width=29) (actual time=0.095..0.192 rows=10 loops=1)
               Recheck Cond: (customer_id = 4242)
               Heap Blocks: exact=10
               Buffers: shared hit=5 read=8
               ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.053..0.053 rows=10 loops=1)
                     Index Cond: (customer_id = 4242)
                     Buffers: shared hit=3
 Planning:
   Buffers: shared hit=141
 Planning Time: 0.828 ms
 Execution Time: 0.318 ms
(17 rows)

Time: 2.639 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 10 -f customer-orders.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 0.391 ms
tps = 20481.723645 (without initial connection time)
```

O plano tem três passos. Um `Bitmap Index Scan` no `orders_customer_id_idx` acha os dez pedidos do
cliente, o `Bitmap Heap Scan` lê **10 páginas da tabela** para buscar as colunas deles, e um `Sort`
os põe do mais novo para o mais antigo. Dezesseis páginas ao todo, 0,32 milissegundo, e sob carga
0,39 milissegundo por chamada, a 20.482 chamadas por segundo. Já é rápido; também é a instrução que a
aplicação mais roda, e as dez páginas de tabela que ela lê por chamada estão espalhadas pela tabela.

## Um índice que busca e ordena

A busca é em `customer_id`, a ordem é `placed_at`, então essas são as colunas-chave. A consulta
devolve também `status` e `total_cents`, então elas vão no `INCLUDE`:

```
market=# CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at) INCLUDE (status, total_cents);
CREATE INDEX
Time: 1922.594 ms (00:01.923)

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..44.24 rows=10 width=29) (actual time=0.035..0.055 rows=10 loops=1)
   Buffers: shared hit=10 read=3
   ->  Index Scan Backward using orders_customer_placed_idx on orders  (cost=0.43..48.62 rows=11 width=29) (actual time=0.034..0.054 rows=10 loops=1)
         Index Cond: (customer_id = 4242)
         Buffers: shared hit=10 read=3
 Planning:
   Buffers: shared hit=107 read=23
 Planning Time: 1.112 ms
 Execution Time: 0.078 ms
(9 rows)

Time: 3.156 ms

market=# DROP INDEX orders_customer_placed_idx;
DROP INDEX
Time: 120.550 ms
```

O `Sort` sumiu: o índice entrega os pedidos de um cliente já em ordem de `placed_at`, e percorrê-lo
**de trás para a frente** dá os mais novos primeiro. Mas o nó diz `Index Scan Backward`, e não `Index
Only Scan`, e ele continuou lendo a tabela. A lista do `SELECT` da consulta tem **`id`**, e o índice
não. Uma coluna esquecida, e toda linha volta ao heap.

## O índice de cobertura

```
market=# CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at) INCLUDE (id, status, total_cents);
CREATE INDEX
Time: 1813.095 ms (00:01.813)

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                                                        QUERY PLAN                                                                        
----------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..4.24 rows=10 width=29) (actual time=0.042..0.045 rows=10 loops=1)
   Buffers: shared hit=1 read=3
   ->  Index Only Scan Backward using orders_customer_placed_idx on orders  (cost=0.43..4.62 rows=11 width=29) (actual time=0.041..0.043 rows=10 loops=1)
         Index Cond: (customer_id = 4242)
         Heap Fetches: 0
         Buffers: shared hit=1 read=3
 Planning:
   Buffers: shared hit=133 read=1
 Planning Time: 0.565 ms
 Execution Time: 0.070 ms
(10 rows)

Time: 1.388 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 10 -f customer-orders.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 0.251 ms
tps = 31855.189890 (without initial connection time)
```

**`Index Only Scan Backward`, `Heap Fetches: 0`, 4 páginas.** O índice carrega tudo: a chave acha o
cliente e fornece a ordem, e as colunas do `INCLUDE` fornecem o resto. Sob carga a consulta foi de
**0,39 milissegundo para 0,25**, e de 20.482 chamadas por segundo para 31.855.

As páginas são a medida mais limpa: **de 16 para 4**, todas elas no índice, nenhuma na tabela.

## Por que não pôr todas como colunas-chave?

`CREATE INDEX … ON orders (customer_id, placed_at, id, status, total_cents)` cobriria a mesma consulta.
O `INCLUDE` continua sendo o jeito melhor de escrever, por três motivos:

- **os níveis de cima da árvore continuam pequenos.** As colunas-chave são copiadas para as páginas
  internas que guiam uma busca; as colunas do `INCLUDE` vivem só nas entradas das folhas. Numa coluna
  incluída larga, isso mantém pequena a parte da árvore que toda busca percorre.
- **um índice `UNIQUE` pode carregar colunas extras sem mudar o que é único.** `CREATE UNIQUE INDEX …
  ON customers (email) INCLUDE (name)` mantém o email único e ainda responde "nome por email" pelo
  índice; com `name` como coluna-chave, só o par seria único.
- **qualquer tipo pode ser incluído**, até um sem ordem de B-tree, porque nada compara valores
  incluídos.

E o motivo para manter uma coluna na chave: se uma consulta **filtra ou ordena** por ela, ela precisa
ser coluna-chave, na posição certa. `placed_at` precisava estar na chave aqui, em segundo, depois da
igualdade em `customer_id`; no `INCLUDE`, o índice acharia as linhas do cliente e depois precisaria
ordená-las.

## O que ele substituiu

O `orders_customer_id_idx` continua lá, e o índice novo começa pela mesma coluna, então toda consulta
que o antigo atendia, o novo atende. Manter os dois é pagar duas vezes pela mesma busca. A aula 11
trata de achar pares assim e apagar um deles com segurança. Antes disso, a próxima seção mede quanto
o índice novo custa.
