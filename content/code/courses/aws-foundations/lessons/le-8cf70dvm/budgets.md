---
title: A budget, and what its two alerts mean
version: 1
---

**A budget is a number and a set of thresholds; it watches the bill and tells somebody when a
threshold is crossed.** The common picture is a spending limit, a ceiling AWS will not let the
account go through. That is not what it is. A budget that reaches 100% sends an e-mail, and every
machine behind it keeps running and keeps charging. Lesson 1 put a budget third in the first hour of
a real account, before anything that costs money, for exactly that reason. It is a warning, and a
warning is only useful while the amount is still small.

## The budget lesson 1 promised

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. The budget is described in two files: the budget itself, and its notifications with
the people and topics each one tells. Write both in `~/aws`:

```sh
cat > budget.json <<'EOF'
{
  "BudgetName": "shop-monthly",
  "BudgetType": "COST",
  "TimeUnit": "MONTHLY",
  "BudgetLimit": {"Amount": "50", "Unit": "USD"}
}
EOF
cat > notifications.json <<'EOF'
[
  {
    "Notification": {"NotificationType": "ACTUAL", "ComparisonOperator": "GREATER_THAN",
                     "Threshold": 80, "ThresholdType": "PERCENTAGE"},
    "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "aws+billing@example.com"}]
  },
  {
    "Notification": {"NotificationType": "FORECASTED", "ComparisonOperator": "GREATER_THAN",
                     "Threshold": 100, "ThresholdType": "PERCENTAGE"},
    "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "aws+billing@example.com"},
                    {"SubscriptionType": "SNS",
                     "Address": "arn:aws:sns:sa-east-1:123456789012:budget-alerts"}]
  }
]
EOF
```

The **budget** is a cost budget of 50 dollars a month. The first **notification** fires when the
actual cost of the month passes 80% of that, 40 dollars. It e-mails a shared mailbox rather than a
person, for the reason lesson 1 gave for the root user's address. The second fires when AWS's
forecast for the month passes 100%, and tells an SNS topic as well as the mailbox. A topic is how an
alert reaches a chat channel or a pager rather than an inbox. Create the topic, then the budget, and
read it back. Budgets belong to an account rather than a region, so the commands name the account,
moto's default `123456789012`:

```
ana@laptop:~/aws$ aws sns create-topic --name budget-alerts
{
    "TopicArn": "arn:aws:sns:sa-east-1:123456789012:budget-alerts"
}
ana@laptop:~/aws$ aws budgets create-budget --account-id 123456789012 --budget file://budget.json --notifications-with-subscribers file://notifications.json
ana@laptop:~/aws$ aws budgets describe-budgets --account-id 123456789012
{
    "Budgets": [
        {
            "BudgetName": "shop-monthly",
            "BudgetLimit": {
                "Amount": "50",
                "Unit": "USD"
            },
            "CostTypes": {
                "IncludeTax": true,
                "IncludeSubscription": true,
                "UseBlended": false,
                "IncludeRefund": true,
                "IncludeCredit": true,
                "IncludeUpfront": true,
                "IncludeRecurring": true,
                "IncludeOtherSubscription": true,
                "IncludeSupport": true,
                "IncludeDiscount": true,
                "UseAmortized": false
            },
            "TimeUnit": "MONTHLY",
            "TimePeriod": {
                "Start": "2026-09-30T21:00:00-03:00",
                "End": "2087-06-14T21:00:00-03:00"
            },
            "CalculatedSpend": {
                "ActualSpend": {
                    "Amount": "0",
                    "Unit": "USD"
                },
                "ForecastedSpend": {
                    "Amount": "0",
                    "Unit": "USD"
                }
            },
            "BudgetType": "COST",
            "LastUpdatedTime": "2026-10-16T12:59:51.960789-03:00"
        }
    ]
}
```

Four things in that answer are worth reading. **`CostTypes` is what the budget counts**, and by
default it counts nearly everything: tax, support, upfront payments and refunds, and also
**credits**. A new account living on credits (lesson 1) therefore shows a budget near zero while it
spends. The first month after the credits run out arrives at full size, so create a budget meant to
watch usage with `IncludeCredit` set to `false`. `UseBlended` and `UseAmortized` are both `false`,
so the budget counts **unblended** cost, the rate charged at the time. The section on Cost Explorer
says what the other two would change. moto filled in `TimePeriod` the way AWS's documentation says
AWS fills it. It runs from the first day of the current month, in UTC, to 15 June 2087, AWS's
stand-in for "until deleted". The prompt's time zone, São Paulo's, is why it prints as 21:00 the day
before. And **`CalculatedSpend` is zero, because moto has no spending.** Against AWS that block
carries the month's actual cost so far and the forecast for its end. Those are the two numbers the
notifications compare against.

```
ana@laptop:~/aws$ aws budgets describe-notifications-for-budget --account-id 123456789012 --budget-name shop-monthly --output text
NOTIFICATIONS	GREATER_THAN	ACTUAL	80	PERCENTAGE
NOTIFICATIONS	GREATER_THAN	FORECASTED	100	PERCENTAGE
ana@laptop:~/aws$ aws budgets describe-subscribers-for-notification --account-id 123456789012 --budget-name shop-monthly --notification NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the DescribeSubscribersForNotification operation (reached max retries: 2): <!doctype html>
```

moto kept both notifications and accepted the SNS topic as a subscriber. But **it cannot list the
subscribers back**: the operation that reads them answers with a server error. So this lab cannot
show whether moto stored the topic and the mailbox. Against AWS, the topic also needs an access
policy that lets `budgets.amazonaws.com` publish to it, or the topic drops the alert. moto does not
judge resource policies, so that part was not run either.

## Actual and forecasted are two different questions

**An actual alert asks "how much has gone?". A forecasted alert asks "where will this month
end?".** They fire on different days for the same account, and each calls for a different
response.

- **Actual, at 80%**, fires when the money is already spent. It means: look now, because what is
  left of the month is the other 20%. It is the alert that cannot be wrong, and the one that arrives
  late.
- **Forecasted, at 100%**, fires when AWS projects that the month will end over the budget. That can
  happen on the fifth day of the month with almost nothing spent. It means: something changed in the
  rate of spending. It is the early warning, and AWS's documentation says it needs about **five
  weeks of history** before it can forecast anything. On a new account only the actual alert works
  at first.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l13-alerts\" aria-label=\"An illustration of one month against a budget, not a capture. The horizontal axis is the day of the month, from 1 to 30; the vertical axis is spending as a percentage of the budget, with lines at 80% and 100%. The actual spending rises slowly until day 8, when a new machine starts, and then faster. On day 10 the forecast, drawn dashed from that day, already ends the month above 100%, so the forecasted alert fires on day 10. The actual spending crosses 80% on day 21, and the actual alert fires then.\"><path d=\"M90.0 280.0 L670.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 280.0 L90.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"270.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"470.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><text x=\"670.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><text x=\"380.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">day of the month</text><text x=\"82.0\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0%</text><text x=\"90.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">spending, as a share of the budget</text><path d=\"M90.0 157.3 L670.0 157.3\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"82.0\" y=\"157.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">80%</text><path d=\"M90.0 126.7 L670.0 126.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"82.0\" y=\"126.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">100%</text><path d=\"M90.0 277.7 L110.0 275.4 L130.0 273.1 L150.0 270.8 L170.0 268.5 L190.0 266.2 L210.0 263.9 L230.0 261.6 L250.0 253.6 L270.0 245.6 L290.0 237.5 L310.0 229.5 L330.0 221.5 L350.0 213.5 L370.0 205.5 L390.0 197.4 L410.0 189.4 L430.0 181.4 L450.0 173.4 L470.0 165.4 L490.0 157.3 L510.0 149.3 L530.0 141.3 L550.0 133.3 L570.0 125.3 L590.0 117.2 L610.0 109.2 L630.0 101.2 L650.0 93.2 L670.0 85.1\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"666.0\" y=\"103.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">actual</text><path d=\"M270.0 245.6 L670.0 57.7\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"666.0\" y=\"45.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">forecast, made on day 10</text><circle cx=\"270.0\" cy=\"245.6\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"280.0\" y=\"267.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">day 10: forecasted alert</text><circle cx=\"490.0\" cy=\"157.3\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"500.0\" y=\"177.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">day 21: actual alert</text><text x=\"230.0\" y=\"235.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a new machine</text><path d=\"M230.0 243.6 L230.0 255.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360.0\" y=\"334.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">an illustration, not a capture</text></svg>", "caption": "The forecast warns when the rate changes; the actual alert, when the money is gone."}
```

**Both arrive behind the spending.** AWS's documentation says AWS refreshes budget data up to three
times a day. An alert set at 80% goes out at the first refresh after spending crossed the line,
which may be well past it. A machine started by mistake on Friday evening shows up on the next
refresh, not the minute it started, and the bill does not wait for the e-mail.

## A budget that acts, and what it still does not do

An alert informs; a **budget action** does something when a threshold is crossed. AWS's
documentation lists three kinds:

- **apply an IAM policy** to a user, group or role, such as a policy that denies starting new
  instances, the subject of lessons 7 and 8;
- **apply a service control policy** to an account or an organisational unit, which only the
  management account can do, because only it can attach SCPs (lesson 4);
- **stop specific EC2 or RDS instances**, which AWS does through Systems Manager.

Each action runs at once or waits for somebody to approve it. It runs as an IAM role you give the
budget. **None of this is in moto**: asking for a budget's actions is a server error.

```
ana@laptop:~/aws$ aws budgets describe-budget-actions-for-budget --account-id 123456789012 --budget-name shop-monthly 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the DescribeBudgetActionsForBudget operation (reached max retries: 2): <!doctype html>
```

**Even an action does not stop spending, only some of it.** A policy that denies new instances
leaves running ones running. A stopped instance stops charging for its hours, and its disks keep
charging for every gigabyte they hold. Nothing a budget does deletes a resource, which is the only
thing that ends its cost. What budgets themselves cost is in the price list:

```
ana@laptop:~/aws$ python3 price.py AWSBudgets 20260911124529 aws-other BudgetsUsage ActionEnabledBudgetsUsage
AWSBudgets 20260911124529, published 2026-09-11, USD
BudgetsUsage
          0 to       Inf Budget-days 0.0000
ActionEnabledBudgetsUsage
          0 to        62 Budget-days 0.0000
         62 to       Inf Budget-days 0.1000
```

In the list AWS published on **11 September 2026**, a budget with only alerts costs nothing. AWS
bills a budget with an action per budget per day, and the first 62 of those budget-days in a month
are free. That is two such budgets for a whole month. After that, each costs 0.10 dollars a day. The
region is `aws-other` because Budgets belongs to no region.

**Where the budget lives decides what it sees.** A budget created in a member account watches that
account. A budget created in the management account watches the whole organisation, because
consolidated billing (lesson 3) puts every account's charges on that account's bill. Filters can
narrow it to one account, one service or one tag. Filtering by tag only works for tags that billing
has been told about, which is the next section.
