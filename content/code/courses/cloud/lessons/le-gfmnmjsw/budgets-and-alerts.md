---
title: Budgets and alerts, and what they do not do
version: 1
---

A budget is **a number for a period, with thresholds that send a message when spending crosses them**.
The common belief is that setting a budget of 400 dollars means the account cannot
spend 401. **An alert tells you; it does not stop anything.** Spending carries on past every threshold
until a person, or something a person built, changes what is running.

## A budget, written down

This is a budget for the application estimated earlier in this lesson, in the shape AWS Budgets
takes it: the request of the `CreateBudget` operation, as a JSON file the AWS CLI can read. The limit
is the estimate, 298.64, rounded up to 400.

```schooling-example
{
  "language": "json",
  "file": "budget.json",
  "parts": [
    {
      "code": "{\n  \"AccountId\": \"111122223333\",\n  \"Budget\": {\n    \"BudgetName\": \"shop-monthly\",\n    \"BudgetLimit\": {\"Amount\": \"400\", \"Unit\": \"USD\"},\n    \"TimeUnit\": \"MONTHLY\",\n    \"BudgetType\": \"COST\"\n  },",
      "note": "The budget itself: a name, a **limit** written as an amount and a unit, a period and what is measured. `COST` is money; a `USAGE` budget would count hours or gigabytes instead. The account number is the one AWS's documentation uses in its examples."
    },
    {
      "code": "  \"NotificationsWithSubscribers\": [\n    {\"Notification\": {\"NotificationType\": \"ACTUAL\", \"ComparisonOperator\": \"GREATER_THAN\",\n                      \"Threshold\": 50, \"ThresholdType\": \"PERCENTAGE\"},\n     \"Subscribers\": [{\"SubscriptionType\": \"EMAIL\", \"Address\": \"cloud-costs@example.com\"}]},",
      "note": "One notification and who receives it. It fires when **actual** spending goes over 50% of the limit, and sends an e-mail. A subscriber can also be an SNS topic, which is how a message reaches a chat channel or a program."
    },
    {
      "code": "    {\"Notification\": {\"NotificationType\": \"ACTUAL\", \"ComparisonOperator\": \"GREATER_THAN\",\n                      \"Threshold\": 80, \"ThresholdType\": \"PERCENTAGE\"},\n     \"Subscribers\": [{\"SubscriptionType\": \"EMAIL\", \"Address\": \"cloud-costs@example.com\"}]},\n    {\"Notification\": {\"NotificationType\": \"ACTUAL\", \"ComparisonOperator\": \"GREATER_THAN\",\n                      \"Threshold\": 100, \"ThresholdType\": \"PERCENTAGE\"},\n     \"Subscribers\": [{\"SubscriptionType\": \"EMAIL\", \"Address\": \"cloud-costs@example.com\"}]},",
      "note": "The same at 80% and at 100%. The 100% message arrives after the limit has been passed, which is why it is not the only one."
    },
    {
      "code": "    {\"Notification\": {\"NotificationType\": \"FORECASTED\", \"ComparisonOperator\": \"GREATER_THAN\",\n                      \"Threshold\": 100, \"ThresholdType\": \"PERCENTAGE\"},\n     \"Subscribers\": [{\"SubscriptionType\": \"EMAIL\", \"Address\": \"cloud-costs@example.com\"}]}",
      "note": "The **forecast**: the provider projects the month from the spending so far and warns when the projection passes the limit, which can be weeks before actual spending does."
    },
    {
      "code": "  ]\n}"
    }
  ]
}
```

It was **not created anywhere**: this course has no account. What the CLI does before it looks for
credentials is check the file against the operation's definition, and that much can be run on a
laptop. The first attempt got as far as looking for credentials, which means the file passed; the
second has one letter missing and does not:

```
ana@laptop:~/cloud$ aws budgets create-budget --cli-input-json file://budget.json

aws: [ERROR]: An error occurred (NoCredentials): Unable to locate credentials. You can configure credentials by running "aws login".
ana@laptop:~/cloud$ sed s/BudgetLimit/BudgetLimt/ budget.json > typo.json
ana@laptop:~/cloud$ aws budgets create-budget --cli-input-json file://typo.json

aws: [ERROR]: An error occurred (ParamValidation): Parameter validation failed:
Unknown parameter in Budget: "BudgetLimt", must be one of: BudgetName, BudgetLimit, PlannedBudgetLimits, CostFilters, CostTypes, TimeUnit, TimePeriod, CalculatedSpend, BudgetType, LastUpdatedTime, AutoAdjustData, FilterExpression, Metrics, BillingViewArn, HealthStatus
```

## Why the thresholds start at half

Billing data is not live. Usage is metered, collected and priced before it reaches the billing system,
and **the numbers a budget compares are hours behind the usage they describe**. An alert at 100% of
actual spend therefore arrives after the money has been spent, and after whatever was spending it has
been running for a few more hours.

That is why a useful budget has thresholds below the limit. At 50% and 80% the message is news, and
early enough to act on. The forecast alert is the earliest of all: the provider projects the month from
the spending so far, and warns when the projection passes the limit. A runaway process on the fifth of
the month can trigger the forecast long before actual spending reaches half.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"An invented month against the budget of 400 USD. Spending grows by about 10 dollars a day until day 12, when a runaway process makes it grow by 25 a day. Dashed lines mark 200, 320 and 400 dollars, the 50, 80 and 100 percent thresholds. The forecast alert fires on day 13, the 50 percent alert on day 15, the 80 percent on day 20 and the 100 percent on day 23. A dashed forecast from day 24 ends the month far above the limit.\"><defs><marker id=\"bdg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 192.6 L560 192.6\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"62\" y=\"192.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"568\" y=\"192.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M70 146.1 L560 146.1\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"62\" y=\"146.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">320</text><text x=\"568\" y=\"146.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">80%</text><path d=\"M70 115.2 L560 115.2\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"62\" y=\"115.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><text x=\"568\" y=\"115.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">100%</text><path d=\"M70.0 266.1 L86.9 262.3 L103.8 258.4 L120.7 254.5 L137.6 250.6 L154.5 246.8 L171.4 242.9 L188.3 239.0 L205.2 235.2 L222.1 231.3 L239.0 227.4 L255.9 223.5 L272.8 213.9 L289.7 204.2 L306.6 194.5 L323.4 184.8 L340.3 175.2 L357.2 165.5 L374.1 155.8 L391.0 146.1 L407.9 136.5 L424.8 126.8 L441.7 117.1 L458.6 107.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M458.6 107.4 L560.0 49.4\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"488.4\" y=\"53.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">forecast</text><circle cx=\"281.2\" cy=\"209.0\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"309.9\" cy=\"192.6\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"391.0\" cy=\"146.1\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"445.1\" cy=\"115.2\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"289.2\" y=\"221.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">forecast passes 400</text><text x=\"301.9\" y=\"180.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">50%</text><text x=\"383.0\" y=\"134.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">80%</text><text x=\"437.1\" y=\"103.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">100%</text><text x=\"255.9\" y=\"249.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a process runs away</text><path d=\"M255.9 239.5 L255.9 227.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 270 L560 270\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 270 L70 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"270\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"10\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD spent this month</text><text x=\"70.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"222.1\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"391.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><text x=\"560.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><text x=\"560\" y=\"306\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">day of the month</text></svg>", "caption": "An invented month, not a bill. The forecast alert is the first to fire, on the day after the process ran away; the 100% alert comes more than a week later. Each message also arrives hours after the spending it reports."}
```

The providers do offer ways to act as well as warn, and each has to be built on purpose. AWS Budgets
can run actions, such as applying a restrictive policy or stopping chosen instances, when a threshold
is crossed. Google Cloud's documentation shows how to connect a budget's messages to a function that
turns billing off for a project. Both act on the same delayed data, and both can stop something that
should not have stopped, so neither replaces a person reading the message.

## When it fires

A threshold message is the start of a short routine, and it is worth writing down before the first
one arrives:

1. Open the cost view grouped by service, then by tag, for the current month, and compare it with
   the estimate. The line that moved is usually obvious.
2. Find who owns it. The tags from the next section are what makes this a lookup rather than an
   investigation.
3. Decide whether it was expected. A launch, a new customer, a migration: then raise the budget
   and write down why. A loop, a forgotten test, an address nobody released: then stop it today.
4. Change something so it does not happen the same way twice: a retention rule, a tag, a smaller
   default, a budget on the account that surprised you.

A budget that fires every month and is ignored every month is worse than none, because it teaches
everybody that its message means nothing. When the real alert arrives, it will be read the same way.
