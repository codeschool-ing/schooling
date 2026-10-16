---
title: A budget, and the two alerts it carries
version: 1
---

Lesson 10's alarms watch what customers feel. Some incidents customers never feel: a debug flag left on
that writes forty gigabytes of logs a day, a forgotten load test, a credential mining cryptocurrency on
instances somebody else launched. The service works; **the bill is the only thing that moves**, and it
moves at the end of the month unless something is watching it every day. This lesson makes the bill a
signal like any other.

The first instrument is **AWS Budgets**: an amount for a period, and notifications when the spend crosses a
share of it. Budgets are free to create for this use; AWS charges only for budgets that run **actions**,
beyond the first two, which this lesson does not use. Work in `~/aws/bill`
(`mkdir -p ~/aws/bill && cd ~/aws/bill`). The shop's month is about 1,500 USD, so the budget is 1,600.

`budget.json`:

```json
{
  "BudgetName": "shop-monthly",
  "BudgetLimit": { "Amount": "1600", "Unit": "USD" },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```

`notifications.json`:

```json
[
  {
    "Notification": { "NotificationType": "ACTUAL", "ComparisonOperator": "GREATER_THAN", "Threshold": 80, "ThresholdType": "PERCENTAGE" },
    "Subscribers": [{ "SubscriptionType": "SNS", "Address": "arn:aws:sns:us-east-1:123456789012:billing" }]
  },
  {
    "Notification": { "NotificationType": "FORECASTED", "ComparisonOperator": "GREATER_THAN", "Threshold": 100, "ThresholdType": "PERCENTAGE" },
    "Subscribers": [{ "SubscriptionType": "SNS", "Address": "arn:aws:sns:us-east-1:123456789012:billing" }]
  }
]
```

```
ana@laptop:~/aws/bill$ aws sns create-topic --name billing --region us-east-1 --query TopicArn --output text
arn:aws:sns:us-east-1:123456789012:billing
ana@laptop:~/aws/bill$ aws budgets create-budget --account-id 123456789012 --budget file://budget.json --notifications-with-subscribers file://notifications.json
ana@laptop:~/aws/bill$ aws budgets describe-budgets --account-id 123456789012 --query 'Budgets[].[BudgetName,BudgetLimit.Amount,TimeUnit,CalculatedSpend.ActualSpend.Amount]' --output text
shop-monthly	1600	MONTHLY	0
ana@laptop:~/aws/bill$ aws budgets describe-notifications-for-budget --account-id 123456789012 --budget-name shop-monthly --query 'Notifications[].[NotificationType,ComparisonOperator,Threshold]' --output text
ACTUAL	GREATER_THAN	80
FORECASTED	GREATER_THAN	100
```

The two notifications are the point. **`ACTUAL` above 80%** says the money has been spent: on the 25th of a
normal month it is expected, on the 9th it is news. **`FORECASTED` above 100%** says the month is on its way
to exceeding the budget, from AWS's own forecast of the rest of the month, and that one arrives early
enough to act. A budget with only an actual notification at 100% says, on the 30th, what everybody will
see on the 1st.

moto keeps the budget and both notifications, and its actual spend is 0, because there is no spend: no
notification will ever be sent from here. On AWS the spend is updated several times a day, and a budget
notification goes to e-mail addresses or to an SNS topic, and from the topic to the routes of lesson 14:
the forecast alert to a ticket, and a budget for the whole account crossing its actual at 100% early in
the month to a page.

The topic is in `us-east-1`, which is not a slip: the billing metric of the next section exists only
there, and an alarm can notify only a topic in its own region, so one topic there serves both.
