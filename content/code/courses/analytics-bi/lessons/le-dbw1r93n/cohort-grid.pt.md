---
title: A grade de coortes, primeiro do jeito errado
version: 1
---

Uma **grade de coortes** põe uma coorte em cada linha e os meses desde o começo nas colunas. Cada célula é
a parcela da coorte que comprou de novo naquele mês: `m1` é o mês seguinte ao primeiro pedido, `m3`, três
meses depois. Leia uma linha da esquerda para a direita e você acompanha uma geração envelhecendo; leia
uma coluna de cima para baixo e você compara gerações na mesma idade.

A consulta tem três passos. `paid` guarda uma linha por cliente por mês em que ele pagou um pedido;
`cohort` acha o primeiro mês de cada cliente; `activity` mede quantos meses depois dele cada mês seguinte
está, como `k`. A grade então conta, para cada coorte, os clientes ativos em cada `k`. Aqui está ela para
as coortes a partir de outubro de 2025:

```
lantern=# WITH paid AS (
lantern(#   SELECT DISTINCT customer_id, date_trunc('month', order_date)::date AS month
lantern(#   FROM semantic.orders WHERE status = 'paid'),
lantern-# cohort AS (SELECT customer_id, min(month) AS cohort FROM paid GROUP BY customer_id),
lantern-# activity AS (
lantern(#   SELECT c.cohort, p.customer_id,
lantern(#          (12 * (extract(year FROM p.month) - extract(year FROM c.cohort))
lantern(#           + extract(month FROM p.month) - extract(month FROM c.cohort))::int AS k
lantern(#   FROM paid p JOIN cohort c USING (customer_id))
lantern-# SELECT cohort, count(*) FILTER (WHERE k = 0) AS size,
lantern-#        round(100.0 * count(*) FILTER (WHERE k = 1) / count(*) FILTER (WHERE k = 0), 1) AS m1,
lantern-#        round(100.0 * count(*) FILTER (WHERE k = 2) / count(*) FILTER (WHERE k = 0), 1) AS m2,
lantern-#        round(100.0 * count(*) FILTER (WHERE k = 3) / count(*) FILTER (WHERE k = 0), 1) AS m3,
lantern-#        round(100.0 * count(*) FILTER (WHERE k = 6) / count(*) FILTER (WHERE k = 0), 1) AS m6
lantern-# FROM activity
lantern-# WHERE cohort >= '2025-10-01'
lantern-# GROUP BY cohort ORDER BY cohort;
   cohort   | size |  m1  |  m2  |  m3  |  m6  
------------+------+------+------+------+------
 2025-10-01 |  158 | 43.7 | 37.3 | 29.1 | 14.6
 2025-11-01 |  355 | 31.8 | 25.1 | 14.1 |  8.5
 2025-12-01 |  184 | 41.3 | 32.6 | 34.8 |  9.8
 2026-01-01 |  201 | 42.3 | 35.3 | 28.4 |  0.0
 2026-02-01 |  203 | 48.3 | 37.9 | 29.1 |  0.0
 2026-03-01 |  250 | 43.6 | 33.6 | 22.8 |  0.0
 2026-04-01 |  237 | 46.4 | 23.2 |  0.0 |  0.0
 2026-05-01 |  258 | 25.6 |  0.0 |  0.0 |  0.0
 2026-06-01 |  165 |  0.0 |  0.0 |  0.0 |  0.0
(9 rows)
```

Leia a linha de novembro contra as vizinhas: 31,8% voltaram no primeiro mês, contra 43,7% de outubro e
41,3% de dezembro; 14,1% no terceiro mês, contra 29,1% e 34,8%. **Os clientes da Black Friday ficaram
menos, e no terceiro mês cerca de metade.** É a resposta para a qual a coorte foi montada, e está certa.

O resto da grade tem um problema, e ele está no canto. Olhe as últimas linhas: junho de 2026 mostra
**0,0** em todas as colunas, maio mostra 0,0 a partir do segundo mês, e toda coorte a partir de janeiro
mostra 0,0 aos seis meses. Lidos como números, os clientes mais novos são os piores que a Lantern já teve —
ninguém volta.

Eles não tiveram chance. Um cliente cujo primeiro pedido foi em maio de 2026 não pode ter comprado em
agosto de 2026, porque agosto ainda não aconteceu; os dados terminam em 17 de junho. A consulta contou
*nenhum pedido* onde a verdade é *nenhum tempo*. E o primeiro mês de maio, 25,6%, não está errado do mesmo
jeito, mas também está errado: o primeiro mês dele é junho, que só tem dezessete dias.

**Uma célula que não terminou de acontecer não é zero. É desconhecida.** A próxima seção faz a grade dizer
isso.
