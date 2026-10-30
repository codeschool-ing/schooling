---
title: A budget, and the forecast that warns early
version: 1
---

**A budget in Cost Management is an amount for a period, with notifications at thresholds**, and it is the
first thing `azure-foundations` lesson 1 has you create on a real subscription. It does not stop spending:
it tells people, which is the right default, because a budget that switched resources off would turn a
cost problem into an outage. The shop's, for `rg-shop`, in Bicep:

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

Two notifications, and the second one is the useful one. **`Actual` over 80%** fires when the month's
spend so far passes 1,440 USD, which on the 28th means a normal month and on the 10th means trouble.
**`Forecasted` over 100%** fires when Cost Management's projection for the month passes the budget, which
can happen in the first week, while there is still most of the month to act in. Both go to the FinOps
address and to the action group of lesson 12, so a forecast breach reaches the same people a failing
checkout does.

The budget was compiled and not created: budgets live on a billing or resource scope. The amount, 1,800
USD a month, is the shop's illustrative figure, close to what lesson 24's cost export sums for `rg-shop`.

A budget's weakness is the month. It compares spend with a monthly line, and a jump on the 9th that adds
nine dollars a day reaches the 80% threshold days later than a normal month would, if it reaches it at
all. **Budgets catch the month going wrong; they do not catch the day something changed.** The next two
sections do that.
