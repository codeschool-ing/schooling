---
title: Os quatro jeitos de ler uma tabela
version: 1
---

Todo plano termina em varreduras — nós que leem uma tabela e produzem linhas para tudo que está
acima. O PostgreSQL tem quatro, e qual delas aparece é a resposta do planejador a uma única
pergunta: **quantas linhas desta tabela a consulta quer, e quão espalhadas elas estão?**

## Seq Scan: tudo

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'paid';
                                                   QUERY PLAN                                                   
----------------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19966.00 rows=599900 width=28) (actual time=0.005..74.665 rows=600336 loops=1)
   Filter: (status = 'paid'::text)
   Rows Removed by Filter: 399664
 Planning Time: 0.342 ms
 Execution Time: 89.843 ms
(5 rows)
```

Seiscentas mil de um milhão de linhas, e há um índice em `status` — o argumento da aula 9 sobre
seletividade, com o plano para provar. O planejador leu a tabela inteira em ordem, porque seguir
um índice até sessenta por cento das páginas tocaria toda página de qualquer jeito, numa ordem
pior. Uma varredura sequencial numa consulta que devolve a maior parte de uma tabela é o plano
certo, e a linha `Filter` nela não é um problema a corrigir.

Vira problema quando o número em `Rows Removed by Filter` é grande e o número em `rows` é pequeno:
um milhão lido para ficar com treze. Esse formato é um índice que falta, ou uma das sete razões da
aula 9 para ele não estar sendo usado.

## Index Scan: uma por vez, em ordem

```
shop=# EXPLAIN SELECT * FROM customers WHERE email = 'user42@example.com';
                                      QUERY PLAN                                      
--------------------------------------------------------------------------------------
 Index Scan using customers_email_key on customers  (cost=0.42..8.44 rows=1 width=56)
   Index Cond: (email = 'user42@example.com'::text)
(2 rows)
```

Descer a árvore, achar as entradas, buscar cada linha para a qual elas apontam. É o plano para um
punhado de linhas, e a propriedade que o define é que as linhas saem **na ordem do índice**. É por
isso que um `Index Scan` pode atender um `ORDER BY` sem nenhum nó de ordenação acima dele, como a
seção sobre ordenação mostra.

O custo de um index scan é uma leitura aleatória de página por linha. Isso é bom com treze linhas
e ruim com cem mil, e a resposta do planejador para cem mil é o quarto tipo.

## Index Only Scan: a tabela nunca é tocada

```
shop=# EXPLAIN ANALYZE SELECT customer_id FROM orders WHERE customer_id = 42;
                                                              QUERY PLAN                                                              
--------------------------------------------------------------------------------------------------------------------------------------
 Index Only Scan using orders_customer_id_idx on orders  (cost=0.42..4.62 rows=11 width=4) (actual time=0.021..0.023 rows=13 loops=1)
   Index Cond: (customer_id = 42)
   Heap Fetches: 0
 Planning Time: 0.325 ms
 Execution Time: 0.062 ms
(5 rows)
```

O índice de cobertura da aula 9, como aparece num plano. A consulta pede `customer_id` e o índice
guarda `customer_id`, então as linhas não são buscadas — e `Heap Fetches: 0` diz isso. Heap é a
palavra do PostgreSQL para o armazenamento da própria tabela, e essa linha conta as vezes em que
o índice sozinho não bastou.

Quando não é zero, a aula 9 disse por quê: o mapa de visibilidade está velho, e o `VACUUM` não
alcançou. Um plano que diz `Index Only Scan` com `Heap Fetches` perto da contagem de linhas é um
index-only scan só no nome, e a correção é o vacuum e não algo na consulta.

## Bitmap Heap Scan: muitas linhas, buscadas em ordem de página

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'cancelled';
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=1096.96..9789.62 rows=98133 width=28) (actual time=4.220..25.108 rows=96942 loops=1)
   Recheck Cond: (status = 'cancelled'::text)
   Heap Blocks: exact=7466
   ->  Bitmap Index Scan on orders_status_idx  (cost=0.00..1072.42 rows=98133 width=0) (actual time=3.215..3.215 rows=96942 loops=1)
         Index Cond: (status = 'cancelled'::text)
 Planning Time: 0.346 ms
 Execution Time: 27.730 ms
(7 rows)
```

Noventa e sete mil linhas, dez por cento da tabela. Demais para buscar uma por vez em ordem de
índice — isso visitaria as mesmas páginas repetidamente — e de menos para ler a tabela inteira. O
bitmap scan é o meio-termo, e ele é sempre dois nós:

1. **`Bitmap Index Scan`** lê o índice e monta um bitmap: um bit por página da tabela, ligado onde
   o índice diz que mora uma linha que casa. Ele não devolve linha nenhuma, que é o que `width=0`
   diz.
2. **`Bitmap Heap Scan`** percorre a tabela em ordem de página, visitando só as páginas marcadas,
   e reconfere cada linha contra a condição — `Recheck Cond` — porque um bitmap sabe qual página
   e não qual linha dentro dela.

`Heap Blocks: exact=7466` é toda página da tabela, o que diz que os pedidos cancelados estão
espalhados por ela inteira. Mesmo assim ele venceu, com 27 ms contra os 90 da varredura
sequencial, porque o índice fez a filtragem e a tabela foi lida uma vez, sequencialmente.

O mesmo nó aparece para treze linhas, mais cedo nesta aula, e para três mil pendentes. É o padrão
do planejador sempre que mais do que algumas linhas são esperadas, e vê-lo não é um problema: é
o índice sendo usado, do jeito que serve à contagem.

## Duas condições, dois índices

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'pending' AND placed_at >= DATE '2025-06-01';
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=3621.85..5278.39 rows=531 width=28) (actual time=15.411..17.080 rows=562 loops=1)
   Recheck Cond: ((status = 'pending'::text) AND (placed_at >= '2025-06-01'::date))
   Heap Blocks: exact=548
   ->  BitmapAnd  (cost=3621.85..3621.85 rows=531 width=0) (actual time=15.326..15.327 rows=0 loops=1)
         ->  Bitmap Index Scan on orders_status_idx  (cost=0.00..32.92 rows=2733 width=0) (actual time=0.342..0.342 rows=2984 loops=1)
               Index Cond: (status = 'pending'::text)
         ->  Bitmap Index Scan on orders_placed_at_idx  (cost=0.00..3588.41 rows=194131 width=0) (actual time=14.828..14.828 rows=194554 loops=1)
               Index Cond: (placed_at >= '2025-06-01'::date)
 Planning Time: 0.384 ms
 Execution Time: 17.184 ms
(10 rows)
```

Um `BitmapAnd`: dois index scans, um por condição, e os bitmaps combinados antes de a tabela ser
tocada. A aula 9 disse que o PostgreSQL consegue combinar índices em colunas diferentes, e é assim
que isso aparece. Também mostra o custo: o índice em `placed_at` devolveu 194 554 entradas para
cruzar com 2984, e montar esse bitmap levou a maior parte dos 17 ms. Um único índice composto em
`(status, placed_at)` acharia as 562 linhas diretamente, que é o "igualdade primeiro, depois a
faixa" da aula 9.

## Lendo uma varredura

| o nó diz | a pergunta a fazer |
|---|---|
| `Seq Scan` com `Rows Removed by Filter` grande e poucas linhas mantidas | há um índice, e ele é utilizável? |
| `Seq Scan` mantendo a maior parte da tabela | nada — isto está certo |
| `Index Scan` com `loops` na casa dos milhares | está dentro de um nested loop que deveria ser um hash join? |
| `Index Only Scan` com `Heap Fetches` perto da contagem de linhas | quando o vacuum rodou pela última vez? |
| `Bitmap Heap Scan` com `Heap Blocks` perto do tamanho da tabela | vale um índice composto ou parcial? |

A graça da tabela é que **o nome do nó sozinho nunca é o achado**. Uma varredura sequencial está
certa ou errada conforme os números ao lado dela, e um plano se lê comparando esses números.
