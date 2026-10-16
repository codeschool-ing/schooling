---
title: Escolher onde uma comparação começa
version: 1
---

Quanto a Lantern cresceu até maio de 2026? Depende de com o que maio é comparado:

```
lantern=# WITH m AS (
lantern(#   SELECT date_trunc('month', order_date)::date AS month, sum(net_revenue) AS net_revenue
lantern(#   FROM semantic.orders GROUP BY 1)
lantern-# SELECT b.month AS compared_with, b.net_revenue AS then,
lantern-#        may.net_revenue AS may_2026,
lantern-#        round(100.0 * (may.net_revenue - b.net_revenue) / b.net_revenue, 1) AS change_pct
lantern-# FROM m b, m may
lantern-# WHERE may.month = '2026-05-01'
lantern-#   AND b.month IN ('2025-05-01', '2025-11-01', '2026-04-01')
lantern-# ORDER BY b.month;
 compared_with |   then    | may_2026  | change_pct 
---------------+-----------+-----------+------------
 2025-05-01    |  21811.31 | 140097.06 |      542.3
 2025-11-01    |  90630.78 | 140097.06 |       54.6
 2026-04-01    | 119821.78 | 140097.06 |       16.9
(3 rows)
```

Os três estão certos e vêm da mesma tabela. Contra maio de 2025, **+542,3%**: um ano antes a loja era
pequena. Contra novembro de 2025, **+54,6%**: o pico da Black Friday. Contra abril de 2026, **+16,9%**: o
mês anterior. Um relatório que quisesse um crescimento espetacular escolheria o primeiro; um que quisesse
dizer que o pico da campanha foi superado escolheria o segundo. O contrário também funciona: dezembro de
2025 contra novembro é uma queda de 17%, numa loja que cresceu em quase todos os outros meses.

Escolher uma janela é inevitável, então a defesa não é evitá-la, e sim **escolhê-la antes de ver o
resultado**, por um motivo que tenha a ver com a pergunta:

- **O mês contra o mesmo mês do ano anterior** tira as estações, e por isso é o padrão para um negócio com
  Black Friday. Ele exige que o negócio fosse o mesmo tipo de negócio um ano antes, o que a Lantern de maio
  de 2025 mal era.
- **O mês contra o mês anterior** responde "ainda está se mexendo?", e sofre com todas as estações.
- **Contra um pico ou um vale** quase nunca é a pergunta certa, e é exatamente a comparação que se escolhe
  depois de olhar.

Melhor ainda, **mostre a série** em vez de uma comparação só, como o painel da aula 6 fez com doze meses de
barras. Uma série não pode ser escolhida a dedo, porque todo começo fica visível.

A pergunta que pega isso: **a conclusão sobreviveria a outro mês de partida?**
