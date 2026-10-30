---
title: Um alerta de pesquisa de log, e avaliá-lo você mesmo
version: 1
---

A primeira regra da loja dispara quando o checkout está falhando: mais de 5% dos checkouts em cinco minutos, desde que tenham
sido pelo menos dez, para uma falha entre três requisições de madrugada não chamar ninguém.

```bicep
// checkout-alert.bicep
param workspaceId string
param actionGroupId string

resource checkoutFailing 'Microsoft.Insights/scheduledQueryRules@2023-12-01' = {
  name: 'checkout-failing'
  location: 'brazilsouth'
  properties: {
    displayName: 'Checkout failing'
    severity: 1
    enabled: true
    scopes: [ workspaceId ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
            AppRequests
            | where Name == "POST /checkout"
            | summarize total = count(), failed = countif(not(Success))
            | extend failed_pct = 100.0 * failed / total
            | where total >= 10 and failed_pct > 5
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [ actionGroupId ]
    }
  }
}
```

A consulta é KQL comum dentro de uma string de várias linhas com `'''`. Ela devolve uma linha só quando a condição vale, e a
condição da própria regra é *mais de 0 linhas*. Escrever assim mantém a decisão na consulta, onde ela pode ser lida e
testada, em vez de dividida entre a consulta e as configurações da regra.

```
ana@laptop:~/azure/alerts$ bicep build checkout-alert.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/alerts$ jq -r '.resources[0].properties | [.evaluationFrequency, .windowSize, (.severity|tostring)] | @tsv' checkout-alert.json
PT5M	PT5M	1
```

Compilou; não foi implantado, e nada vai disparar. Mas a pergunta que importa, **ela teria disparado na quinta, e quando**,
pode ser respondida exatamente, porque a regra é só a consulta dela rodada a cada cinco minutos sobre os cinco anteriores.
Rode essa consulta em cada janela de cinco minutos da tarde de quinta, no emulador, de `~/azure/kusto`:

```kql
// evaluate.kql: checkout-failing's query, run over each five-minute window of Thursday afternoon
AppRequests
| where Name == "POST /checkout"
| where TimeGenerated between (datetime(2026-10-15 16:50) .. datetime(2026-10-15 18:00))
| summarize total = count(), failed = countif(not(Success)) by window_end = bin(TimeGenerated, 5m) + 5m
| extend failed_pct = round(100.0 * failed / total, 1)
| extend fires = total >= 10 and failed_pct > 5
| order by window_end asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < evaluate.kql
window_end            total  failed  failed_pct  fires
2026-10-15T16:55:00Z  13     0       0.0         False
2026-10-15T17:00:00Z  10     0       0.0         False
2026-10-15T17:05:00Z  24     0       0.0         False
2026-10-15T17:10:00Z  13     9       69.2        True
2026-10-15T17:15:00Z  22     18      81.8        True
2026-10-15T17:20:00Z  19     14      73.7        True
2026-10-15T17:25:00Z  22     9       40.9        True
2026-10-15T17:30:00Z  16     11      68.8        True
2026-10-15T17:35:00Z  21     19      90.5        True
2026-10-15T17:40:00Z  15     9       60.0        True
2026-10-15T17:45:00Z  16     11      68.8        True
2026-10-15T17:50:00Z  18     3       16.7        True
2026-10-15T17:55:00Z  17     0       0.0         False
2026-10-15T18:00:00Z  17     0       0.0         False
```

O incidente começou às 17:05:12. **A avaliação que terminou às 17:10 é a primeira a dizer sim**, com 9 de 13 checkouts com
falha, e a regra dispara ali: 14:10 em São Paulo. Ela continua disparada, porque o `autoMitigate` a deixa com estado, até a
avaliação que termina às 17:55 voltar não, e então se resolve sozinha. Um alerta, uma resolução, para um incidente de
quarenta minutos.

Duas coisas que o emulador não mostra. Num workspace, os logs levam alguns minutos para chegar, então a regra real vê cada
janela com atraso, e um alerta real dispara alguns minutos depois do que esta tabela diz. E a avaliação das 17:25 lembra por
que o limite é baixo: 9 falhas em 22 ainda eram 41%, bem acima de 5%, e um limite em 50% teria resolvido o alerta no meio do
incidente e disparado de novo cinco minutos depois.
