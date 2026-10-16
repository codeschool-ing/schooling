---
title: EstimatedCharges, the bill as a CloudWatch metric
version: 1
---

Budgets look at the month. The second instrument is a metric: **`EstimatedCharges`**, in the namespace
`AWS/Billing`, the month-to-date estimate of the bill in US dollars, updated several times a day. It is
published only in **`us-east-1`**, whatever region the account uses, and only after billing alerts are
turned on once in the billing preferences. An alarm on it is an alarm like lesson 10's:

```
ana@laptop:~/aws/bill$ aws cloudwatch put-metric-alarm --region us-east-1 --alarm-name bill-over-1600 --namespace AWS/Billing --metric-name EstimatedCharges --dimensions Name=Currency,Value=USD --statistic Maximum --period 21600 --evaluation-periods 1 --threshold 1600 --comparison-operator GreaterThanThreshold --alarm-actions arn:aws:sns:us-east-1:123456789012:billing
ana@laptop:~/aws/bill$ aws cloudwatch describe-alarms --region us-east-1 --query 'MetricAlarms[].[AlarmName,Namespace,MetricName,StateValue]' --output text
bill-over-1600	AWS/Billing	EstimatedCharges	OK
ana@laptop:~/aws/bill$ aws cloudwatch list-metrics --region us-east-1 --namespace AWS/Billing
{
    "Metrics": []
}
```

The alarm is the same 1,600 USD as the budget, on the maximum of a six-hour period, since the metric
changes a few times a day and a shorter period would mostly see no data. The last command is the honest
one: **there is no `AWS/Billing` metric in moto**, so this alarm will watch nothing for ever. moto also
reports it `OK`, where AWS starts an alarm in `INSUFFICIENT_DATA` until its metric arrives.

## What the metric is, and is not

`EstimatedCharges` is **cumulative over the month**: it climbs from the 1st and falls to near zero when the
next month starts. That shape makes a fixed threshold right for one question, *has the month passed
1,600?*, and wrong for most others: an alarm at 800 fires on the 16th of a normal month and on the 5th of a
bad one, and says the same thing both times. Two habits make it useful:

- **one alarm per service**, with the `ServiceName` dimension, `AmazonCloudWatch` or `AmazonEC2`, so the
  page names what moved;
- **the rate, not the level**: lesson 12's metric math applies, and `RATE(m1)` over the metric is dollars
  per second, the thing a spike changes. An alarm on the rate fires on the day the spend changes pace,
  whatever day of the month it is.

The next section does the second with the data a daily cost report would give, since moto has none.
