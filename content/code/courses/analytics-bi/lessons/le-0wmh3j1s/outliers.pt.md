---
title: Valores atípicos, e as três coisas que um deles pode ser
version: 1
---

Um **valor atípico** (*outlier*) é um valor longe dos outros. A palavra soa como veredito e é só
uma observação: se a linha é um erro, um tipo diferente de cliente, ou um evento real que
aconteceu uma vez, é algo que você descobre. Apagar atípicos por serem atípicos é o jeito mais
comum de deixar uma tabela mais arrumada e fazê-la dizer algo falso.

## Encontrando-os

Uma regra convencional, do estatístico John Tukey, traça duas **cercas** a um IQR e meio além dos
quartis e chama de atípico tudo o que fica fora delas:

```
lantern=# WITH q AS (
lantern(#   SELECT percentile_cont(0.25) WITHIN GROUP (ORDER BY gross_cents) AS q1,
lantern(#          percentile_cont(0.75) WITHIN GROUP (ORDER BY gross_cents) AS q3
lantern(#   FROM order_totals)
lantern-# SELECT q1 - 1.5 * (q3 - q1) AS low_fence,
lantern-#        q3 + 1.5 * (q3 - q1) AS high_fence,
lantern-#        (SELECT count(*) FROM order_totals, q
lantern(#          WHERE gross_cents > q3 + 1.5 * (q3 - q1)) AS above
lantern-# FROM q;
 low_fence | high_fence | above 
-----------+------------+-------
  -13322.5 |    34977.5 |   591
(1 row)
```

A cerca inferior é negativa, então nenhum pedido pode ficar abaixo dela; a superior é R$ 349,78,
e 591 pedidos estão acima. Isso é mais de um pedido em doze, o que é demais para serem erros de
digitação. A regra encontrou algo real — o quê, ela não sabe dizer:

```
lantern=# SELECT c.segment, count(*) AS above_fence
lantern-# FROM order_totals t JOIN customers c USING (customer_id)
lantern-# WHERE t.gross_cents > 34977.5
lantern-# GROUP BY c.segment;
 segment | above_fence 
---------+-------------
 office  |         428
 home    |         163
(2 rows)
```

428 dos 591 são pedidos de escritório, e 428 é a maior parte dos 684 pedidos de escritório que
existem. **A regra estava medindo a população errada**: comparado aos pedidos home, um pedido de
escritório está longe; comparado a outros pedidos de escritório, é comum. Essa é a segunda coisa
que um atípico pode ser, e a resposta certa não é removê-lo, e sim parar de misturá-lo com os
outros.

## Os do topo

```
lantern=# SELECT t.order_id, t.customer_id, c.segment, t.gross_cents / 100 AS gross_brl
lantern-# FROM order_totals t JOIN customers c USING (customer_id)
lantern-# ORDER BY t.gross_cents DESC LIMIT 6;
 order_id | customer_id | segment | gross_brl 
----------+-------------+---------+-----------
      412 |         561 | home    |     23980
      415 |         295 | home    |      9180
      431 |         191 | home    |      8900
     2010 |        1242 | office  |      3974
     5986 |        1867 | office  |      3778
     4280 |        1215 | office  |      3446
(6 rows)
```

Os três maiores são clientes home, com pedidos de R$ 23.980, R$ 9.180 e R$ 8.900. Uma pessoa
comprando café para casa não gasta R$ 23.980 num pedido, e os três seguintes, todos escritórios,
gastam menos de R$ 4.000. Olhe as linhas por trás deles, contra a tabela de preços:

```
lantern=# SELECT l.order_id, l.product_id, l.quantity, l.unit_cents, p.price_cents
lantern-# FROM order_lines l JOIN products p USING (product_id)
lantern-# WHERE l.unit_cents <> p.price_cents
lantern-# ORDER BY l.order_id;
 order_id | product_id | quantity | unit_cents | price_cents 
----------+------------+----------+------------+-------------
        1 |          1 |        1 |          1 |        3490
        9 |          1 |        1 |          1 |        3490
        9 |          1 |        1 |          1 |        3490
       20 |          1 |        1 |          1 |        3490
       20 |          1 |        1 |          1 |        3490
       20 |          1 |        1 |          1 |        3490
       32 |          1 |        1 |          1 |        3490
      412 |          2 |        2 |    1199000 |       11990
      415 |          3 |        2 |     459000 |        4590
      431 |         10 |        1 |     890000 |        8900
(10 rows)
```

Dois defeitos diferentes numa consulta só. Os pedidos 412, 415 e 431 têm cada um uma linha cujo
preço unitário é exatamente cem vezes o do produto: 1.199.000 centavos por um pacote que custa
11.990. É a assinatura de uma conversão feita duas vezes — um preço em reais transformado em
centavos por alguém que não sabia que ele já estava em centavos. **Esse é o primeiro tipo: um
erro**, e ele tem um valor correto que pode ser calculado, então a correção pertence aos dados,
feita por quem cuida da carga, e informada — e não dividida por cem em silêncio na sua consulta e
esquecida.

As outras sete linhas são do cliente 1, cujas linhas custam um centavo.

## Os de baixo

```
lantern=# SELECT order_id, customer_id, gross_cents FROM order_totals ORDER BY gross_cents LIMIT 5;
 order_id | customer_id | gross_cents 
----------+-------------+-------------
       32 |           1 |           1
        1 |           1 |           1
        9 |           1 |           2
       20 |           1 |           3
     6458 |         965 |        1590
(5 rows)

lantern=# SELECT customer_id, signed_up, state, channel FROM customers WHERE customer_id = 1;
 customer_id | signed_up  | state | channel 
-------------+------------+-------+---------
           1 | 2025-01-02 | SP    | email
(1 row)
```

Quatro pedidos de um a três centavos, todos do cliente 1, que se cadastrou no segundo dia da loja
pelo canal `email`. Pedidos de um centavo do produto mais barato são o que um time faz quando testa
o checkout na loja de verdade. **Isso não é um atípico no sentido estatístico** — com um centavo,
ele fica bem dentro das cercas — e continua sendo uma linha que não deveria estar num relatório de
vendas. A análise exploratória o encontra olhando o mínimo, e é por isso que o mínimo e o máximo
sempre valem uma consulta cada.

## Decidindo

Três tipos, três respostas:

| o que é | aqui | o que fazer |
|---|---|---|
| um erro | as três linhas com preço cem vezes maior | corrigir na origem, e dizer quantas linhas foram afetadas |
| uma população diferente | pedidos de escritório | analisar separadamente; nunca tirar média junto com o resto |
| um evento real e raro | nenhum ainda — um cliente que de fato comprou R$ 9.000 de café | manter, e mostrar a mediana ao lado da média |

A conta interna de teste é uma quarta coisa que não é nenhuma das três, e dados reais a têm em toda
parte: linhas produzidas pela própria empresa. **O que quer que você exclua, escreva o quê e por
quê, junto do número**: "excluindo o cliente 1, a conta de teste da loja (4 pedidos)". Um número
com uma exclusão silenciosa não pode ser reproduzido pela próxima pessoa que perguntar.
