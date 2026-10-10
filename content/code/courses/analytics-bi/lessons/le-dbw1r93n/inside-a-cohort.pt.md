---
title: Por que a coorte de novembro ficou menos
version: 1
---

Uma grade de coortes diz *que* uma geração é diferente. Para dizer *por quê*, divida a coorte por algo que
os clientes dela têm em comum, e compare cada pedaço com o mesmo pedaço nos outros meses. A Lantern sabe o
canal que trouxe cada cliente, então a pergunta vira: a Black Friday trouxe clientes piores em todo lugar,
ou trouxe muitos de um tipo?

A medida aqui é mais simples que a grade: a parcela de clientes que compraram de novo em até 90 dias depois
do primeiro pedido. Só entram coortes até fevereiro de 2026, para que todo cliente tenha tido os 90 dias
inteiros antes do fim dos dados — a regra da censura da seção anterior, aplicada uma vez:

```
lantern=# WITH first AS (
lantern(#   SELECT customer_id, min(order_date) AS first_order
lantern(#   FROM semantic.orders WHERE status = 'paid' GROUP BY customer_id)
lantern-# SELECT date_trunc('month', f.first_order) = '2025-11-01' AS november,
lantern-#        c.acquisition_channel, count(*) AS customers,
lantern-#        round(100.0 * count(*) FILTER (WHERE EXISTS (
lantern(#          SELECT 1 FROM semantic.orders o
lantern(#          WHERE o.customer_id = f.customer_id AND o.status = 'paid'
lantern(#            AND o.order_date > f.first_order AND o.order_date <= f.first_order + 90))
lantern(#          / count(*), 1) AS again_within_90_days
lantern-# FROM first f JOIN semantic.customers c USING (customer_id)
lantern-# WHERE f.first_order < '2026-03-01'
lantern-# GROUP BY 1, 2 ORDER BY 1, 2;
 november | acquisition_channel | customers | again_within_90_days 
----------+---------------------+-----------+----------------------
 f        | email               |       193 |                 64.8
 f        | referral            |       276 |                 76.4
 f        | search              |       535 |                 66.2
 f        | social              |       355 |                 66.5
 t        | email               |        20 |                 65.0
 t        | referral            |        19 |                 68.4
 t        | search              |        53 |                 75.5
 t        | social              |       263 |                 43.0
(8 rows)
```

A resposta está numa linha. Em todos os outros meses, os clientes vindos de redes sociais voltaram em 90
dias 66,5% das vezes, como os de e-mail e de busca. **Em novembro, 263 dos 355 clientes novos vieram de
redes sociais, e só 43,0% deles voltaram.** Os clientes de novembro vindos de busca, e-mail e indicação
voltaram tão bem quanto os de qualquer outro mês.

Então a Black Friday não trouxe clientes piores em geral. Trouxe um número grande de clientes por um canal,
numa campanha, e esses ficaram muito menos. É uma frase sobre a qual alguém pode agir — julgar a próxima
campanha pela taxa de volta em 90 dias por canal, e não pelo número de primeiros pedidos —, onde *a coorte
de novembro é mais fraca* era só uma frase com que alguém podia se preocupar.

Dois cuidados com as linhas pequenas. Os clientes de e-mail e de indicação de novembro são 20 e 19
pessoas; 68,4% de 19 pessoas são 13 pessoas, e uma a mais ou a menos move o número em cinco pontos. Elas
dizem "nenhum sinal de problema", não "melhor que o normal".
