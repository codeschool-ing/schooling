---
title: Carregando uma relação de uma vez
version: 1
---

A correção do N+1 é dizer ao ORM, antes do laço, que os pedidos vão ser desejados. Todo mapeador
tem um jeito de dizer isso, e por baixo há exatamente duas formas de SQL.

## Uma consulta por nível, com o conjunto

Busque os cinquenta clientes. Pegue os ids deles. Busque todo pedido cujo `customer_id` está nesse
conjunto, numa instrução só, e entregue cada pedido ao seu cliente em memória:

```
shop=# SELECT id, customer_id, placed_at, total FROM orders WHERE customer_id = ANY(ARRAY[1, 2, 3]) ORDER BY customer_id, placed_at;
   id   | customer_id |           placed_at           | total  
--------+-------------+-------------------------------+--------
 867901 |           1 | 2024-02-01 19:45:14.879823+00 | 645.81
 436232 |           1 | 2024-03-20 14:06:59.047487+00 | 248.10
 832622 |           1 | 2024-04-03 05:16:39.364248+00 | 292.93
 563685 |           1 | 2024-05-12 06:31:09.597037+00 | 950.55
 712515 |           1 | 2024-06-19 20:24:34.119482+00 | 999.09
 106558 |           1 | 2024-10-24 13:18:18.94516+00  | 378.71
 376517 |           1 | 2025-03-01 12:22:17.35475+00  | 449.14
 186406 |           1 | 2025-03-13 08:14:07.577697+00 | 241.28
  83957 |           1 | 2025-04-01 08:36:51.409198+00 | 824.88
 561192 |           1 | 2025-05-18 15:20:10.148928+00 | 826.20
 174320 |           1 | 2025-07-28 07:33:10.682282+00 | 629.38
 634580 |           1 | 2025-08-13 19:55:45.983218+00 | 508.08
 973786 |           2 | 2023-11-25 23:44:59.843629+00 | 402.98
 153988 |           2 | 2024-02-05 13:20:55.311275+00 | 362.49
 377213 |           2 | 2024-02-14 05:58:51.408678+00 | 187.07
 750331 |           2 | 2024-05-30 12:41:13.21633+00  | 130.32
 808345 |           2 | 2024-06-30 19:37:46.382061+00 | 661.96
 817860 |           2 | 2024-08-11 14:43:12.612129+00 | 584.30
 906859 |           2 | 2024-08-14 19:10:22.97878+00  | 431.19
  66505 |           2 | 2025-04-07 09:18:44.349303+00 | 706.37
 681428 |           2 | 2025-04-27 15:58:35.762079+00 | 280.21
 261311 |           2 | 2025-04-28 06:47:29.029807+00 | 588.75
 529349 |           3 | 2023-09-27 13:43:57.406336+00 | 614.69
 733286 |           3 | 2023-10-19 15:14:47.740549+00 | 359.85
 263511 |           3 | 2024-01-15 10:05:51.665555+00 | 398.62
 115453 |           3 | 2024-06-11 18:02:51.326442+00 | 473.14
  38758 |           3 | 2024-09-07 23:17:18.02898+00  | 254.42
 818551 |           3 | 2024-09-29 21:18:52.879204+00 | 494.03
 298176 |           3 | 2024-11-01 04:43:50.533645+00 | 343.01
 789889 |           3 | 2024-12-27 14:51:54.473518+00 | 840.21
 795003 |           3 | 2025-01-17 23:10:49.224958+00 | 961.90
 135774 |           3 | 2025-03-14 15:27:50.707643+00 | 700.78
 881393 |           3 | 2025-06-24 11:11:44.245599+00 | 533.82
 665173 |           3 | 2025-08-25 05:04:37.836811+00 | 616.18
(34 rows)
```

Duas instruções para a página em vez de cinquenta e uma, seja N o que for. O plano é o que a aula
10 previria:

```
shop=# EXPLAIN ANALYZE SELECT id, customer_id, placed_at, total FROM orders WHERE customer_id = ANY(ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=45.13..443.26 rows=109 width=22) (actual time=0.045..0.214 rows=95 loops=1)
   Recheck Cond: (customer_id = ANY ('{1,2,3,4,5,6,7,8,9,10}'::integer[]))
   Heap Blocks: exact=93
   ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..45.08 rows=109 width=0) (actual time=0.022..0.022 rows=95 loops=1)
         Index Cond: (customer_id = ANY ('{1,2,3,4,5,6,7,8,9,10}'::integer[]))
 Planning Time: 0.566 ms
 Execution Time: 0.271 ms
(7 rows)
```

Uma varredura por bitmap pelo índice em `customer_id`, uma vez, para os dez ids — 95 linhas em
um quarto de milissegundo. Cinquenta ids são a mesma forma com um array mais longo, e cem mil ids são o
ponto em que o ORM manda o array em pedaços.

É o que o Django chama de `prefetch_related`, o Rails de `preload`, o SQLAlchemy de
`selectinload`, e o Hibernate alcança com `@BatchSize`. É a forma a preferir para uma relação
**para-muitos**, porque cada pedido volta uma vez e as colunas do cliente não se repetem em toda
linha.

## Uma consulta, com uma junção

A outra forma é a resposta da aula 5:

```
shop=# SELECT c.id, c.name, o.id AS order_id, o.total FROM customers c LEFT JOIN orders o ON o.customer_id = c.id WHERE c.id IN (1, 2, 3) ORDER BY c.id, o.id;
 id |     name     | order_id | total  
----+--------------+----------+--------
  1 | Igor Fontes  |    83957 | 824.88
  1 | Igor Fontes  |   106558 | 378.71
  1 | Igor Fontes  |   174320 | 629.38
  1 | Igor Fontes  |   186406 | 241.28
  1 | Igor Fontes  |   376517 | 449.14
  1 | Igor Fontes  |   436232 | 248.10
  1 | Igor Fontes  |   561192 | 826.20
  1 | Igor Fontes  |   563685 | 950.55
  1 | Igor Fontes  |   634580 | 508.08
  1 | Igor Fontes  |   712515 | 999.09
  1 | Igor Fontes  |   832622 | 292.93
  1 | Igor Fontes  |   867901 | 645.81
  2 | Ana Alves    |    66505 | 706.37
  2 | Ana Alves    |   153988 | 362.49
  2 | Ana Alves    |   261311 | 588.75
  2 | Ana Alves    |   377213 | 187.07
  2 | Ana Alves    |   681428 | 280.21
  2 | Ana Alves    |   750331 | 130.32
  2 | Ana Alves    |   808345 | 661.96
  2 | Ana Alves    |   817860 | 584.30
  2 | Ana Alves    |   906859 | 431.19
  2 | Ana Alves    |   973786 | 402.98
  3 | Elisa Fontes |    38758 | 254.42
  3 | Elisa Fontes |   115453 | 473.14
  3 | Elisa Fontes |   135774 | 700.78
  3 | Elisa Fontes |   263511 | 398.62
  3 | Elisa Fontes |   298176 | 343.01
  3 | Elisa Fontes |   529349 | 614.69
  3 | Elisa Fontes |   665173 | 616.18
  3 | Elisa Fontes |   733286 | 359.85
  3 | Elisa Fontes |   789889 | 840.21
  3 | Elisa Fontes |   795003 | 961.90
  3 | Elisa Fontes |   818551 | 494.03
  3 | Elisa Fontes |   881393 | 533.82
(34 rows)
```

Uma instrução, uma ida e volta, e as colunas do cliente estão em toda linha dos pedidos dele —
`Igor Fontes` doze vezes. O ORM lê as linhas de volta para um objeto cliente com doze
pedidos, e a repetição custa banda em vez de correção.

O `select_related` do Django, o `eager_load` do Rails, o `joinedload` do SQLAlchemy, o
`JOIN FETCH` do Hibernate. É a forma para uma relação **para-um** — o cliente de cada pedido, em
que a junção acrescenta algumas colunas a cada linha e não repete nada. É a forma errada para uma
para-muitos com pais largos, em que um cliente com cem pedidos são cem cópias do cliente.

O `includes` do Rails escolhe entre as duas por você, e toma a junção quando o `WHERE` menciona a
tabela juntada. Isso é conveniente e é uma decisão sendo tomada onde você não consegue ver, que é
exatamente o tipo de coisa que esta aula manda conferir no log.

## Qual das duas

| relação | forma | por quê |
|---|---|---|
| para-um (o cliente de um pedido) | junção | algumas colunas a mais por linha, nada repetido |
| para-muitos, pai estreito | qualquer uma | a repetição é pequena |
| para-muitos, pai largo ou muitos filhos | consulta à parte com o conjunto | a junção repetiria o pai por filho |
| filtrando pela tabela relacionada | junção | o `WHERE` tem que ver as duas |
| várias relações de uma vez | consultas à parte | juntar três relações para-muitos multiplica linhas |

A última linha é a multiplicação da aula 5 chegando num ORM: juntar clientes a pedidos e a
endereços numa instrução devolve pedidos × endereços linhas por cliente, e um mapeador que faz
isso em silêncio está produzindo um resultado correto e enorme.

## Onde pôr a instrução

Na consulta que começa o laço, e não no modelo. A maioria dos ORMs permite marcar uma relação
como sempre-ansiosa na classe, e é tentador, porque conserta o N+1 em todo lugar de uma vez.
Também carrega os pedidos em toda tela que busca um cliente, inclusive as que mostram um nome e
mais nada — o *peça menos* da aula 10, desfeito globalmente.

Então a instrução pertence a onde está o laço: esta página quer clientes com seus pedidos, aquela
página quer clientes sozinhos. Que é mais uma razão para ler o SQL emitido por página em vez de por
modelo.

## Conferindo que funcionou

As mesmas duas ferramentas. O `pg_stat_statements` depois da correção mostra a consulta de pedidos
com `calls` igual ao número de páginas renderizadas, não ao número de clientes; o log mostra duas
instruções por página em vez de cinquenta e uma. Uma correção aplicada no código e não confirmada
na contagem é uma correção que alguém vai descobrir que estava na relação errada — e a contagem é
mais barata que a descoberta.
