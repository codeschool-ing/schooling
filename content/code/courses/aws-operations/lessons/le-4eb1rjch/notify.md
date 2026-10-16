---
title: Telling somebody, through a topic
version: 1
---

An alarm's state changes in silence unless it has **actions**. The usual action is to publish to an SNS
**topic**, and the topic delivers to every **subscription** it has: an email address, an SMS number, an
HTTPS endpoint of a paging service, a queue, a Lambda function. The shop's alarm already names the
topic `shop-oncall` for both `ALARM` and `OK`, so the person paged also learns when it is over.

A topic decouples the alarm from the people. **Alarms name a topic per audience, never a person**:
when the rotation changes on Monday, the subscriptions change and none of the forty alarms does.
Lesson 14 is about that rotation.

## Following the route in the lab

An email subscription needs somebody to click a confirmation link, which a lab cannot do, so the lab
subscribes a queue and reads the queue as the inbox. Then it forces the alarm into `ALARM` by hand,
which is also how a team tests the route on AWS:

```
ana@laptop:~/aws/alarms$ QUEUE=$(aws sqs create-queue --queue-name oncall-inbox --query QueueUrl --output text)
ana@laptop:~/aws/alarms$ aws sns subscribe --topic-arn arn:aws:sns:sa-east-1:123456789012:shop-oncall --protocol sqs --notification-endpoint arn:aws:sqs:sa-east-1:123456789012:oncall-inbox --query SubscriptionArn --output text
arn:aws:sns:sa-east-1:123456789012:shop-oncall:4621fb4c-a6f6-41d6-878f-4eb73b672643
ana@laptop:~/aws/alarms$ aws cloudwatch set-alarm-state --alarm-name api-errors --state-value ALARM --state-reason 'set by hand to test the route'
ana@laptop:~/aws/alarms$ aws sqs receive-message --queue-url $QUEUE --wait-time-seconds 2 --query 'length(Messages || `[]`)'
0
ana@laptop:~/aws/alarms$ aws sns publish --topic-arn arn:aws:sns:sa-east-1:123456789012:shop-oncall --subject 'ALARM: api-errors' --message file://notification.json --query MessageId --output text
8b6c26aa-61d0-4648-8fc1-6a859a764da8
ana@laptop:~/aws/alarms$ aws sqs receive-message --queue-url $QUEUE --wait-time-seconds 2 --query 'Messages[0].Body' --output text | jq -r .Message | jq '{AlarmName, NewStateValue, NewStateReason}'
{
  "AlarmName": "api-errors",
  "NewStateValue": "ALARM",
  "NewStateReason": "Threshold Crossed: 3 out of the last 5 datapoints were greater than the threshold (10.0)."
}
```

Read it in order. The subscription is made. `set-alarm-state` moves the alarm to `ALARM`, and **the
queue receives nothing**: moto changes the state and runs no action. On AWS, that one command is the
standard test that a page reaches the phone it should, and running it once after every change to the
route is cheap.

The lab then publishes by hand what CloudWatch would have published, `notification.json`, written by
this lesson in the documented shape of an alarm's message:

```json
{
  "AlarmName": "api-errors",
  "NewStateValue": "ALARM",
  "NewStateReason": "Threshold Crossed: 3 out of the last 5 datapoints were greater than the threshold (10.0).",
  "OldStateValue": "OK",
  "Region": "South America (Sao Paulo)",
  "Trigger": {
    "MetricName": "Errors5xx",
    "Namespace": "Shop",
    "Statistic": "SUM",
    "Period": 60,
    "EvaluationPeriods": 5,
    "DatapointsToAlarm": 3,
    "ComparisonOperator": "GreaterThanThreshold",
    "Threshold": 10.0,
    "TreatMissingData": "notBreaching"
  }
}
```

The queue receives it, wrapped in SNS's own envelope, and `jq` unwraps the `Message` to the three fields
a person reads first. **Every alarm message says which alarm, what state, and why**: `NewStateReason`
is CloudWatch's sentence about the data points, and the `Trigger` block repeats the alarm's rule, so the
person paged does not need the console to know what crossed what.

## What each subscription is for

| subscription | use it for |
|---|---|
| a paging service (HTTPS) | waking a person: acknowledgement, escalation, a phone that rings |
| email | a record, and for alarms that can wait for the morning |
| a chat channel, through AWS's chat integration | the team seeing it together during an incident |
| a queue or a Lambda function | automation: opening a ticket, scaling, a runbook step |

Email alone is not paging: nobody's phone rings for an email at three in the morning, which is either
the right answer for that alarm or the reason an outage was found by a customer.
