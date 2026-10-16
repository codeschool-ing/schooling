---
title: RFM, e o que o ntile faz com empates
version: 1
---

Os segmentos da seção anterior são um caso pequeno de um método que times de marketing usam há décadas:
**RFM**, de recência, frequência e valor monetário. Cada cliente ganha uma nota de 1 a 5 em cada um dos
três, e as notas juntas dão nome a um segmento — 5-5-5 é o melhor cliente, 1-1-1 o mais perdido.

A receita de costume calcula cada nota como um **quintil**: ordenar os clientes e cortá-los em cinco
grupos de tamanho igual. Em SQL isso é `ntile(5)`, e na frequência dá errado de um jeito que vale ver:

```
lantern=# SELECT f, min(orders), max(orders), count(*) AS customers
lantern-# FROM (SELECT orders, ntile(5) OVER (ORDER BY orders) AS f
lantern(#       FROM activation.crm_contacts WHERE orders > 0) x
lantern-# GROUP BY f ORDER BY f;
 f | min | max | customers 
---+-----+-----+-----------
 1 |   1 |   1 |       530
 2 |   1 |   2 |       530
 3 |   2 |   2 |       530
 4 |   2 |   4 |       529
 5 |   4 |  16 |       529
(5 rows)
```

Cinco grupos de 529 ou 530, exatamente como pedido — e clientes com **um pedido** estão na nota 1 *e* na
nota 2. Clientes com dois pedidos estão espalhados pelas notas 2, 3 e 4. O `ntile` corta numa posição, não
num valor, então quando 988 clientes têm o mesmo número de pedidos ele os parte onde a linha 530 cair, e
qual cliente fica de cada lado depende da ordem em que as linhas voltam.

Dois clientes com históricos idênticos, um com nota 1 e outro com nota 2, podem receber e-mails
diferentes. Ninguém consegue explicar por quê, porque não há motivo.

Duas saídas, e a primeira é a preferível:

- **Limites fixos**, como os da seção anterior: 1 pedido, 2 a 3, 4 ou mais. Clientes iguais sempre têm
  notas iguais, as faixas podem ser explicadas, e não se movem quando os clientes do mês seguinte chegam.
- **Postos que respeitam empates**, como `percent_rank()`, cortados em cinco depois. Os empates ficam
  juntos, ao preço de grupos de tamanhos diferentes.

Quintis funcionam bem num valor com poucos empates, como receita medida até o centavo. Numa contagem com
um punhado de valores distintos — pedidos, visitas, chamados — eles inventam distinções que os dados não
têm.
