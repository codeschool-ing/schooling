---
title: Razões, e qual média você quis dizer
version: 1
---

Muitas das métricas que um negócio acompanha são razões: receita por pedido, pedidos por cliente,
conversão como compras por visita. Uma razão tem duas partes, e pode ser tirada a média de dois
jeitos que dão dois números diferentes. O valor médio do pedido da Lantern, perguntado dos dois
jeitos:

```
lantern=# SELECT round(sum(gross_cents) / count(*) / 100.0, 2) AS per_order
lantern-# FROM order_totals WHERE customer_id <> 1;
 per_order 
-----------
    170.33
(1 row)

lantern=# SELECT round(avg(customer_avg) / 100.0, 2) AS per_customer
lantern-# FROM (SELECT customer_id, avg(gross_cents) AS customer_avg
lantern(#       FROM order_totals WHERE customer_id <> 1
lantern(#       GROUP BY customer_id) AS c;
 per_customer 
--------------
       156.10
(1 row)
```

O primeiro é a **razão das somas**: todo o dinheiro dividido por todos os pedidos, R$ 170,33. O
segundo é a **média das razões**: a média de pedido de cada cliente, e depois a média dessas, R$
156,10. A diferença não é arredondamento. No primeiro, um cliente com quarenta pedidos pesa
quarenta vezes mais que um cliente com um; no segundo, cada cliente pesa igual. Escritórios pedem
com frequência e em grande quantidade, então puxam o primeiro número para cima mais que o segundo.

Os dois são legítimos, e respondem a perguntas diferentes:

| | responde | pondera |
|---|---|---|
| razão das somas | quanto traz um pedido, em média? | cada pedido igual |
| média das razões | quanto um cliente típico gasta por pedido? | cada cliente igual |

**A definição precisa dizer qual.** Uma ferramenta que tira a média de uma coluna de razões por
cliente, ou um painel que tira a média de uma coluna de taxas diárias de conversão, calcula o
segundo tipo, quer alguém tenha querido ou não. A aula 4 encontra a mesma armadilha na linguagem de
fórmulas do Power BI, onde ela está a um nome de função de distância.

Uma regra prática que acerta muito mais do que erra: quando a métrica é "do negócio" — a conversão
da loja, o valor de pedido da loja —, calcule a razão das somas, somando o numerador e o
denominador separadamente e dividindo uma vez no fim.
