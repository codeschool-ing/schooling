---
title: Uma primeira olhada, antes de qualquer pergunta
version: 1
---

O jeito errado de começar é pela pergunta. Alguém pede o pedido médio do último trimestre, você
escreve `SELECT avg(...)`, sai um número, e o número vai para um slide. Nada nessa sequência
perguntou se a tabela guarda o que o nome dela diz, se falta um dia, ou se um pedido em mil é um
erro de digitação que vale dez mil reais.

**Análise exploratória é a hora que você passa com uma tabela antes de confiar nela.** Ela
responde três perguntas, em ordem: o que há aqui, como é uma linha normal, e quais linhas não são
normais. Esta aula as faz às tabelas da Lantern, e todo defeito que ela encontra foi plantado pelo
script — mas cada um é um defeito que dados reais têm, e as consultas que os encontram são as que
você vai usar no trabalho.

## O que há aqui

```
lantern=# \dt
           List of relations
 Schema |     Name     | Type  | Owner 
--------+--------------+-------+-------
 shop   | customers    | table | ana
 shop   | order_lines  | table | ana
 shop   | orders       | table | ana
 shop   | products     | table | ana
 shop   | web_events   | table | ana
 shop   | web_sessions | table | ana
(6 rows)
```

Seis tabelas. `products` e `customers` descrevem coisas; `orders` e `order_lines` registram
vendas; `web_sessions` e `web_events` registram visitas ao site, que as aulas 9 e 10 usam. As
primeiras perguntas a fazer a qualquer tabela são quantas linhas ela tem e que intervalo ela
cobre:

```
lantern=# SELECT count(*) AS customers, min(signed_up), max(signed_up) FROM customers;
 customers |    min     |    max     
-----------+------------+------------
      2650 | 2025-01-02 | 2026-06-17
(1 row)

lantern=# SELECT count(*) AS orders, min(ordered_at), max(ordered_at) FROM orders;
 orders |          min           |          max           
--------+------------------------+------------------------
   7102 | 2025-01-02 19:49:00-03 | 2026-06-17 23:55:00-03
(1 row)

lantern=# SELECT status, count(*) FROM orders GROUP BY status;
  status  | count 
----------+-------
 refunded |   257
 paid     |  6845
(2 rows)
```

Três fatos para guardar. Os clientes se cadastraram de 2 de janeiro de 2025 a 17 de junho de 2026.
O último pedido foi feito às 23:55 de 17 de junho — o `-03` é a diferença de São Paulo para o
UTC, que a configuração da última seção fez o banco imprimir. E 257 dos 7.102 pedidos foram
estornados: **um total de "pedidos" que os inclui é um número diferente de um que não os
inclui**, e esse é o assunto inteiro da aula 2.

## A granularidade de cada tabela

A **granularidade** de uma tabela é o que uma linha representa. Em `orders`, uma linha é um
pedido; em `order_lines`, é um produto dentro de um pedido, então um pedido de três produtos tem
três linhas. Errar a granularidade é o jeito mais comum de dobrar um total, e conferir é barato:

```
lantern=# SELECT count(*) AS lines, count(DISTINCT order_id) AS orders FROM order_lines;
 lines | orders 
-------+--------
 11362 |   7102
(1 row)

lantern=# SELECT count(*) AS orders_without_lines
lantern-# FROM orders o
lantern-# WHERE NOT EXISTS (SELECT 1 FROM order_lines l WHERE l.order_id = o.order_id);
 orders_without_lines 
----------------------
                    0
(1 row)
```

11.362 linhas em 7.102 pedidos distintos, e nenhum pedido sem linha. Os dois fatos importam: o
primeiro diz que contar linhas de `order_lines` conta produtos, não pedidos; o segundo diz que um
join de pedidos com linhas não perde nada. **Escreva a granularidade da primeira vez que você a
conferir.** É a frase sobre a qual a aula 3 constrói um modelo inteiro.
