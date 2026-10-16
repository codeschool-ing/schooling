---
title: Divisões, e a região com cinco pedidos
version: 1
---

A terceira pergunta da lista — de onde vem o dinheiro — é uma divisão, e uma divisão tem uma armadilha
que cresce com o número de pedaços. Maio de 2026 por região:

```
lantern=# SELECT c.region, count(*) AS orders, sum(o.net_revenue) AS net_revenue
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE o.order_date >= '2026-05-01' AND o.order_date < '2026-06-01'
lantern-# GROUP BY c.region ORDER BY net_revenue DESC;
  region   | orders | net_revenue 
-----------+--------+-------------
 Southeast |    657 |   106548.18
 South     |    139 |    24688.47
 Northeast |     54 |     8094.39
 North     |      5 |      766.02
(4 rows)
```

O Sudeste é três quartos do mês. O Norte são cinco pedidos e R$ 766,02. Um painel que mostra a
variação de cada região sobre o mês anterior num cartão do mesmo tamanho dá a esses cinco pedidos o
mesmo peso na página que aos 657 do Sudeste — e números pequenos se mexem muito:

```
lantern=# SELECT to_char(date_trunc('month', o.order_date), 'YYYY-MM') AS month, count(*) AS orders,
lantern-#        sum(o.net_revenue) AS net_revenue
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE c.region = 'North' AND o.order_date >= '2026-01-01'
lantern-# GROUP BY 1 ORDER BY 1;
  month  | orders | net_revenue 
---------+--------+-------------
 2026-01 |      6 |      424.51
 2026-02 |      7 |     1140.91
 2026-03 |      4 |      396.30
 2026-04 |      5 |      406.10
 2026-05 |      5 |      766.02
 2026-06 |      3 |      622.86
(6 rows)
```

O Norte foi de R$ 424,51 em janeiro para R$ 1.140,91 em fevereiro, um aumento de 169%, em sete pedidos.
Um único escritório pedindo uma vez faz isso. **Uma variação percentual sobre um punhado de eventos é
ruído vestido de descoberta**, e a aula 10 volta a isso como um dos jeitos mais comuns de um número
verdadeiro enganar.

O que um painel pode fazer a respeito:

- **Mostrar a contagem ao lado da taxa.** "+169% (7 pedidos)" se lê bem diferente de "+169%".
- **Agrupar os pedaços pequenos.** Abaixo de certo número de pedidos, uma região entra em "outras
  regiões", e a regra para isso fica escrita na página.
- **Ordenar por tamanho, e não por nome.** A divisão acima está ordenada pela receita líquida, então o
  olho encontra o Sudeste primeiro e o Norte por último, que é a ordem de importância deles para o
  negócio.
