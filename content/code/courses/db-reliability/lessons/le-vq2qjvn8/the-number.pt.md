---
title: O número do contrato
version: 1
---

O **acordo de nível de serviço** (SLA) de um provedor promete uma disponibilidade, uma porcentagem do
mês em que o serviço responde. As porcentagens parecem todas iguais, então converta-as em tempo:

```
shop=# SELECT p AS availability, justify_interval(interval '30 days' * (1 - p / 100)) AS down_per_month, justify_interval(interval '365 days' * (1 - p / 100)) AS down_per_year FROM (VALUES (99.0), (99.9), (99.95), (99.99)) AS t(p);
 availability | down_per_month |  down_per_year  
--------------+----------------+-----------------
         99.0 | 07:12:00       | 3 days 15:36:00
         99.9 | 00:43:12       | 08:45:36
        99.95 | 00:21:36       | 04:22:48
        99.99 | 00:04:19.2     | 00:52:33.6
(4 rows)
```

**99,95%**, um número comum para um banco com um standby num segundo data center, permite **21
minutos e 36 segundos** fora do ar por mês, mais de quatro horas por ano. 99,99% permite quatro
minutos por mês, mais ou menos o tempo de um failover com todo mundo reconectando. São orçamentos que
o provedor tem o direito de gastar, não previsões.

## Em cadeia

Uma aplicação precisa do banco **e** de tudo o que fica entre os dois: os próprios servidores dela, a
rede, o DNS. Disponibilidades em cadeia se multiplicam:

```
shop=# SELECT round(99.95 * 99.95 / 100, 4) AS database_and_app, round(99.95 * 99.95 * 99.9 / 10000, 4) AS with_a_network_link;
 database_and_app | with_a_network_link 
------------------+---------------------
          99.9000 |             99.8001
(1 row)

shop=# SELECT justify_interval(interval '30 days' * (1 - 99.95 * 99.95 * 99.9 / 1000000)) AS down_per_month;
 down_per_month  
-----------------
 01:26:20.760648
(1 row)
```

Dois componentes com 99,95% cada dão 99,90% juntos; acrescente um link de rede com 99,9% e o conjunto
fica em **99,80%**, quase uma hora e meia por mês. O número do banco é um teto para o que a aplicação
pode ter, nunca o que ela vai ter.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Três caixas em fila ligadas por setas: a aplicação com 99,95%, a rede com 99,9% e o banco gerenciado com 99,95%. Embaixo, uma chave sobre as três diz 99,80% juntos, cerca de 1 hora e 26 minutos fora do ar por mês.\"><defs><marker id=\"l21c-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aplicação</text><text x=\"110\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">99,95%</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rede</text><text x=\"360\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">99,9%</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">banco gerenciado</text><text x=\"610\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">99,95%</text><path d=\"M202 60 L268 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l21c-pa)\"></path><path d=\"M452 60 L518 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l21c-pa)\"></path><path d=\"M20 108 L20 116 L700 116 L700 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">juntos: 99,80%, cerca de 1 h 26 min fora por mês</text></svg>", "caption": "Disponibilidades em cadeia se multiplicam. O número do banco é um teto para o da aplicação, nunca o que a aplicação recebe."}
```

## O que o contrato paga

Quando o provedor não cumpre o número, o contrato paga um **crédito de serviço**: uma porcentagem da
conta daquele mês por aquele serviço, abatida de contas futuras, em geral mediante pedido e dentro de
um prazo:

```
shop=# SELECT 2000.00 AS monthly_bill, 2000.00 * 0.10 AS credit_at_10_percent, interval '3 hours' AS outage, 50000 AS orders_per_day, round(50000 / 24.0 * 3) AS orders_not_taken;
 monthly_bill | credit_at_10_percent |  outage  | orders_per_day | orders_not_taken 
--------------+----------------------+----------+----------------+------------------
      2000.00 |             200.0000 | 03:00:00 |          50000 |             6250
(1 row)
```

Uma indisponibilidade de três horas custa a um shop que recebe 50.000 pedidos por dia cerca de
**6.250 pedidos** não recebidos, e o contrato devolve 10% de uma conta de 2.000. **Um SLA é uma
promessa sobre a receita do provedor, não sobre a sua.** Ele diz com que frequência esperar problemas;
não é um seguro contra eles, e o RPO e o RTO da lição 8 continuam sendo números que você precisa
cumprir com coisas que você controla.
