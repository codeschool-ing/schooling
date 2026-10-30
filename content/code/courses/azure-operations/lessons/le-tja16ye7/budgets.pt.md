---
title: Um orçamento, e a previsão que avisa cedo
version: 1
---

**Um orçamento no Cost Management é um valor para um período, com notificações em limites**, e é a primeira coisa que a lição 1 de
`azure-foundations` manda você criar numa assinatura real. Ele não para o gasto: ele avisa pessoas, que é o padrão certo, porque um
orçamento que desligasse recursos transformaria um problema de custo numa queda. O da loja, para `rg-shop`, em Bicep:

```bicep
// budget.bicep
param actionGroupId string

resource monthly 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: 'rg-shop-monthly'
  properties: {
    category: 'Cost'
    amount: 1800
    timeGrain: 'Monthly'
    timePeriod: { startDate: '2026-11-01' }
    notifications: {
      actualOver80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [ 'finops@example.com' ]
        contactGroups: [ actionGroupId ]
      }
      forecastOver100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [ 'finops@example.com' ]
        contactGroups: [ actionGroupId ]
      }
    }
  }
}
```

```
ana@laptop:~/azure/budget$ bicep build budget.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/budget$ jq -r '.resources[0].properties.notifications | to_entries[] | [.key, .value.thresholdType, (.value.threshold|tostring)] | @tsv' budget.json
actualOver80	Actual	80
forecastOver100	Forecasted	100
```

Duas notificações, e a segunda é a útil. **`Actual` acima de 80%** dispara quando o gasto do mês até ali passa de 1.440 USD, o que no dia
28 quer dizer um mês normal e no dia 10 quer dizer problema. **`Forecasted` acima de 100%** dispara quando a projeção do Cost Management
para o mês passa do orçamento, o que pode acontecer na primeira semana, com a maior parte do mês ainda para agir. As duas vão para o
endereço de FinOps e para o action group da lição 12, então uma previsão estourada chega às mesmas pessoas que um checkout falhando.

O orçamento foi compilado e não criado: orçamentos moram num escopo de cobrança ou de recurso. O valor, 1.800 USD por mês, é o número
ilustrativo da loja, perto do que a exportação de custos da lição 24 soma para `rg-shop`.

A fraqueza de um orçamento é o mês. Ele compara o gasto com uma linha mensal, e um salto no dia 9 que soma nove dólares por dia chega ao
limite de 80% dias depois de um mês normal, se chegar. **Orçamentos pegam o mês dando errado; não pegam o dia em que algo mudou.** As duas
próximas seções fazem isso.
