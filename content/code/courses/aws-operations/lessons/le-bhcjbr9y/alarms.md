---
title: Alarms on what the trail records
version: 1
---

A log read after the fact explains an incident. The same log, read as it arrives, can **raise** one.
Lesson 18 promised the alarm for a key pending deletion that something still uses; this is where it is
built, in two of the ways CloudTrail feeds alarms.

## A metric filter on the trail's log group

A trail can also send its events to a CloudWatch Logs group, and from there lesson 9's metric filters
turn matching events into a metric. AWS documents that a use of a key pending deletion is recorded with
the error message ending `is pending deletion.`, and a filter in the JSON syntax of filter patterns
matches it:

```
ana@laptop:~/aws/trail$ aws logs create-log-group --log-group-name /shop/cloudtrail
ana@laptop:~/aws/trail$ aws logs put-metric-filter --log-group-name /shop/cloudtrail --filter-name kms-pending-use --filter-pattern '{ ($.eventSource = kms.amazonaws.com) && ($.errorMessage = "* is pending deletion.") }' --metric-transformations metricName=KmsPendingKeyUse,metricNamespace=Shop/Security,metricValue=1
ana@laptop:~/aws/trail$ aws logs describe-metric-filters --log-group-name /shop/cloudtrail --query 'metricFilters[].[filterName,metricTransformations[0].metricName]' --output text
kms-pending-use	KmsPendingKeyUse
ana@laptop:~/aws/trail$ aws cloudwatch put-metric-alarm --alarm-name kms-pending-key-used --namespace Shop/Security --metric-name KmsPendingKeyUse --statistic Sum --period 300 --evaluation-periods 1 --threshold 0 --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching --alarm-actions arn:aws:sns:sa-east-1:123456789012:shop-page
```

On AWS, every attempt to use the key during its seven days now adds 1 to `KmsPendingKeyUse`, and the
alarm pages on the first. **moto stores the filter and the alarm and applies neither**: its metric filters
ignore JSON patterns, as lesson 9 found, and it evaluates no alarm.

## A rule on the event itself

For changes that matter the moment they happen, an EventBridge rule on the event is quicker than a metric:
CloudTrail sends management events to EventBridge as `AWS API Call via CloudTrail`, and a pattern picks
them. This one catches anybody disabling a key or scheduling its deletion.

`key-events.json`:

```json
{
  "source": ["aws.kms"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["kms.amazonaws.com"],
    "eventName": ["DisableKey", "ScheduleKeyDeletion"]
  }
}
```

```
ana@laptop:~/aws/trail$ aws events put-rule --name key-changes --event-pattern file://key-events.json --query RuleArn --output text
arn:aws:events:sa-east-1:123456789012:rule/key-changes
```

With `shop-page` as its target, as in lesson 19, the person on call learns of a key's scheduled deletion
the minute it is scheduled, with six days and twenty-three hours left to ask why.

The same pattern, with other event names, covers the short list most teams page on: the root user
signing in, a trail being stopped or deleted, a security group opened to `0.0.0.0/0`, an IAM policy
attached to a user. **A trail that can be stopped silently is not an audit log**, so `StopLogging` and
`DeleteTrail` belong on that list first.
