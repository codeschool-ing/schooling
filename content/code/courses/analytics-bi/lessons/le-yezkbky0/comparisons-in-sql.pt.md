---
title: Comparações em SQL, e a certa a fazer
version: 1
---

Uma ferramenta de BI calcula comparações com uma opção; vale ver uma vez o que a opção faz. O valor
do mês anterior ao lado de cada mês é uma função de janela, `lag`, que lê a linha anterior na ordem
que você der:

```sql
WITH m AS (
  SELECT date_trunc('month', order_date)::date AS month, sum(net_revenue) AS net_revenue
  FROM semantic.orders GROUP BY 1
)
SELECT month, net_revenue,
       lag(net_revenue) OVER (ORDER BY month) AS previous_month,
       round(100 * (net_revenue / lag(net_revenue) OVER (ORDER BY month) - 1), 1) AS change_pct
FROM m
WHERE month >= '2026-01-01'
ORDER BY month;
```

```
lantern=# WITH m AS (
lantern(#   SELECT date_trunc('month', order_date)::date AS month, sum(net_revenue) AS net_revenue
lantern(#   FROM semantic.orders GROUP BY 1
lantern(# )
lantern-# SELECT month, net_revenue,
lantern-#        lag(net_revenue) OVER (ORDER BY month) AS previous_month,
lantern-#        round(100 * (net_revenue / lag(net_revenue) OVER (ORDER BY month) - 1), 1) AS change_pct
lantern-# FROM m
lantern-# WHERE month >= '2026-01-01'
lantern-# ORDER BY month;
   month    | net_revenue | previous_month | change_pct 
------------+-------------+----------------+------------
 2026-01-01 |    87883.56 |                |           
 2026-02-01 |    88361.90 |       87883.56 |        0.5
 2026-03-01 |   117964.14 |       88361.90 |       33.5
 2026-04-01 |   119821.78 |      117964.14 |        1.6
 2026-05-01 |   140097.06 |      119821.78 |       16.9
 2026-06-01 |    75811.94 |      140097.06 |      -45.9
(6 rows)
```

Todo mês de 2026 numa vista, com a variação. Março saltou 33,5%; fevereiro quase não se mexeu. E
então junho: **−45,9%**. Guarde esse número; a próxima seção o desmonta.

## Os dias, e a semana dentro deles

Uma comparação diária tem uma armadilha própria, que a aula 1 encontrou: os domingos têm cerca de
metade dos pedidos de um dia útil. Comparar um dia com o anterior compara o calendário:

```
lantern=# SELECT k.day, to_char(k.day, 'Dy') AS name, count(o.order_id) AS orders
lantern-# FROM semantic.calendar k LEFT JOIN semantic.orders o ON o.order_date = k.day
lantern-# WHERE k.day IN ('2026-06-07', '2026-06-08', '2026-06-14', '2026-06-15')
lantern-# GROUP BY k.day ORDER BY k.day;
    day     | name | orders 
------------+------+--------
 2026-06-07 | Sun  |     15
 2026-06-08 | Mon  |     38
 2026-06-14 | Sun  |     10
 2026-06-15 | Mon  |     43
(4 rows)
```

A segunda, 15 de junho, contra o domingo, 14, é 43 contra 10, mais de quatro vezes — e não significa
nada. Contra a segunda anterior, 8 de junho, é 43 contra 38, uma alta real, se pequena. **Compare um
dia com o mesmo dia da semana anterior**, e uma semana com a mesma semana do ano anterior quando houver
um ano para comparar. A comparação embutida de uma ferramenta costuma ser com o período anterior, e o
período anterior nem sempre é o certo.
