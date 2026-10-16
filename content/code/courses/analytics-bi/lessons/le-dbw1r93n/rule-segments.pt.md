---
title: Segmentos a partir de duas regras
version: 1
---

Os segmentos mais simples vêm de regras que dá para dizer em voz alta. O modelo da aula 7 já tem duas:
`health`, que vem de quão recentemente um cliente comprou, e `orders`, de com que frequência. Corte cada
uma em três faixas e cruze:

```
lantern=# SELECT health,
lantern-#        CASE WHEN orders = 1 THEN '1 order'
lantern-#             WHEN orders <= 3 THEN '2-3 orders'
lantern-#             ELSE '4+ orders' END AS frequency,
lantern-#        count(*) AS customers, sum(net_revenue) AS net_revenue
lantern-# FROM activation.crm_contacts
lantern-# WHERE orders > 0
lantern-# GROUP BY 1, 2 ORDER BY 1, 2;
 health  | frequency  | customers | net_revenue 
---------+------------+-----------+-------------
 active  | 1 order    |       306 |    42047.51
 active  | 2-3 orders |       340 |   109079.02
 active  | 4+ orders  |       321 |   330774.49
 at risk | 1 order    |       209 |    29275.05
 at risk | 2-3 orders |       227 |    78446.82
 at risk | 4+ orders  |       173 |   153117.26
 lapsed  | 1 order    |       473 |    56773.19
 lapsed  | 2-3 orders |       416 |   122897.05
 lapsed  | 4+ orders  |       183 |   124346.01
(9 rows)
```

Nove segmentos, cada um uma frase. Três deles carregam a maior parte das decisões:

- **Ativos, quatro pedidos ou mais**: 321 clientes, 12% da base, e R$ 330.774,49 — 32% de toda a receita
  que a loja já fez. São os que não se pode perder; não precisam de desconto, e um programa que lhes dá
  um é dinheiro dado a gente que compraria de qualquer jeito.
- **Em risco, quatro pedidos ou mais**: 173 clientes que compravam com frequência e estão quietos há 45 a
  120 dias. R$ 153.117,26 entre eles, cerca de R$ 885 cada. É a lista de reconquista da aula 8 sem o
  filtro de escritório, e o segmento em que uma ligação tem mais chance de se pagar.
- **Sumidos, um pedido**: 473 clientes, o maior grupo, e R$ 56.773,19. Uma compra, há mais de 120 dias.
  Muitos vieram por uma promoção, e é o segmento em que mais esforço se desperdiça.

Duas propriedades tornam esses segmentos úteis, e não só arrumados. **As faixas querem dizer algo**: 45
dias é onde a aula 2 viu terminar três de cada quatro intervalos entre pedidos, e *um pedido* é uma linha
real — um cliente que nunca voltou é um caso diferente de um que voltou uma vez. E **todo cliente cai em
exatamente uma célula**, então as nove somam os 2.648 clientes com pedido, e ninguém é contado duas vezes
nem se perde.
