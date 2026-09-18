---
title: Ordenar, agrupar, e para onde vai a memória
version: 1
---

Varreduras e junções produzem linhas. Os nós acima delas rearranjam linhas — ordenam, agrupam,
cortam — e esses nós são onde a memória de uma consulta é gasta. Cada um tem uma linha no plano
que diz como fez o trabalho, e essa linha é a coisa a ler.

## Sort, e a diferença que o LIMIT faz

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders ORDER BY placed_at LIMIT 10;
                                                          QUERY PLAN                                                          
------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=39075.64..39075.67 rows=10 width=28) (actual time=99.300..99.303 rows=10 loops=1)
   ->  Sort  (cost=39075.64..41575.64 rows=1000000 width=28) (actual time=99.298..99.300 rows=10 loops=1)
         Sort Key: placed_at
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Seq Scan on orders  (cost=0.00..17466.00 rows=1000000 width=28) (actual time=0.003..48.091 rows=1000000 loops=1)
 Planning Time: 0.282 ms
 Execution Time: 99.348 ms
(7 rows)
```

Três nós: ler tudo, ordenar, ficar com dez. `Sort Method: top-N heapsort  Memory: 26kB` é a linha
interessante. A ordenação sabia, pelo `Limit` acima dela, que só dez linhas seriam desejadas,
então manteve um heap de dez e jogou o resto fora conforme lia — um milhão de linhas ordenadas em
vinte e seis kilobytes. O `LIMIT` da aula 4 é barato exatamente por isso.

Tire o `LIMIT`:

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders ORDER BY placed_at;
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=141049.84..143549.84 rows=1000000 width=28) (actual time=333.134..404.816 rows=1000000 loops=1)
   Sort Key: placed_at
   Sort Method: external merge  Disk: 38576kB
   ->  Seq Scan on orders  (cost=0.00..17466.00 rows=1000000 width=28) (actual time=0.003..49.042 rows=1000000 loops=1)
 Planning Time: 0.211 ms
 Execution Time: 433.040 ms
(6 rows)
```

`Sort Method: external merge  Disk: 38576kB`. O mesmo milhão de linhas já não cabe na memória
que uma ordenação pode usar — `work_mem`, 4 MB neste servidor — então elas foram escritas em disco
em trechos ordenados e intercaladas de volta. Quatro vezes mais lento que o top-N, e a palavra a
procurar é **`Disk`**: uma ordenação que vaza é a razão mais comum de uma consulta que ia bem com
dez mil linhas ficar lenta com um milhão.

Duas correções, na ordem em que tentar. Peça menos linhas, se a consulta puder — um `LIMIT`, um
`WHERE` mais apertado. Senão, dê à ordenação um índice para ler:

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders ORDER BY placed_at LIMIT 10;
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.42..0.98 rows=10 width=28) (actual time=0.042..0.094 rows=10 loops=1)
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.42..55844.42 rows=1000000 width=28) (actual time=0.041..0.092 rows=10 loops=1)
 Planning Time: 0.332 ms
 Execution Time: 0.124 ms
(4 rows)
```

Com o índice da aula 9 em `placed_at`, não há nó `Sort` nenhum. O índice já está em ordem, a
varredura o lê para a frente e para depois de dez, e a coisa toda é um décimo de milissegundo.
Aumentar o `work_mem` é a terceira opção e a primeira que as pessoas procuram; é uma cota por
ordenação, concedida a toda ordenação em toda conexão ao mesmo tempo, e um número que conserta
um relatório pode deixar o servidor sem memória sob carga.

## Agregações: hash ou grupo

```
shop=# EXPLAIN ANALYZE SELECT status, count(*) FROM orders GROUP BY status;
                                                      QUERY PLAN                                                       
-----------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=22466.00..22466.04 rows=4 width=14) (actual time=193.690..193.692 rows=4 loops=1)
   Group Key: status
   Batches: 1  Memory Usage: 24kB
   ->  Seq Scan on orders  (cost=0.00..17466.00 rows=1000000 width=6) (actual time=0.004..50.667 rows=1000000 loops=1)
 Planning Time: 0.239 ms
 Execution Time: 193.886 ms
(6 rows)
```

`GROUP BY status` virou um `HashAggregate`: uma tabela hash chaveada pelo grupo, um balde por
status, toda linha somando ao seu balde. `Batches: 1  Memory Usage: 24kB` — quatro grupos, então a
tabela é minúscula. É o plano quando o número de grupos é pequeno o bastante para caber em
memória, e como no hash join, `Batches` acima de um quer dizer que não coube e vazou.

A outra agregação é o `GroupAggregate`, que precisa da entrada ordenada pela chave do grupo e
então conta cada sequência conforme passa. Ele aparece quando a entrada já está ordenada — um
índice na coluna do grupo, ou um `Sort` de que a consulta precisava de qualquer forma — e quando o
planejador espera grupos demais para hashear. Nenhum dos dois é melhor; servem a entradas
diferentes, e a linha ao lado do nó é a conferência.

## Um ORDER BY em cima de um GROUP BY

```
shop=# EXPLAIN ANALYZE SELECT city, count(*) FROM customers GROUP BY city ORDER BY city;
                                                         QUERY PLAN                                                          
-----------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=2602.27..2602.29 rows=10 width=18) (actual time=21.176..21.178 rows=10 loops=1)
   Sort Key: city
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=2602.00..2602.10 rows=10 width=18) (actual time=21.148..21.150 rows=10 loops=1)
         Group Key: city
         Batches: 1  Memory Usage: 24kB
         ->  Seq Scan on customers  (cost=0.00..2102.00 rows=100000 width=10) (actual time=0.007..5.063 rows=100000 loops=1)
 Planning Time: 0.236 ms
 Execution Time: 21.351 ms
(9 rows)
```

Leia de baixo: varrer, hashear os grupos, depois ordenar os dez grupos. Esse `Sort` é sobre dez
linhas e não custa nada, e é a ordem certa das operações — agrupar primeiro reduz cem mil linhas a
dez, e ordenar dez é de graça. Um plano que ordenasse cem mil linhas primeiro e agrupasse depois
seria um `GroupAggregate` sobre um `Sort`, e isso também não estaria errado; o planejador
precificou os dois e este foi mais barato.

## De onde veio uma ordenação que você não escreveu

Um nó `Sort` sem `ORDER BY` na consulta é uma de três coisas: um `Merge Join` precisando das
entradas em ordem, um `GroupAggregate` precisando dos grupos adjacentes, ou um `DISTINCT` feito
por ordenação. Nenhuma delas é engano, e cada uma é uma ordenação que a consulta pagou. Quando é
grande e em disco, a pergunta é se um índice teria fornecido a ordem — a mesma correção de cima,
pela mesma razão.

## O padrão

Todo nó desta seção tem uma linha que diz **método e memória**: `top-N heapsort`,
`external merge  Disk:`, `Batches:`, `Memory Usage:`. O nome do nó diz o que foi feito; essa linha
diz se coube. Um plano pode estar estruturalmente certo e ainda ser lento porque uma dessas linhas
diz `Disk`, e essa palavra é o achado.
