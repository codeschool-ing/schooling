---
title: A budget, and what its two alerts mean
version: 1
---

**A budget in Azure is an amount and a set of thresholds; Cost Management compares the bill with
them and tells somebody when a threshold is crossed.** The common picture is a spending limit, a
ceiling Azure will not let the subscription go through. That is not what it is. Microsoft's own
documentation says it in one line: when a threshold is reached, *resources aren't affected, and
your consumption isn't stopped*. A budget that reaches 100% sends an e-mail, and every machine behind
it keeps running and keeps charging. Lesson 1 put the budget second in the first hour of a real
account, before anything that costs money, for exactly that reason: a warning is only useful while
the amount is still small.

## The budget lesson 1 promised

A budget is a resource like any other, of the type `Microsoft.Consumption/budgets`, and it can be
written in Bicep and compiled in the lab. It belongs to a scope: a subscription, a resource group, a
management group, or a billing account. The shop's first one watches the whole `shop-prod`
subscription, so the file is aimed at a subscription. Make the lesson's directory:

```sh
mkdir -p ~/azure/cost && cd ~/azure/cost
```

and save this as `budget.bicep` in it:

```bicep
targetScope = 'subscription'

@description('The first day of the month the budget starts counting from.')
param startDate string = '2026-11-01'

resource monthly 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: 'budget-shop-monthly'
  properties: {
    category: 'Cost'
    amount: 50
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [
          'billing@shop.example'
        ]
      }
      forecast100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [
          'billing@shop.example'
        ]
      }
    }
  }
}
```

Field by field:

| field | what it says |
|---|---|
| `category: 'Cost'` | the budget counts money, in the subscription's billing currency |
| `amount: 50` | fifty a month, a deliberately small number for a subscription that is being learnt on |
| `timeGrain: 'Monthly'` | the count starts again at zero on the first of each month. `Quarterly` and `Annually` exist too, and divide the amount evenly over their months |
| `startDate` | the first day of a month; a budget cannot start in the middle of one |
| `actual80` | **an alert on what has already been charged**: it fires when the month's cost passes 80% of fifty, which is forty |
| `forecast100` | **an alert on where the month is heading**: it fires when Microsoft's forecast for the month's total passes fifty |
| `contactEmails` | a shared mailbox rather than a person, for the reason lesson 1 gave for the identity that signs up |

The names `actual80` and `forecast100` are the shop's own; Azure only asks that each notification
has one. A budget takes at least one notification and at most five, each with its own threshold,
which Azure accepts anywhere from 0.01% to 1000% of the amount.

Compile it and read back what Resource Manager would receive:

```
ana@laptop:~/azure/cost$ az bicep build --file budget.bicep --stdout | jq -c '."$schema", (.resources[0] | {type, apiVersion, alerts: [.properties.notifications | to_entries[] | {(.key): "\(.value.thresholdType) > \(.value.threshold)%"}]})'
"https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#"
{"type":"Microsoft.Consumption/budgets","apiVersion":"2024-08-01","alerts":[{"actual80":"Actual > 80%"},{"forecast100":"Forecasted > 100%"}]}
```

A template aimed at a subscription, one resource of the budget type, and the two alerts in the words
Azure stores them in.

## Two alerts, two questions

The two thresholds answer different questions, and a budget with only one of them answers half.

**The actual alert says that money has been spent.** At 80% of the month's amount, forty of the fifty
are gone. It cannot be wrong and it cannot be early: by the time it fires, the forty are on the bill.
It is the alert to keep when somebody asks for proof.

**The forecasted alert says that money is going to be spent.** Cost Management projects the month's
total from the cost so far, and the alert fires when that projection passes fifty. On the third day
of a month, a forgotten machine that costs two a day projects to about sixty, and the forecast says
so while only six have been charged. **It is the alert that arrives in time to do something.** It
can also be wrong, in both directions: a one-off charge early in the month inflates the projection,
and a cost that only starts on the twentieth is invisible to it until then.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l13-two-alerts\" aria-label=\"An invented month for a budget of 50: a forgotten machine adds 2 a day from the first. The actual cost rises in a straight line and crosses 40, the 80% threshold, on day 20, where the actual alert fires. The forecast for the month, drawn as a dashed line, sits at about 60 from the start, above the budget of 50, so the forecast alert fires on day 3, seventeen days earlier.\"><path d=\"M80.0 270.0 L660.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 270.0 L80.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"70.0\" y=\"204.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><text x=\"70.0\" y=\"138.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><text x=\"70.0\" y=\"105.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><text x=\"70.0\" y=\"72.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><text x=\"80.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"260.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"460.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><text x=\"660.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><text x=\"370.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">day of the month</text><path d=\"M80.0 105.7 L660.0 105.7\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"660.0\" y=\"95.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">budget: 50</text><path d=\"M80.0 138.6 L660.0 138.6\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"660.0\" y=\"150.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80% of the budget</text><path d=\"M80.0 263.4 L660.0 72.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M120.0 72.9 L660.0 72.9\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"300.0\" y=\"60.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">forecast for the month</text><circle cx=\"120.0\" cy=\"72.9\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"130.0\" y=\"90.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">forecast alert, day 3</text><circle cx=\"460.0\" cy=\"138.6\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"470.0\" y=\"160.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">actual alert, day 20</text><text x=\"320.0\" y=\"237.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">actual cost</text></svg>", "caption": "An invented month: the forecast alert arrives seventeen days before the actual one."}
```

That is why the shop keeps both, with the forecast at 100% and the actual below it: one says *this
month is heading over*, the other *this month is most of the way there*.

## How late an alert is

**A budget is not watching in real time, and the delay is part of the design.** Microsoft's
documentation gives the chain: cost and usage data reaches Cost Management between 8 and 24 hours
after it happens, budgets are evaluated against it **once every 24 hours**, and the e-mail goes out
within an hour of the evaluation:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"l13-delay\" aria-label=\"The chain between a cost and the e-mail about it, from Microsoft's documentation: the cost is incurred; its data reaches Cost Management 8 to 24 hours later; budgets are evaluated once every 24 hours; the e-mail goes out within an hour of the evaluation.\"><defs><marker id=\"l13-delay-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a cost</text><text x=\"90.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is incurred</text><path d=\"M163.0 78.0 L197.0 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-delay-af-ah-paper-dim)\"></path><text x=\"180.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8 to 24 hours</text><rect x=\"200.0\" y=\"50.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data reaches</text><text x=\"270.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Cost Management</text><path d=\"M343.0 78.0 L377.0 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-delay-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">up to 24 hours</text><rect x=\"380.0\" y=\"50.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the budget</text><text x=\"450.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is evaluated</text><path d=\"M523.0 78.0 L557.0 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-delay-af-ah-paper-dim)\"></path><text x=\"540.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">within an hour</text><rect x=\"560.0\" y=\"50.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the e-mail</text><text x=\"630.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is sent</text></svg>", "caption": "More than a day can pass between the cost and the alert about it."}
```

So the alert for a cost incurred on Monday morning can arrive on
Tuesday evening. **A runaway resource has more than a day of head start on any budget**, which is
the argument for keeping the amount small and the forecast alert on: the earlier threshold is the
only thing that buys back some of that day.

Two more delays catch people out. A brand-new subscription can take up to 48 hours before Cost
Management, budgets included, works on it at all. And a budget compares against the cost as
charged, not spread out: a reservation paid in one go lands on the budget the day it is bought,
which is lesson 14's subject.
