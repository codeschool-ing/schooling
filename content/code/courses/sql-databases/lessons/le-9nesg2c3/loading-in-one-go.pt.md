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
   id   | customer_id |          placed_at          | total  
--------+-------------+-----------------------------+--------
 258406 |           1 | 2023-12-29 04:15:09.9072+00 | 707.73
   3664 |           1 | 2025-06-11 16:30:37.6704+00 | 537.02
 933519 |           1 | 2025-07-23 19:30:48.384+00  | 996.95
 856379 |           2 | 2023-01-16 09:35:05.568+00  |  75.34
 548786 |           2 | 2023-03-04 12:53:26.9088+00 | 761.50
 418066 |           2 | 2023-03-11 05:06:16.416+00  | 898.33
 132296 |           2 | 2023-06-05 23:12:51.5232+00 | 480.19
 469617 |           2 | 2023-07-01 21:12:32.1984+00 | 187.07
 548309 |           2 | 2023-08-04 11:18:44.208+00  | 248.10
 339910 |           2 | 2023-09-25 09:19:04.2816+00 | 410.59
 179551 |           2 | 2023-10-09 01:41:05.0208+00 |  84.13
  82698 |           2 | 2024-02-16 13:46:51.1392+00 | 767.87
 813068 |           2 | 2024-05-04 09:01:28.4736+00 |  30.91
 468689 |           2 | 2024-11-15 21:47:22.56+00   | 449.14
  78609 |           2 | 2025-01-09 14:25:20.1792+00 | 824.88
 875237 |           2 | 2025-02-27 00:28:56.208+00  | 280.21
 315081 |           2 | 2025-02-28 03:37:02.7264+00 | 588.75
 199093 |           2 | 2025-08-23 21:31:48.4032+00 | 629.38
 812773 |           2 | 2025-09-27 16:48:58.752+00  | 508.08
 672465 |           3 | 2023-03-19 11:35:05.28+00   | 614.69
 410227 |           3 | 2023-03-20 00:35:30.1056+00 | 918.16
 505327 |           3 | 2023-06-08 14:29:04.9056+00 | 377.35
 937359 |           3 | 2023-06-22 19:57:59.184+00  |  39.77
 983688 |           3 | 2023-07-25 08:36:50.688+00  |  29.13
 690660 |           3 | 2023-10-28 14:22:25.0464+00 | 718.48
 699978 |           3 | 2024-06-10 06:32:00.672+00  | 468.04
 394239 |           3 | 2024-08-15 02:02:41.3664+00 | 938.50
 160670 |           3 | 2024-08-19 09:50:06.288+00  | 538.64
 772914 |           3 | 2024-12-17 10:44:42.3168+00 | 928.93
 708466 |           3 | 2024-12-24 02:45:46.1952+00 | 631.79
 370786 |           3 | 2025-02-06 17:23:09.5424+00 | 676.42
 517439 |           3 | 2025-09-10 18:10:11.5392+00 |  98.63
(32 rows)
```

Duas instruções para a página em vez de cinquenta e uma, seja N o que for. O plano é o que a aula
10 previria:

```
shop=# EXPLAIN ANALYZE SELECT id, customer_id, placed_at, total FROM orders WHERE customer_id = ANY(ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=45.13..446.72 rows=110 width=22) (actual time=0.047..0.461 rows=88 loops=1)
   Recheck Cond: (customer_id = ANY ('{1,2,3,4,5,6,7,8,9,10}'::integer[]))
   Heap Blocks: exact=88
   ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..45.08 rows=110 width=0) (actual time=0.024..0.025 rows=88 loops=1)
         Index Cond: (customer_id = ANY ('{1,2,3,4,5,6,7,8,9,10}'::integer[]))
 Planning Time: 0.698 ms
 Execution Time: 0.514 ms
(7 rows)
```

Uma varredura por bitmap pelo índice em `customer_id`, uma vez, para os dez ids — 88 linhas em
meio milissegundo. Cinquenta ids são a mesma forma com um array mais longo, e cem mil ids são o
ponto em que o ORM manda o array em pedaços.

É o que o Django chama de `prefetch_related`, o Rails de `preload`, o SQLAlchemy de
`selectinload`, e o Hibernate alcança com `@BatchSize`. É a forma a preferir para uma relação
**para-muitos**, porque cada pedido volta uma vez e as colunas do cliente não se repetem em toda
linha.

## Uma consulta, com uma junção

A outra forma é a resposta da aula 5:

```
shop=# SELECT c.id, c.name, o.id AS order_id, o.total FROM customers c LEFT JOIN orders o ON o.customer_id = c.id WHERE c.id IN (1, 2, 3) ORDER BY c.id, o.id;
 id |      name       | order_id | total  
----+-----------------+----------+--------
  1 | Helena Santos   |     3664 | 537.02
  1 | Helena Santos   |   258406 | 707.73
  1 | Helena Santos   |   933519 | 996.95
  2 | Bruno Costa     |    78609 | 824.88
  2 | Bruno Costa     |    82698 | 767.87
  2 | Bruno Costa     |   132296 | 480.19
  2 | Bruno Costa     |   179551 |  84.13
  2 | Bruno Costa     |   199093 | 629.38
  2 | Bruno Costa     |   315081 | 588.75
  2 | Bruno Costa     |   339910 | 410.59
  2 | Bruno Costa     |   418066 | 898.33
  2 | Bruno Costa     |   468689 | 449.14
  2 | Bruno Costa     |   469617 | 187.07
  2 | Bruno Costa     |   548309 | 248.10
  2 | Bruno Costa     |   548786 | 761.50
  2 | Bruno Costa     |   812773 | 508.08
  2 | Bruno Costa     |   813068 |  30.91
  2 | Bruno Costa     |   856379 |  75.34
  2 | Bruno Costa     |   875237 | 280.21
  3 | Fábio Carvalho |   160670 | 538.64
  3 | Fábio Carvalho |   370786 | 676.42
  3 | Fábio Carvalho |   394239 | 938.50
  3 | Fábio Carvalho |   410227 | 918.16
  3 | Fábio Carvalho |   505327 | 377.35
  3 | Fábio Carvalho |   517439 |  98.63
  3 | Fábio Carvalho |   672465 | 614.69
  3 | Fábio Carvalho |   690660 | 718.48
  3 | Fábio Carvalho |   699978 | 468.04
  3 | Fábio Carvalho |   708466 | 631.79
  3 | Fábio Carvalho |   772914 | 928.93
  3 | Fábio Carvalho |   937359 |  39.77
  3 | Fábio Carvalho |   983688 |  29.13
(32 rows)
```

Uma instrução, uma ida e volta, e as colunas do cliente estão em toda linha dos pedidos dele —
`Bruno Costa` dezesseis vezes. O ORM lê as linhas de volta para um objeto cliente com dezesseis
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
