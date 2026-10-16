---
title: Os valores mais comuns
version: 1
---

O vendedor 1, a loja própria do marketplace, tem um quarto de todos os pedidos. Os outros 999
vendedores dividem o resto, uns 1500 cada. Um planejador que só soubesse "1000 vendedores
diferentes" esperaria 2000 pedidos para qualquer um deles e erraria por um fator de 250 justamente
no que mais importa. Ele não erra, porque o resumo carrega uma segunda informação: **os valores que
ele viu com mais frequência, com a fração das linhas que cada um representava**.

## Lendo a lista

O `\x on` põe cada coluna da resposta numa linha própria, que é o único jeito de dois arrays longos
caberem numa tela:

```
market=# \x on
Expanded display is on.

market=# SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders' AND attname = 'seller_id';
-[ RECORD 1 ]-----+------------------------------------------------------------------------------------------------------
most_common_vals  | {1,553,391,831,295,379,520,561,377,706}
most_common_freqs | {0.2508,0.0013666666,0.0012666667,0.0012333334,0.0012,0.0012,0.0012,0.0012,0.0011666666,0.0011666666}

Time: 3.346 ms
```

Dois arrays do mesmo tamanho, lidos aos pares. O valor **1** era **0.2508** da amostra, um quarto,
como o `market.sql` o fez. Os nove valores seguintes são vendedores que por acaso eram cerca de
0.0012 da amostra cada: umas 41 linhas em 30.000. Dez entradas ao todo, onde a configuração da
seção 02 permite até cem, porque o `ANALYZE` só guarda um valor que apareceu claramente mais vezes
que o valor médio. O vendedor 1 passa com folga; os nove depois dele mal passam do corte, e vale
lembrar disso na terceira estimativa abaixo.

## Três estimativas, feitas à mão

Desligue com `\x off` e pergunte ao planejador sobre três vendedores. O `EXPLAIN` sem `ANALYZE`
planeja a consulta e para, então o `rows=` que ele imprime é a estimativa e nada mais:

```
market=# EXPLAIN SELECT * FROM orders WHERE seller_id = 1;
                                        QUERY PLAN                                         
-------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=5647.83..28584.83 rows=501600 width=37)
   Recheck Cond: (seller_id = 1)
   ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..5522.43 rows=501600 width=0)
         Index Cond: (seller_id = 1)
(4 rows)

Time: 1.079 ms

market=# EXPLAIN SELECT * FROM orders WHERE seller_id = 42;
                                      QUERY PLAN                                       
---------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=19.98..4496.66 rows=1491 width=37)
   Recheck Cond: (seller_id = 42)
   ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..19.61 rows=1491 width=0)
         Index Cond: (seller_id = 42)
(4 rows)

Time: 0.443 ms

market=# EXPLAIN SELECT * FROM orders WHERE seller_id = 553;
                                      QUERY PLAN                                       
---------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=33.61..7221.63 rows=2733 width=37)
   Recheck Cond: (seller_id = 553)
   ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..32.93 rows=2733 width=0)
         Index Cond: (seller_id = 553)
(4 rows)

Time: 0.418 ms
```

E a verdade, contada:

```
market=# SELECT seller_id, count(*) FROM orders WHERE seller_id IN (1, 42, 553) GROUP BY seller_id ORDER BY seller_id;
 seller_id | count  
-----------+--------
         1 | 500114
        42 |   1532
       553 |   1590
(3 rows)

Time: 31.419 ms
```

**Vendedor 1: 501.600 estimados, 500.114 contados.** Um valor que está na lista é o caso fácil. A
frequência dele vezes o número de linhas da tabela é a estimativa: 0,2508 × 2.000.000 = 501.600,
exatamente o número do plano. Três décimos de um por cento de distância da verdade.

**Vendedor 42: 1491 estimados, 1532 contados.** O vendedor 42 não está na lista, então o planejador
raciocina sobre o que sobra. Os dez valores listados somam 0,2618 das linhas, o que deixa 0,7382
para todo o resto. Há 1000 vendedores distintos, dez deles listados, então 990 dividem esse resto, e
o planejador supõe que dividem **por igual**: 0,7382 ÷ 990 × 2.000.000 = **1491**, de novo o número
do plano. Três por cento abaixo, porque os 990 são mesmo parecidos entre si, que é como o
`market.sql` os sorteou.

**Vendedor 553: 2733 estimados, 1590 contados.** Esta é a surpresa. O vendedor 553 é o segundo da
lista, com 0.0013666666, então a estimativa dele é essa frequência vezes dois milhões. Mas o 553 é
um vendedor comum, com 1590 pedidos, não mais que o vendedor 42. Ele entrou na lista porque a
amostra por acaso pegou 41 linhas dele em vez das 24 que a sua fatia real daria, e uma vez na
lista, a sorte da amostra é tomada como fato. **Estar na lista piorou a estimativa dele em vez de
melhorar**: 72% acima, enquanto o vendedor 42, entregue à média, ficou 3% abaixo.

É essa a troca que a lista faz. Para um valor que é de fato comum, a lista é a única coisa que
mantém a estimativa sã, e o vendedor desproporcional daqui é o motivo de ela existir. Para valores
que só são comuns por acaso da amostra, a lista registra ruído. Uma amostra maior encolhe o ruído,
que é o que a seção 05 faz com `SET STATISTICS`.

## Onde o desequilíbrio morde

A diferença entre o vendedor 1 e o vendedor 42 não é cosmética. Os dois planos acima são bitmap
scans no índice da aula 2, mas o custo que o planejador põe neles é **28.585 contra 4.497**, porque
ele sabe que um busca meio milhão de linhas e o outro mil e quinhentas. A aula 4 mostrou a escolha
entre os tipos de scan girando exatamente em torno desse número, e dentro de uma consulta maior o
mesmo número decide o join, a ordem dos joins e se uma ordenação cabe na memória. Com uma lista boa,
a mesma instrução pode receber planos diferentes para vendedores diferentes, o que está certo. Sem
lista, ou com uma lista errada, todo vendedor recebe o plano de um vendedor médio.

Isso também explica uma armadilha da aula 2. O `pg_stat_statements` guarda o painel do vendedor como
uma instrução só, com uma média só, seja qual for o vendedor de cada execução. O planejador, ao
contrário, vê o valor quando planeja uma consulta comum, então planeja o painel do vendedor 1 e o
do vendedor 42 de jeitos diferentes. O placar esconde justamente a diferença que o planejador está
usando.

## Uma coluna sem cauda longa

Todos os valores de `status` cabem na lista:

```
market=# SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders' AND attname = 'status';
           most_common_vals            |           most_common_freqs           
---------------------------------------+---------------------------------------
 {delivered,cancelled,shipped,pending} | {0.9469333,0.0284,0.021366667,0.0033}
(1 row)

Time: 4.671 ms

market=# SELECT status, count(*) FROM orders GROUP BY status ORDER BY count(*) DESC;
  status   |  count  
-----------+---------
 delivered | 1890887
 cancelled |   58372
 shipped   |   43422
 pending   |    7319
(4 rows)

Time: 121.674 ms
```

Quatro valores, quatro entradas, nada sobrando para uma média. A estimativa de qualquer um deles é a
frequência vezes dois milhões. Assim, `pending` é estimado em 0,0033 × 2.000.000 = 6600 linhas e há
**7319**: 10% abaixo, porque a amostra de 30.000 viu 99 pedidos pendentes onde a fatia da tabela
daria 110. Números pequenos numa amostra mudam muito em proporção.

A linha mais importante é a última: `pending` é **0,37% da tabela**. Uma condição que separa menos
de meio por cento de dois milhões de linhas é exatamente o tipo que um índice atende bem, e a aula 9
constrói para ela um índice muito menor que o óbvio.
