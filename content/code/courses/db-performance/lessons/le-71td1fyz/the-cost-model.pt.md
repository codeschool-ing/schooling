---
title: O modelo de custo, calculado à mão
version: 1
---

O custo num plano parece uma medida e é tratado como uma, e não é nem um tempo nem nada misterioso.
**É aritmética: um punhado de ajustes multiplicados por números que o servidor guarda sobre cada
tabela.** Calcular um à mão, uma vez, é o que transforma o planejador de oráculo numa calculadora
cujas entradas você pode conferir — e um plano que parece errado quase sempre é uma calculadora
alimentada com uma entrada errada.

## As entradas

São de dois tipos. O primeiro é o que o PostgreSQL sabe do tamanho de cada tabela, guardado na
tabela de catálogo `pg_class`: `relpages`, o número de páginas de 8 kB, e `reltuples`, o número de
linhas. O segundo é a tabela de preços, alguns ajustes que dizem quanto custa uma unidade de cada
tipo de trabalho:

```
market=# SELECT relname, relpages, reltuples FROM pg_class WHERE relname IN ('orders', 'order_lines', 'products', 'customers', 'sellers', 'events') ORDER BY relname;
   relname   | relpages |  reltuples   
-------------+----------+--------------
 customers   |     2283 |       200000
 events      |    65432 | 4.999827e+06
 order_lines |    31848 | 4.999992e+06
 orders      |    16667 |        2e+06
 products    |      649 |        50000
 sellers     |        6 |         1000
(6 rows)

Time: 2.781 ms

market=# SELECT name, setting FROM pg_settings WHERE name IN ('seq_page_cost', 'random_page_cost', 'cpu_tuple_cost', 'cpu_index_tuple_cost', 'cpu_operator_cost');
         name         | setting 
----------------------+---------
 cpu_index_tuple_cost | 0.005
 cpu_operator_cost    | 0.0025
 cpu_tuple_cost       | 0.01
 random_page_cost     | 4
 seq_page_cost        | 1
(5 rows)

Time: 2.647 ms
```

Os preços são relativos a um número. **`seq_page_cost` vale 1 por definição**: ler uma página de
uma tabela como parte de uma passada sequencial. Todo o resto tem preço em relação a isso:

| ajuste | o que ele precifica | valor |
|---|---|---|
| `seq_page_cost` | uma página lida em sequência | 1 |
| `random_page_cost` | uma página buscada fora de ordem, como faz uma varredura de índice | 4 |
| `cpu_tuple_cost` | tratar uma linha | 0.01 |
| `cpu_index_tuple_cost` | tratar uma entrada de índice | 0.005 |
| `cpu_operator_cost` | um operador ou função aplicado, como um `=` ou um `>` | 0.0025 |

Ou seja, o planejador acredita que uma página fora de ordem custa quatro vezes uma página em ordem,
e que ler uma página custa cem vezes o que custa tratar uma linha. São crenças sobre um disco,
escolhidas há muito tempo como padrão, e a aula 4 é onde o quatro contra o um decide entre dois
planos.

## Uma varredura sequencial, à mão

Uma varredura sequencial lê cada página uma vez, em ordem, e trata cada linha uma vez:

```
cost = relpages × seq_page_cost + reltuples × cpu_tuple_cost
     = 16667 × 1             + 2000000 × 0.01
     = 16667                 + 20000
     = 36667
```

Agora pergunte ao planejador. Depois acrescente uma condição, que custa um operador por linha, e por
fim prove a fórmula mudando um preço e vendo o total se mexer:

```
market=# EXPLAIN SELECT * FROM orders;
                           QUERY PLAN                            
-----------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..36667.00 rows=2000000 width=37)
(1 row)

Time: 1.437 ms

market=# EXPLAIN SELECT * FROM orders WHERE total_cents > 0;
                           QUERY PLAN                            
-----------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..41667.00 rows=1999800 width=37)
   Filter: (total_cents > 0)
(2 rows)

Time: 1.030 ms

market=# SET cpu_tuple_cost = 0.02;
SET
Time: 0.851 ms

market=# EXPLAIN SELECT * FROM orders;
                           QUERY PLAN                            
-----------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..56667.00 rows=2000000 width=37)
(1 row)

Time: 0.830 ms

market=# RESET cpu_tuple_cost;
RESET
Time: 0.276 ms
```

`36667.00`, exatamente. A condição `total_cents > 0` é aplicada a dois milhões de linhas a `0.0025`
cada, o que soma 5000 e dá `41667.00`. E com o `cpu_tuple_cost` dobrado para 0.02, os dois milhões
de linhas custam 40000 em vez de 20000 e o total é `56667.00`: **16667 páginas mais 40000 pelas
linhas, que é a fórmula e nada mais.** O `RESET` devolve o preço.

O custo inicial dos três é `0.00`, porque uma varredura sequencial não tem nada a fazer antes da
primeira linha: abre a tabela e começa a ler.

## A mesma conta para toda tabela

O resultado do `pg_class` acima basta para pôr preço numa varredura completa de qualquer uma das
seis tabelas. Duas já calculadas, para conferir contra os números do próprio planejador:

| tabela | páginas | linhas | páginas × 1 | linhas × 0.01 | total |
|---|---|---|---|---|---|
| `orders` | 16667 | 2000000 | 16667 | 20000 | 36667 |
| `products` | 649 | 50000 | 649 | 500 | 1149 |

`EXPLAIN SELECT * FROM products` imprime `cost=0.00..1149.00`. Calcule as outras você mesmo; o
exercício no fim da aula pede uma.

## Nós acima da varredura

Cada nó tem uma fórmula própria, e os nós acima de uma varredura somam a sua parte ao total que está
embaixo. A contagem dos pendentes, como uma árvore simples:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.474 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE status = 'pending';
                                                     QUERY PLAN                                                     
--------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=41683.50..41683.51 rows=1 width=8) (actual time=176.162..176.164 rows=1 loops=1)
   ->  Seq Scan on orders  (cost=0.00..41667.00 rows=6600 width=0) (actual time=175.277..175.912 rows=7319 loops=1)
         Filter: (status = 'pending'::text)
         Rows Removed by Filter: 1992681
 Planning Time: 0.540 ms
 Execution Time: 176.299 ms
(6 rows)

Time: 178.010 ms
```

A varredura é o `41667.00` de antes: páginas, linhas e um `=` por linha. O `Aggregate` acima dela
conta as linhas que recebe, o que o planejador precifica como um operador por linha: 6600 linhas
esperadas, a 0.0025, dão 16.5, então a agregação não consegue devolver nada antes de `41683.50`.
Depois ela entrega uma linha, a `cpu_tuple_cost`, que é o último `.01`.

O 6600 ali é a estimativa do planejador de quantos pedidos estão pendentes; o número real, em
`actual`, é 7319. Essa estimativa veio de estatísticas sobre a coluna `status`, não da fórmula, e
importa mais do que qualquer preço da lista: **todo nó acima de uma varredura tem o preço calculado
sobre a estimativa de linhas da varredura**, então uma estimativa errada deixa errado, junto com
ela, cada custo acima. A aula 6 trata dessa falha, e a aula 7 das estatísticas por trás da
estimativa.

## Custo não é tempo

O mesmo plano tem custo de 41683.51 e levou 176 milissegundos aqui. Não há taxa de câmbio fixa entre
os dois, e nem se pretende que haja. Numa máquina fria o mesmo custo leva mais; num disco mais
rápido, menos. **O custo existe para comparar entre si os planos de uma mesma consulta**, com os
mesmos preços, no mesmo segundo. Comparar o custo de duas consultas diferentes diz muito pouco, e
comparar um custo com um tempo não diz nada.

Um detalhe mantém a aritmética honesta quando uma tabela cresce. `relpages` e `reltuples` são
atualizados pelo `VACUUM` e pelo `ANALYZE`, não a cada insert, então o planejador não confia neles
cegamente: ele consulta o tamanho atual da tabela em páginas na hora de planejar e ajusta a contagem
de linhas na mesma proporção. Numa tabela que não mudou desde a última análise, como as seis aqui, os
dois batem e a conta à mão é exata. A aula 6 usa uma tabela em que eles não batem.
