---
title: Os clientes que não estão mais lá
version: 1
---

Uma frase ouvida em muitas lojas: *nossos clientes mais antigos são os melhores*. Os clientes da Lantern
que compraram pela primeira vez no primeiro trimestre dela, de janeiro a março de 2025, divididos entre os
que continuam ativos e os que não:

```
lantern=# WITH c AS (
lantern(#   SELECT customer_id, min(order_date) AS first_order, max(order_date) AS last_order,
lantern(#          count(*) FILTER (WHERE status = 'paid') AS paid_orders
lantern(#   FROM semantic.orders GROUP BY customer_id),
lantern-# asof AS (SELECT max(order_date) AS day FROM semantic.orders)
lantern-# SELECT last_order >= asof.day - 45 AS still_active,
lantern-#        count(*) AS customers, round(avg(paid_orders), 2) AS avg_paid_orders
lantern-# FROM c, asof
lantern-# WHERE first_order < '2025-04-01'
lantern-# GROUP BY 1 ORDER BY 1;
 still_active | customers | avg_paid_orders 
--------------+-----------+-----------------
 f            |        65 |            3.52
 t            |         3 |           11.67
(2 rows)
```

Os três que continuam ativos fizeram 11,67 pedidos pagos cada. Um relatório que olhasse só os clientes
ativos — os da lista *active* do CRM, os que um painel de "clientes atuais" mostra — diria que os primeiros
clientes fazem quase doze pedidos em média. **Os 65 que saíram não estão nesse relatório**, e a média deles
foi 3,52.

Isso é o **viés de sobrevivência**: tirar uma conclusão dos membros de um grupo que passaram por algum
filtro, como se eles fossem o grupo inteiro. O filtro aqui é "ainda ativo", e ele selecionou justamente os
clientes que compram com frequência. A conclusão "quanto mais ficam, mais compram" está invertida — eles
ficaram *porque* compram; a maior parte da geração deles não ficou.

Ele aparece em toda lista que foi filtrada pelo resultado:

- **Só clientes ativos.** Toda média sobre os clientes de hoje exclui todo mundo que saiu, e quem saiu é
  justamente o assunto de uma pergunta sobre retenção.
- **Só campanhas bem-sucedidas.** Uma apresentação das três campanhas que deram certo, das doze que
  rodaram.
- **Respostas a uma pesquisa de satisfação.** Quem responde não é quem saiu em silêncio.

A grade de coortes da aula 9 é a defesa embutida: ela começa de todo mundo que chegou e conta quem ficou,
em vez de começar de quem ficou.

A pergunta que pega isso: **quem foi tirado desta lista antes de eu vê-la, e pelo quê?**
