---
title: CALCULATE, que muda os filtros
version: 1
---

Às vezes uma medida precisa de um número de um contexto diferente daquele em que está. A
participação de cada região na receita do ano precisa, em toda linha, da receita de **todas** as
regiões. O `CALCULATE` do DAX avalia uma expressão com o contexto de filtro mudado:

```
Net Revenue All Regions = CALCULATE ( [Net Revenue], ALL ( customers ) )

Share of Net Revenue = DIVIDE ( [Net Revenue], [Net Revenue All Regions] )
```

(Não rodou.) `ALL ( customers )` remove todo filtro sobre a tabela de clientes — a região da linha —
e mantém os outros, então o ano do filtro da página continua valendo. Em SQL, a mesma coisa é uma
função de janela, cujo `OVER ()` vazio quer dizer "todas as linhas do resultado":

```
lantern=# SELECT c.region,
lantern-#        round(100 * sum(o.net_revenue) / sum(sum(o.net_revenue)) OVER (), 1) AS share_pct
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE o.order_date >= '2026-01-01'
lantern-# GROUP BY c.region ORDER BY share_pct DESC;
  region   | share_pct 
-----------+-----------
 Southeast |      74.8
 South     |      15.7
 Northeast |       8.9
 North     |       0.6
(4 rows)
```

O Sudeste é três quartos do ano até agora, e o Norte menos de um por cento.

O `CALCULATE` também pode acrescentar um filtro em vez de tirar. Uma medida para uma região, seja o
que for que a matriz mostre:

```
Net Revenue South = CALCULATE ( [Net Revenue], customers[region] = "South" )
```

```
lantern=# SELECT sum(o.net_revenue) AS net_revenue_south
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE o.order_date >= '2026-01-01' AND c.region = 'South';
 net_revenue_south 
-------------------
          99133.58
(1 row)
```

R$ 99.133,58, o mesmo número da linha do Sul na matriz da última seção — mas, como medida, ela dá
esse número em toda linha, inclusive na do Norte, porque troca o filtro de região pelo próprio. É o
comportamento que surpreende, e é a mesma regra nas duas vezes: **os filtros dentro do `CALCULATE`
vencem os filtros do visual na mesma coluna.**
