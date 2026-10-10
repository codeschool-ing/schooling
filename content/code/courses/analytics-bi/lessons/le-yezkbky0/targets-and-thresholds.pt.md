---
title: Metas, e as cores que as julgam
version: 1
---

A segunda comparação da lista é a meta. Uma meta não está nos dados: é uma decisão que o negócio
tomou, e precisa ficar guardada num lugar que uma consulta leia. Uma tabelinha na camada, digitada por
quem cuida do plano, basta:

```sql
CREATE TABLE semantic.revenue_target (month date PRIMARY KEY, target numeric(12,2) NOT NULL);
INSERT INTO semantic.revenue_target VALUES
  ('2026-01-01', 90000), ('2026-02-01', 95000), ('2026-03-01', 110000),
  ('2026-04-01', 125000), ('2026-05-01', 135000), ('2026-06-01', 145000);
```

```
lantern=# CREATE TABLE semantic.revenue_target (month date PRIMARY KEY, target numeric(12,2) NOT NULL);
CREATE TABLE

lantern=# INSERT INTO semantic.revenue_target VALUES
lantern-#   ('2026-01-01', 90000), ('2026-02-01', 95000), ('2026-03-01', 110000),
lantern-#   ('2026-04-01', 125000), ('2026-05-01', 135000), ('2026-06-01', 145000);
INSERT 0 6
```

Os números são do negócio, inventados para a Lantern como todo o resto. Depois, o realizado contra a
meta, mês a mês:

```sql
SELECT t.month, t.target, sum(o.net_revenue) AS actual,
       round(100 * sum(o.net_revenue) / t.target) AS attainment_pct
FROM semantic.revenue_target t
JOIN semantic.orders o ON date_trunc('month', o.order_date) = t.month
GROUP BY t.month, t.target
ORDER BY t.month;
```

```
lantern=# SELECT t.month, t.target, sum(o.net_revenue) AS actual,
lantern-#        round(100 * sum(o.net_revenue) / t.target) AS attainment_pct
lantern-# FROM semantic.revenue_target t
lantern-# JOIN semantic.orders o ON date_trunc('month', o.order_date) = t.month
lantern-# GROUP BY t.month, t.target
lantern-# ORDER BY t.month;
   month    |  target   |  actual   | attainment_pct 
------------+-----------+-----------+----------------
 2026-01-01 |  90000.00 |  87883.56 |             98
 2026-02-01 |  95000.00 |  88361.90 |             93
 2026-03-01 | 110000.00 | 117964.14 |            107
 2026-04-01 | 125000.00 | 119821.78 |             96
 2026-05-01 | 135000.00 | 140097.06 |            104
 2026-06-01 | 145000.00 |  75811.94 |             52
(6 rows)
```

Março e maio passaram das metas; janeiro, fevereiro e abril ficaram um pouco abaixo. Junho está em
52%, e você sabe por quê: dezessete dias de trinta. Um cartão mostrando o atingimento de junho contra a
meta do mês inteiro ficaria vermelho todo mês até os últimos dias dele. Proporcional a 17 de 30 dias, a
meta de junho é cerca de R$ 82.167, e os R$ 75.811,94 até agora são cerca de 92% dela — abaixo, e nada
parecido com 52%.

## Cores que julgam

Painéis gostam de colorir o atingimento: verde acima da meta, âmbar perto dela, vermelho abaixo. Três
cuidados, e o primeiro é sobre pessoas, e não números:

- **Nunca dependa só da cor.** Cerca de um homem em doze tem alguma deficiência de visão de cores, e
  vermelho contra verde é o par mais confundido. Ponha o número ou uma palavra ao lado da cor: *104% —
  acima da meta*.
- **Limites são definições.** Quem decidiu que 95% é âmbar e 90% é vermelho? Escreva isso no cartão ao
  lado da meta, com o dono, ou duas pessoas vão ler o mesmo âmbar de jeitos diferentes.
- **Uma cor num período parcial mente.** Junho está vermelho em 52% e no rumo, em 92% proporcional.
  Compare igual com igual, ou não pinte nada até o período fechar.
