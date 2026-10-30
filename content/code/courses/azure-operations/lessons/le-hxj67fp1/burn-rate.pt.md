---
title: Taxa de queima: a velocidade com que o orçamento vai embora
version: 1
---

**A taxa de queima é a taxa de erro dividida pela taxa de erro que o objetivo permite.** A 99,5%, a taxa permitida é 0,5%.
Uma taxa de queima de 1 gasta o orçamento exatamente ao longo do período; 2 gasta em metade do período; 100 gasta o orçamento
de uma semana em cerca de uma hora e quarenta minutos. É o número que diz quão urgente é uma taxa de falha, o que a taxa de
falha sozinha não diz.

```kql
// burn.kql: how fast checkout spent its budget, hour by hour on Thursday afternoon
let objective = 99.5;
AppRequests
| where Name == "POST /checkout"
| where TimeGenerated between (datetime(2026-10-15 15:00) .. datetime(2026-10-15 20:00))
| summarize valid = count(), bad = countif(not(Success)) by hour = bin(TimeGenerated, 1h)
| extend error_rate = round(100.0 * bad / valid, 2)
| extend burn_rate = round(error_rate / (100.0 - objective), 1)
| order by hour asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < burn.kql
hour                  valid  bad  error_rate  burn_rate
2026-10-15T15:00:00Z  203    0    0.0         0.0
2026-10-15T16:00:00Z  229    0    0.0         0.0
2026-10-15T17:00:00Z  220    103  46.82       93.6
2026-10-15T18:00:00Z  207    3    1.45        2.9
2026-10-15T19:00:00Z  207    1    0.48        1.0
```

A hora das 17:00 UTC queimou a **93,6**: nesse ritmo, a permissão da semana inteira vai embora em menos de duas horas. As
horas antes queimaram a zero, e a hora depois a 2,9, alguns retardatários. Uma taxa de erro de 1,45% não soa alarmante
sozinha; como taxa de queima de 2,9 ela diz que o orçamento duraria pouco mais de dois dias nesse ritmo, o que vale um
chamado na fila e não uma ligação.

Esse é o uso da taxa de queima: **ela põe toda taxa de falha numa escala só**, seja qual for o objetivo, para a mesma lógica de
alerta servir a um serviço a 99,9% e a um a 99%. Os limites da próxima seção são taxas de queima por isso.
