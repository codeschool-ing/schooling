---
title: O EXPLAIN ANALYZE, e multiplicar pelos loops
version: 1
---

O `EXPLAIN ANALYZE` planeja a consulta, **executa-a** e imprime o plano com um segundo conjunto de
números em cada nó: o que de fato aconteceu. A aula 10 de `sql-databases` mostrou o formato. Esta
seção trata dos três jeitos como as pessoas o leem errado — um número que é por loop, um tempo que
inclui os filhos e um comando que rodou de verdade.

## `actual time`, `rows`, `loops`

A página do pedido, da carga da aula 2, junta as linhas de um pedido aos seus produtos. Rode-a de
verdade para o pedido 1234567:

```
market=# EXPLAIN ANALYZE SELECT p.title, l.quantity, l.price_cents FROM order_lines AS l JOIN products AS p ON p.id = l.product_id WHERE l.order_id = 1234567;
                                                               QUERY PLAN                                                               
----------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.72..36.91 rows=3 width=28) (actual time=0.091..0.140 rows=4 loops=1)
   ->  Index Scan using order_lines_pkey on order_lines l  (cost=0.43..11.98 rows=3 width=12) (actual time=0.064..0.065 rows=4 loops=1)
         Index Cond: (order_id = 1234567)
   ->  Index Scan using products_pkey on products p  (cost=0.29..8.31 rows=1 width=24) (actual time=0.017..0.017 rows=1 loops=4)
         Index Cond: (id = l.product_id)
 Planning Time: 1.380 ms
 Execution Time: 0.233 ms
(7 rows)

Time: 3.088 ms
```

Cada nó agora tem um segundo parêntese. **`actual time=0.064..0.065` está em milissegundos** e
espelha o custo: quando o nó entregou a primeira linha e quando entregou a última. **`rows=4` é o
que ele realmente devolveu**, para pôr ao lado da estimativa de 3. E **`loops` é quantas vezes o nó
rodou.**

A varredura de `order_lines` rodou uma vez e achou quatro linhas. A junção então buscou o produto
de cada linha, então a varredura de `products` rodou quatro vezes: `loops=4`. **Todo outro número
numa linha com `loops` acima de um é por loop, uma média das execuções.** `rows=1` ali quer dizer um
produto de cada vez, quatro no total; `actual time=0.017..0.017` quer dizer dezessete
microssegundos de cada vez, uns 0,07 milissegundo no total. A estimativa também é por loop: `rows=1`
e `cost=0.29..8.31` são o preço de uma busca.

Quatro loops não fazem mal. A mesma linha com `loops=50000` e um `0.017` de aparência inocente são
850 milissegundos, e nada na linha diz isso até você multiplicar. **Multiplique antes de acreditar
num número** em qualquer nó cujo `loops` não seja 1. A aula 5 trata da junção que produz esses
loops e de quando ela é a escolha errada.

## Os tempos incluem os filhos

Os dez pedidos mais baratos, da seção anterior, rodados de verdade com os planos paralelos
desligados na sessão:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.442 ms

market=# EXPLAIN ANALYZE SELECT id, placed_at, total_cents FROM orders ORDER BY total_cents LIMIT 10;
                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=79886.28..79886.31 rows=10 width=20) (actual time=415.266..415.270 rows=10 loops=1)
   ->  Sort  (cost=79886.28..84886.28 rows=2000000 width=20) (actual time=415.264..415.266 rows=10 loops=1)
         Sort Key: total_cents
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Seq Scan on orders  (cost=0.00..36667.00 rows=2000000 width=20) (actual time=0.069..224.847 rows=2000000 loops=1)
 Planning Time: 0.533 ms
 Execution Time: 415.347 ms
(7 rows)

Time: 417.148 ms
```

O `Seq Scan` entregou a primeira linha em 0,069 ms e a última em 224,847. O `Sort` acima dele
entregou a **primeira** linha em 415,264. É o custo inicial da seção anterior ficando visível: a
ordenação não pôde entregar nada antes de a varredura terminar, e depois gastou mais 190
milissegundos escolhendo as dez menores de dois milhões. `top-N heapsort` diz como ela fez — guardou
só as dez melhores vistas até ali, em 26 kB, em vez de ordenar tudo.

**O tempo real de um nó inclui o tempo de tudo o que está embaixo dele**, do mesmo jeito que o
custo. Os 415 milissegundos da ordenação contêm os 225 da varredura. Para achar onde o tempo foi
gasto, subtraia, como a seção anterior fez com os custos.

## Um plano paralelo também tem loops

A consulta individual mais cara da aula 2 contava os pedidos pendentes:

```
market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                              QUERY PLAN                                                               
---------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28090.76..28090.77 rows=1 width=8) (actual time=72.965..76.105 rows=1 loops=1)
   ->  Gather  (cost=28090.54..28090.75 rows=2 width=8) (actual time=72.830..76.097 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=27090.54..27090.55 rows=1 width=8) (actual time=68.531..68.532 rows=1 loops=3)
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=2750 width=0) (actual time=68.112..68.407 rows=2440 loops=3)
                     Filter: (status = 'pending'::text)
                     Rows Removed by Filter: 664227
 Planning Time: 0.536 ms
 Execution Time: 76.222 ms
(10 rows)

Time: 78.012 ms

market=# SELECT count(*) FROM orders WHERE status = 'pending';
 count 
-------
  7319
(1 row)

Time: 61.566 ms
```

`Gather` com `Workers Launched: 2` quer dizer que a varredura foi dividida entre três processos: o
que atende a sua conexão e dois ajudantes. Cada um dos três rodou o `Parallel Seq Scan`, então ele
diz `loops=3`, e `rows=2440` é a média por processo. Multiplicado, `2440 × 3` dá 7320, contra os
7319 que a contagem simples devolve; a linha a mais é o arredondamento de uma média. `Rows Removed
by Filter: 664227` também é por processo, o que dá quase dois milhões no total.

**Aqui as linhas se multiplicam e o tempo não.** Os três rodaram lado a lado, então 68
milissegundos cada são 68 milissegundos de espera, e não 205. As execuções de um nested loop
acontecem uma depois da outra e o tempo delas se multiplica; as dos workers paralelos se sobrepõem e
o delas não. A aula 4 trata de quando o planejador decide dividir uma varredura assim.

## Tempo de planejamento e tempo de execução

As duas linhas do fim são o relógio do próprio servidor. **`Planning Time` é escolher o plano;
`Execution Time` é executá-lo**, do começo até a última linha produzida. A linha `Time:` embaixo
delas é a do `psql`, que a aula 1 disse incluir a ida e a volta até o servidor: 78,012 contra os
76,222 do servidor na contagem dos pendentes.

Mais uma diferença entre os dois merece ser conhecida. O `EXPLAIN ANALYZE` joga o resultado fora em
vez de enviá-lo, então **o Execution Time deixa de fora o custo de mandar as linhas ao cliente**. Um
milhão de linhas de pedido mostram o tamanho disso. `\o /dev/null` manda o `psql` jogar as linhas
fora do lado dele também, para a tela continuar legível, e `\o` sozinho devolve a saída:

```
market=# EXPLAIN ANALYZE SELECT * FROM order_lines WHERE order_id <= 400000;
                                                                QUERY PLAN                                                                 
-------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on order_lines  (cost=23248.37..67625.31 rows=1002315 width=22) (actual time=62.497..195.361 rows=1000000 loops=1)
   Recheck Cond: (order_id <= 400000)
   Heap Blocks: exact=6370
   ->  Bitmap Index Scan on order_lines_pkey  (cost=0.00..22997.79 rows=1002315 width=0) (actual time=61.531..61.532 rows=1000000 loops=1)
         Index Cond: (order_id <= 400000)
 Planning Time: 0.749 ms
 Execution Time: 225.431 ms
(7 rows)

Time: 227.302 ms

market=# \o /dev/null
market=# SELECT * FROM order_lines WHERE order_id <= 400000;
Time: 1137.844 ms (00:01.138)

market=# \o
```

O plano diz 225 milissegundos. A mesma consulta, com o milhão de linhas de fato enviado ao `psql`,
levou 1138. Para uma consulta que devolve poucas linhas a diferença não é nada; para uma que devolve
muitas, **a aplicação espera pelas linhas, e o plano não as conta**.

## Ele executa o comando. Inteiro.

`EXPLAIN ANALYZE DELETE` apaga. `EXPLAIN ANALYZE UPDATE` atualiza. O único jeito de ver o plano real
de um comando que escreve, sem ficar com o que ele escreveu, é envolvê-lo numa transação e
desfazê-la:

```
market=# BEGIN;
BEGIN
Time: 0.413 ms

market=*# EXPLAIN ANALYZE DELETE FROM order_lines WHERE order_id = 7;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Delete on order_lines  (cost=0.43..11.98 rows=0 width=0) (actual time=0.179..0.180 rows=0 loops=1)
   ->  Index Scan using order_lines_pkey on order_lines  (cost=0.43..11.98 rows=3 width=6) (actual time=0.111..0.113 rows=4 loops=1)
         Index Cond: (order_id = 7)
 Planning Time: 0.548 ms
 Execution Time: 0.261 ms
(5 rows)

Time: 1.723 ms

market=*# SELECT count(*) FROM order_lines WHERE order_id = 7;
 count 
-------
     0
(1 row)

Time: 0.953 ms

market=*# ROLLBACK;
ROLLBACK
Time: 0.363 ms

market=# SELECT count(*) FROM order_lines WHERE order_id = 7;
 count 
-------
     4
(1 row)

Time: 0.670 ms
```

Dentro da transação o prompt muda para `market=*#`, que é o jeito do `psql` de dizer que há uma
transação aberta. O delete rodou de verdade — a contagem dentro da transação é 0 — e o `ROLLBACK` o
desfez, então as quatro linhas voltaram. O nó `Delete` diz `rows=0` porque não entrega nada para
cima; as linhas que ele apagou são as quatro que o filho achou.

Duas coisas que um rollback não desfaz, para que não surpreendam você: uma sequência que distribuiu
números continua com eles gastos, e as travas (locks) que o comando pegou nas linhas que alterou
foram travas de verdade para quem estava esperando por elas. Num servidor movimentado, um `EXPLAIN
ANALYZE` de um `UPDATE` grande dentro de uma transação ainda bloqueia as linhas em que tocou até o
rollback.
