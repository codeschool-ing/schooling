---
title: Chamando pelo orçamento, com duas janelas
version: 1
---

**Um alerta no sintoma chama quando os clientes são afetados; um alerta no orçamento chama quando eles são afetados rápido o
bastante para importar.** O padrão que o workbook de SRE do Google popularizou, e que a própria orientação da Microsoft sobre
alertas de SLO segue, usa duas janelas sobre a mesma taxa de queima:

- uma **janela longa**, de uma hora, para um soluço breve não chamar ninguém;
- uma **janela curta**, de cinco minutos, para a chamada parar assim que o problema para;

e só chama quando **as duas** queimam mais rápido que um limite. 14,4 é o clássico para uma janela de uma hora: nesse ritmo, um
orçamento de 30 dias perde 2% numa hora. A loja mantém o número, sobre o seu orçamento semanal, como ponto de partida para
ajustar. Avaliado a cada cinco minutos na quinta:

```kql
// two-windows.kql: the page condition, evaluated every 5 minutes: both windows burning over 14.4
let objective = 99.5;
let checkout = AppRequests | where Name == "POST /checkout";
range evaluated from datetime(2026-10-15 17:00) to datetime(2026-10-15 19:00) step 5m
| extend k = 1
| join kind=inner (checkout | extend k = 1) on k
| where TimeGenerated > evaluated - 1h and TimeGenerated <= evaluated
| summarize long_rate = 100.0 * countif(not(Success)) / count(),
    short_rate = 100.0 * countif(not(Success) and TimeGenerated > evaluated - 5m) / max_of(countif(TimeGenerated > evaluated - 5m), 1)
    by evaluated
| extend long_burn = round(long_rate / (100.0 - objective), 1), short_burn = round(short_rate / (100.0 - objective), 1)
| extend page = long_burn > 14.4 and short_burn > 14.4
| project evaluated, long_burn, short_burn, page
| order by evaluated asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < two-windows.kql
evaluated             long_burn  short_burn  page
2026-10-15T17:00:00Z  0.0        0.0         False
2026-10-15T17:05:00Z  0.0        0.0         False
2026-10-15T17:10:00Z  8.0        138.5       False
2026-10-15T17:15:00Z  23.8       163.6       True
2026-10-15T17:20:00Z  36.3       147.4       True
2026-10-15T17:25:00Z  44.1       81.8        True
2026-10-15T17:30:00Z  56.0       137.5       True
2026-10-15T17:35:00Z  73.4       181.0       True
2026-10-15T17:40:00Z  83.7       125.0       True
2026-10-15T17:45:00Z  96.6       133.3       True
2026-10-15T17:50:00Z  98.6       33.3        True
2026-10-15T17:55:00Z  96.7       0.0         False
2026-10-15T18:00:00Z  93.6       0.0         False
2026-10-15T18:05:00Z  99.0       0.0         False
2026-10-15T18:10:00Z  87.9       0.0         False
2026-10-15T18:15:00Z  72.0       0.0         False
2026-10-15T18:20:00Z  59.0       0.0         False
2026-10-15T18:25:00Z  49.8       0.0         False
2026-10-15T18:30:00Z  38.9       0.0         False
2026-10-15T18:35:00Z  21.7       0.0         False
2026-10-15T18:40:00Z  12.5       0.0         False
2026-10-15T18:45:00Z  4.6        17.4        False
2026-10-15T18:50:00Z  1.9        0.0         False
2026-10-15T18:55:00Z  2.0        0.0         False
2026-10-15T19:00:00Z  2.9        10.5        False
```

`range` faz uma linha por avaliação, e o join com uma chave constante `k` junta cada avaliação a todo checkout para cada uma
contar as próprias janelas; é um jeito de força bruta de avaliar uma regra em muitos momentos, bom para uma semana de dados e
não como o alerta real roda. **Leia a coluna `page` contra as duas colunas de queima.** A janela curta passou de 14,4 às 17:10,
e a longa só às 17:15, então a chamada veio às 17:15, cinco minutos depois da regra simples da lição 12: o preço de não chamar
por soluços. Às 17:55 a janela curta caiu a zero enquanto a longa ainda estava perto de 97, e a chamada parou: o incidente
acabou, e ninguém precisa ser acordado pela memória da hora. Às 18:45 uma única falha empurrou a janela curta a 17,4 e a longa
ficou em 4,6: sem chamada, que é exatamente o soluço que a janela longa existe para ignorar.

Para ir para produção, a consulta da última avaliação vira a consulta de um alerta de pesquisa de log, como na lição 12,
avaliado a cada cinco minutos; uma segunda regra com janela de seis horas e limite mais baixo, mandada como chamado na fila e
não como ligação, pega as queimas lentas que esta ignora.
