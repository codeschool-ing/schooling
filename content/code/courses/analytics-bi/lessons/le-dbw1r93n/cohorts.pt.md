---
title: Uma coorte é uma geração de clientes
version: 1
---

Uma **coorte** é um grupo de clientes que começaram ao mesmo tempo — aqui, o mês do primeiro pedido pago.
O motivo de agrupá-los assim é que isso separa duas coisas que um total mistura: quantos clientes chegam,
e quão bem eles ficam. Uma loja pode crescer todo mês enquanto cada geração nova fica menos que a
anterior, e o total não vai mostrar isso até as chegadas diminuírem.

As coortes da Lantern, por tamanho:

```
lantern=# SELECT date_trunc('month', first_order)::date AS cohort, count(*) AS customers
lantern-# FROM (SELECT customer_id, min(order_date) AS first_order
lantern(#       FROM semantic.orders WHERE status = 'paid' GROUP BY customer_id) f
lantern-# GROUP BY 1 ORDER BY 1;
   cohort   | customers 
------------+-----------
 2025-01-01 |         8
 2025-02-01 |        19
 2025-03-01 |        38
 2025-04-01 |        45
 2025-05-01 |        68
 2025-06-01 |        85
 2025-07-01 |       113
 2025-08-01 |       119
 2025-09-01 |       118
 2025-10-01 |       158
 2025-11-01 |       355
 2025-12-01 |       184
 2026-01-01 |       201
 2026-02-01 |       203
 2026-03-01 |       250
 2026-04-01 |       237
 2026-05-01 |       258
 2026-06-01 |       165
(18 rows)
```

A loja cresce de forma constante ao longo de 2025 e entrando em 2026, com uma exceção: **novembro de 2025
tem 355 clientes novos**, o dobro dos 158 de outubro e quase o dobro dos 184 de dezembro. É a campanha de
Black Friday que a aula 1 achou nos pedidos e que a aula 2 prometeu acompanhar: *quantos deles ficaram?*

Duas outras coortes pedem um aviso antes de qualquer leitura. **Janeiro e fevereiro de 2025 são
minúsculas** — 8 e 19 clientes —, então uma porcentagem calculada nelas se move 5 ou 12 pontos a cada
cliente que volta ou não. E **junho de 2026 não é um mês inteiro**: os dados terminam em 17 de junho,
então a coorte são os clientes de dezessete dias, e eles não tiveram tempo nenhum de voltar.

Há outros jeitos de cortar uma coorte — pela semana do cadastro, pelo primeiro produto comprado, pelo
canal que os trouxe —, e a escolha depende da pergunta. *A Black Friday trouxe bons clientes?* é uma
pergunta sobre o mês do primeiro pedido, então esse é o corte aqui.
