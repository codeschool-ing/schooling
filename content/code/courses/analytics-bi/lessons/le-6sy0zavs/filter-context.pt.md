---
title: Contexto de filtro, que é um WHERE que você não escreveu
version: 1
---

Uma medida não tem valor fixo. `[Net Revenue]` é um número diferente em cada célula de cada visual, e
o que decide qual número é o **contexto de filtro**: o conjunto de filtros em vigor para aquela
célula.

Ponha `[Net Revenue]` numa matriz com `customers[region]` nas linhas, e um filtro na página marcando
o ano de 2026. O Power BI avalia a medida cinco vezes — uma por região, uma para o total — e cada vez
o contexto de filtro é diferente:

| célula | filtros em vigor |
|---|---|
| North | ano de 2026, região = North |
| South | ano de 2026, região = South |
| … | … |
| Total | ano de 2026 |

Os filtros chegam em `customers` e `calendar` e andam pelos relacionamentos até `orders`, onde o
`SUM` soma as linhas que sobraram. Em SQL, a matriz inteira é uma consulta que você poderia ter
escrito na aula 2:

```
lantern=# SELECT c.region, sum(o.net_revenue) AS net_revenue
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE o.order_date >= '2026-01-01'
lantern-# GROUP BY ROLLUP (c.region)
lantern-# ORDER BY c.region NULLS LAST;
  region   | net_revenue 
-----------+-------------
 North     |     3756.70
 Northeast |    56003.78
 South     |    99133.58
 Southeast |   471046.32
           |   629940.38
(5 rows)
```

**Contexto de filtro é só isso**: o `WHERE` vem do filtro da página, o `GROUP BY` das linhas da
matriz, e o join dos relacionamentos. A medida em DAX diz só `SUM`; o visual fornece o resto. O total
não é a soma das células feita pelo visual. É a medida avaliada de novo sem o filtro de região, e
é por isso que, para uma medida que não é uma soma simples, um total pode parecer não fechar e mesmo
assim estar certo.

A consequência prática: **uma medida é escrita uma vez e dá a resposta certa em todo visual**, porque
nunca diz que linhas cobre. É também por isso que ela é difícil de ler: a fórmula é curta porque o
contexto é invisível.
