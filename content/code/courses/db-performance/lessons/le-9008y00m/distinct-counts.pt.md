---
title: Contando os valores diferentes
version: 1
---

`n_distinct` parece o número mais simples do resumo, e é o mais difícil de tirar de uma amostra.
Contar os valores diferentes em 30.000 linhas é fácil. Deduzir daí quantos valores diferentes as
outras 1.970.000 linhas guardam é um palpite, e o palpite erra numa direção previsível: **para
menos**.

## Por que uma amostra conta de menos

Imagine uma coluna em que cada valor aparece exatamente duas vezes na tabela, cinco milhões de
linhas e dois milhões e meio de valores. Uma amostra de 30.000 linhas pega a segunda cópia de
pouquíssimos deles, então quase todo valor que ela vê aparece uma vez só. É uma coluna de valores
únicos, ou de pares cujos parceiros não caíram na amostra? A amostra sozinha não sabe dizer, e o
`ANALYZE` usa uma fórmula que estima os valores não vistos a partir de quantos foram vistos uma vez
e quantos mais de uma vez. Ela acerta quando os valores são muito comuns ou realmente únicos, e fica
aquém no meio do caminho.

`order_lines` está no meio do caminho. Cada pedido tem de uma a quatro linhas, duas e meia em média:

```
market=# SELECT attname, n_distinct FROM pg_stats WHERE tablename = 'order_lines' ORDER BY attname;
   attname   | n_distinct  
-------------+-------------
 line        |           4
 order_id    | -0.28848767
 price_cents |         500
 product_id  |       43299
 quantity    |           3
(5 rows)

Time: 4.217 ms

market=# SELECT count(DISTINCT order_id) FROM order_lines;
  count  
---------
 2000000
(1 row)

Time: 563.365 ms
```

O resumo diz **-0.28848767**, uma fração, então 0,288 × 5.000.000 dá cerca de 1,44 milhão de pedidos
diferentes. A contagem diz **2.000.000**. Todo pedido tem linhas, então todo pedido aparece; a amostra
apenas viu muitos deles uma vez só para acreditar nisso. As outras colunas estão certas ou perto:
quatro números de linha, três quantidades, 500 preços. `product_id` com 43.299 é o mesmo efeito numa
forma mais branda.

## Onde uma contagem de distintos é usada

A seletividade de `order_id = 123` vem de `n_distinct` quando o valor não está na lista dos comuns:
um dividido pelo número de valores. Mas o lugar onde esse número mais trabalha é o
**agrupamento**. Pergunte ao planejador quantos grupos um `GROUP BY` vai formar:

```
market=# EXPLAIN SELECT order_id, count(*) FROM order_lines GROUP BY order_id;
                                                QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=0.43..191628.63 rows=1442436 width=16)
   Group Key: order_id
   ->  Index Only Scan using order_lines_pkey on order_lines  (cost=0.43..152204.31 rows=4999992 width=8)
 JIT:
   Functions: 3
   Options: Inlining false, Optimization false, Expressions true, Deforming true
(6 rows)

Time: 0.913 ms
```

**1.442.436 grupos** na linha de cima, os mesmos 0,288 vezes o número de linhas da tabela. Serão dois
milhões. Neste plano o erro não custa nada, porque as linhas já chegam em ordem pela chave primária e
cada grupo é contado e repassado. Mas a mesma estimativa decide, em outros planos, se uma tabela hash
dos grupos cabe no `work_mem` ou transborda para o disco, e quantas linhas um join acima do
agrupamento vai receber. Uma estimativa 28% abaixo da verdade basta para escolher errado em qualquer
um desses. (As três linhas `JIT` dizem como o servidor vai compilar as expressões, e não importam
aqui.)

## Uma amostra maior: `SET STATISTICS`

O tamanho da amostra é definido por coluna, e pode ser aumentado para a única coluna que precisa,
em vez do servidor inteiro:

```
market=# ALTER TABLE order_lines ALTER COLUMN order_id SET STATISTICS 1000;
ALTER TABLE
Time: 5.002 ms

market=# ANALYZE order_lines;
ANALYZE
Time: 1006.722 ms (00:01.007)

market=# SELECT n_distinct FROM pg_stats WHERE tablename = 'order_lines' AND attname = 'order_id';
 n_distinct 
------------
 -0.3375722
(1 row)

Time: 2.997 ms
```

`SET STATISTICS 1000` sobe o alvo desta coluna de 100 para 1000: dez vezes mais valores comuns e dez
vezes mais baldes de histograma que a coluna pode guardar. O `ANALYZE` amostra 300 vezes o maior
alvo entre as colunas da tabela, então agora lê **300.000 linhas**, e levou cerca de um segundo. A
estimativa foi de 0,288 para **0,338**, cerca de 1,69 milhão: melhor, e ainda 16% abaixo de dois
milhões. Uma amostra dez vezes maior ainda vê a maioria dos pedidos uma vez só.

Esse é o resultado honesto do `SET STATISTICS`. Ele afia o que uma amostra consegue ver: os valores
comuns da seção 03, os baldes da seção 04. Uma contagem de distintos ele melhora uma contagem de distintos só devagar, ao preço
de um `ANALYZE` mais lento e de um resumo maior, que todo plano que toca a tabela lê. Aumente onde uma
estimativa está errada e uma amostra maior a conserta, uma coluna de cada vez, não no servidor todo.

## Dizendo ao planejador: `SET (n_distinct = …)`

Quando você sabe a resposta, pode anotá-la. `order_lines` tem duas linhas e meia por pedido pelo
próprio desenho da aplicação, então o número de pedidos diferentes é dois quintos das linhas, seja
qual for o tamanho da tabela: `-0.4`.

```
market=# ALTER TABLE order_lines ALTER COLUMN order_id SET (n_distinct = -0.4);
ALTER TABLE
Time: 1.576 ms

market=# ANALYZE order_lines;
ANALYZE
Time: 1005.352 ms (00:01.005)

market=# SELECT n_distinct FROM pg_stats WHERE tablename = 'order_lines' AND attname = 'order_id';
 n_distinct 
------------
       -0.4
(1 row)

Time: 2.297 ms

market=# EXPLAIN SELECT order_id, count(*) FROM order_lines GROUP BY order_id;
                                                QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=0.43..197204.43 rows=2000000 width=16)
   Group Key: order_id
   ->  Index Only Scan using order_lines_pkey on order_lines  (cost=0.43..152204.43 rows=5000000 width=8)
 JIT:
   Functions: 3
   Options: Inlining false, Optimization false, Expressions true, Deforming true
(6 rows)

Time: 15.899 ms
```

O `ANALYZE` continua rodando e amostrando, mas para esta coluna ele mantém o valor que recebeu, e a
estimativa do `GROUP BY` agora é **2.000.000** exatos. Por ser uma fração, continua certa quando a
tabela cresce. A configuração faz parte da definição da tabela e sobrevive a todo `ANALYZE` até alguém
desfazê-la com `ALTER TABLE … ALTER COLUMN … RESET (n_distinct)`.

O perigo é o mesmo que a força: nada confere o valor. Se a aplicação mudar e os pedidos passarem a
ter dez linhas cada, o resumo continua dizendo -0.4 e toda estimativa construída sobre ele fica
errada de um jeito que nenhum `ANALYZE` vai notar. Então use isso para uma proporção que o esquema
garante, anote o porquê ao lado do `ALTER TABLE` e prefira o `SET STATISTICS` onde uma amostra maior
bastar.

As duas mudanças ficam em `order_lines` até você desfazê-las. A última seção desta aula devolve o
`market` ao estado de antes.
