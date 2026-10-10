---
title: work_mem, por operação e por processo
version: 1
---

O `work_mem` parece um limite de quanta memória uma consulta pode usar, ou uma conexão. **Não é
nenhum dos dois: é o máximo que um sort ou um hash dentro de um processo pode usar antes de
começar a escrever em arquivos temporários.** Uma consulta com três sorts pode usar três vezes
isso. Uma consulta paralela faz o mesmo em cada um dos seus processos, e cem conexões podem estar
rodando uma cada. Essa é toda a dificuldade de dimensioná-lo, e a última seção desta lição faz a
conta. Primeiro, o que acontece no limite.

## Um sort que não cabe

Ordene o milhão de pedidos pelo valor, com os 4 MB padrão, e depois com espaço de sobra:

```
ana@db:~$ psql shop
shop=# EXPLAIN (ANALYZE, COSTS OFF)
shop-#   SELECT customer_id, total_cents FROM orders ORDER BY total_cents;
                                QUERY PLAN                                 
---------------------------------------------------------------------------
 Sort (actual time=357.462..430.820 rows=1000000 loops=1)
   Sort Key: total_cents
   Sort Method: external merge  Disk: 21632kB
   ->  Seq Scan on orders (actual time=2.660..99.928 rows=1000000 loops=1)
 Planning Time: 0.436 ms
 Execution Time: 484.063 ms
(6 rows)

shop=# SET work_mem = '100MB';
SET

shop=# EXPLAIN (ANALYZE, COSTS OFF)
shop-#   SELECT customer_id, total_cents FROM orders ORDER BY total_cents;
                                QUERY PLAN                                 
---------------------------------------------------------------------------
 Sort (actual time=281.689..417.494 rows=1000000 loops=1)
   Sort Key: total_cents
   Sort Method: quicksort  Memory: 63639kB
   ->  Seq Scan on orders (actual time=2.064..92.406 rows=1000000 loops=1)
 Planning Time: 0.100 ms
 Execution Time: 450.995 ms
(6 rows)

shop=# \q
```

A linha a ler é **`Sort Method`**. Com 4 MB o sort foi um `external merge`: ordenou quantas
linhas couberam, gravou-as num arquivo temporário, repetiu isso várias vezes e intercalou os
arquivos, 21632 kB deles. Com 100 MB foi um `quicksort` inteiro em memória, usando 63639 kB. A
versão em memória precisou de cerca de três vezes o espaço que os arquivos ocuparam, porque uma
linha sendo ordenada em memória leva ponteiros e cabeçalhos que os arquivos deixam de fora; um
sort que transborda 20 MB não cabe em 20 MB de `work_mem`.

O `SET` mudou o valor só para esta sessão, e é assim que o `work_mem` deve ser aumentado na maior
parte das vezes: para o trabalho que precisa, não para todas as conexões. O `ALTER ROLE reporting
SET work_mem = '256MB'` dá a um papel o seu próprio valor a partir da próxima conexão, a camada
por papel da lição 5, e um papel de relatórios cujas poucas consultas pesadas ordenam milhões de
linhas é o caso clássico.

O sort em memória foi mais rápido aqui, e não muito. É esta máquina de novo: os arquivos
temporários foram gravados e lidos de volta sem sair do cache de páginas. Num servidor em que eles
chegam ao disco, e principalmente onde muitas sessões transbordam ao mesmo tempo, a diferença é
maior, e a lição 19 define o `log_temp_files` para que todo transbordo acima de um tamanho que
você escolher deixe uma linha no log.

## Duas operações, duas cotas

Uma consulta é uma árvore de passos, e cada sort ou hash da árvore tem o seu próprio `work_mem`:

```
ana@db:~$ psql shop
shop=# EXPLAIN (ANALYZE, COSTS OFF)
shop-#   SELECT customer_id, sum(total_cents) FROM orders
shop-#    GROUP BY customer_id ORDER BY 2 DESC LIMIT 5;
                                      QUERY PLAN                                       
---------------------------------------------------------------------------------------
 Limit (actual time=286.506..286.527 rows=5 loops=1)
   ->  Sort (actual time=286.504..286.506 rows=5 loops=1)
         Sort Key: (sum(total_cents)) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         ->  HashAggregate (actual time=264.105..278.300 rows=50000 loops=1)
               Group Key: customer_id
               Batches: 1  Memory Usage: 4881kB
               ->  Seq Scan on orders (actual time=0.012..88.128 rows=1000000 loops=1)
 Planning Time: 0.506 ms
 Execution Time: 287.907 ms
(10 rows)

shop=# \q
```

Esta é uma sessão nova, então o `work_mem` voltou a 4 MB. Dois passos usaram memória. O
`HashAggregate` montou uma entrada por cliente, 50.000 delas, em **4881 kB, mais que o `work_mem`,
num único lote**: um hash recebe `work_mem` vezes `hash_mem_multiplier`, 2, ou seja, 8 MB, porque
um hash que transborda custa mais que um sort que transborda. O `Sort` acima dele guardou só os
cinco primeiros, em 25 kB, e tinha um `work_mem` próprio que mal tocou.

Uma consulta que junta cinco tabelas pode levar quatro hashes e um sort, cada um com direito à sua
cota, e um plano paralelo dá a cada processo worker o mesmo direito de novo. **Os 4 MB são um teto
por passo, e nada soma os passos**: nenhuma configuração limita o total que uma consulta ou uma
conexão toma.
