---
title: Inteligência de tempo, e do que ela precisa
version: 1
---

As comparações que um negócio mais pede são contra o tempo: o ano até agora, o mesmo mês do ano
passado. O DAX tem funções para as duas, e elas só funcionam com uma tabela de datas marcada, que é
por que a `calendar` do modelo importa:

```
Net Revenue YTD = TOTALYTD ( [Net Revenue], calendar[day] )

Net Revenue Same Month Last Year =
    CALCULATE ( [Net Revenue], SAMEPERIODLASTYEAR ( calendar[day] ) )
```

(Não rodou.) O `TOTALYTD` muda o contexto de filtro para "todo dia de primeiro de janeiro até o
último dia do contexto atual"; o `SAMEPERIODLASTYEAR` desloca os dias atuais um ano para trás. O SQL
do primeiro é uma soma acumulada, uma função de janela ordenada por mês:

```
lantern=# SELECT k.month,
lantern-#        sum(o.net_revenue) AS net_revenue,
lantern-#        sum(sum(o.net_revenue)) OVER (ORDER BY k.month) AS net_revenue_ytd
lantern-# FROM semantic.orders o JOIN semantic.calendar k ON k.day = o.order_date
lantern-# WHERE k.month >= '2026-01-01'
lantern-# GROUP BY k.month ORDER BY k.month;
   month    | net_revenue | net_revenue_ytd 
------------+-------------+-----------------
 2026-01-01 |    87883.56 |        87883.56
 2026-02-01 |    88361.90 |       176245.46
 2026-03-01 |   117964.14 |       294209.60
 2026-04-01 |   119821.78 |       414031.38
 2026-05-01 |   140097.06 |       554128.44
 2026-06-01 |    75811.94 |       629940.38
(6 rows)
```

A coluna acumulada no ano chega a R$ 294.209,60 no fim de março, o trimestre a que o financeiro e o
Metabase também chegaram. E a comparação com o ano passado:

```
lantern=# SELECT k.month,
lantern-#        sum(o.net_revenue) AS net_revenue,
lantern-#        (SELECT sum(o2.net_revenue) FROM semantic.orders o2
lantern(#          WHERE o2.order_date >= k.month - interval '1 year'
lantern(#            AND o2.order_date < k.month - interval '1 year' + interval '1 month') AS same_month_last_year
lantern-# FROM semantic.orders o JOIN semantic.calendar k ON k.day = o.order_date
lantern-# WHERE k.month BETWEEN '2026-03-01' AND '2026-05-01'
lantern-# GROUP BY k.month ORDER BY k.month;
   month    | net_revenue | same_month_last_year 
------------+-------------+----------------------
 2026-03-01 |   117964.14 |              9769.26
 2026-04-01 |   119821.78 |             10706.84
 2026-05-01 |   140097.06 |             21811.31
(3 rows)
```

Março de 2026 é mais de doze vezes março de 2025. Não é erro de impressão: a loja abriu em janeiro de
2025, então toda comparação com o ano passado compara um negócio com os próprios primeiros meses.
**Um crescimento ano contra ano de um negócio com pouco mais de um ano descreve o nascimento dele, e
não o desempenho**, e um painel que o mostra em letras grandes convida a uma comemoração que ninguém
deveria ter. A aula 10 volta a isso.

Duas coisas que as funções fazem e que o SQL acima obriga você a decidir explicitamente:

- **O que "mesmo período" quer dizer num mês parcial.** O `SAMEPERIODLASTYEAR` num contexto de 1 a 17
  de junho de 2026 devolve 1 a 17 de junho de 2025. O SQL acima compara meses inteiros; em junho, ele
  compararia 17 dias com 30.
- **Onde o ano começa.** O `TOTALYTD` aceita uma data opcional de fim de ano para um ano fiscal que não
  termina em dezembro. O da Lantern termina em dezembro, e o padrão está certo.
