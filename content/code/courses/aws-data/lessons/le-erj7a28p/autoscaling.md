---
title: Autoscaling
version: 1
---

**DynamoDB autoscaling is not part of DynamoDB.** It is Application Auto Scaling, the same service that
scales other AWS resources, driving the table's provisioned capacity through `update-table` on your
behalf. It applies only to provisioned tables and indexes, and it is set up in two steps: a **scalable
target**, which says what may move and between which bounds, and a **scaling policy**, which says what
to aim for. The policy is a file. `policy.json`:

```json
{
  "TargetValue": 70.0,
  "PredefinedMetricSpecification": {"PredefinedMetricType": "DynamoDBWriteCapacityUtilization"},
  "ScaleOutCooldown": 60,
  "ScaleInCooldown": 60
}
```

**Target tracking at 70%**: keep the consumed write units at about 70% of the provisioned ones, adding
capacity when they run above it and removing it when they run well below. The cooldowns are the
seconds to wait after one change before considering the next.

```
ana@laptop:~/aws$ aws application-autoscaling register-scalable-target --service-namespace dynamodb --resource-id table/products --scalable-dimension dynamodb:table:WriteCapacityUnits --min-capacity 5 --max-capacity 500
{
    "ScalableTargetARN": "arn:aws:application-autoscaling:sa-east-1:123456789012:scalable-target/m5dloybd3ubrfiyla2pm9qo1gjve3osjqew6"
}
ana@laptop:~/aws$ aws application-autoscaling put-scaling-policy --service-namespace dynamodb --resource-id table/products --scalable-dimension dynamodb:table:WriteCapacityUnits --policy-name products-writes --policy-type TargetTrackingScaling --target-tracking-scaling-policy-configuration file://policy.json --query "Alarms[].AlarmName"
[
    "TargetTracking-table/products-AlarmHigh-7383b42b-b07f-4480-b7f2-281ad286ed12",
    "TargetTracking-table/products-AlarmLow-1792338c-7a9a-4a3f-a0be-df8b0a5c97e8",
    "TargetTracking-table/products-ProvisionedCapacityHigh-f8e77f49-847a-4b6d-a4a5-55e4fc20092b",
    "TargetTracking-table/products-ProvisionedCapacityLow-d6a2a5d3-74a8-4572-a1a4-ff7bf74ff4df"
]
```

The target allows the products table to move between 5 and 500 write units. The policy answered with
four CloudWatch alarms, because that is how target tracking works: it does not watch the table itself,
it creates alarms on the table's metrics and acts when one of them fires.

```
ana@laptop:~/aws$ aws cloudwatch describe-alarms --query 'MetricAlarms[].[MetricName,ComparisonOperator,Threshold,Period,EvaluationPeriods]' --output text
ConsumedReadCapacityUnits	GreaterThanThreshold	42.0	60	2
ConsumedReadCapacityUnits	LessThanThreshold	30.0	60	15
ProvisionedReadCapacityUnits	GreaterThanThreshold	1.0	300	2
ProvisionedReadCapacityUnits	LessThanThreshold	1.0	300	3
ana@laptop:~/aws$ aws application-autoscaling describe-scaling-activities --service-namespace dynamodb --resource-id table/products 2>&1 | head -2

aws: [ERROR]: An error occurred (500) when calling the DescribeScalingActivities operation (reached max retries: 2): <!doctype html>
```

**The alarms have the shape AWS creates, and the wrong contents.** Two watch the consumed units, one
minute at a time: one fires after 2 minutes above the target, one after 15 minutes well below it,
which is why scaling out is quick and scaling in is slow on purpose. Two more watch the provisioned
capacity itself. But this is a policy on write units, and every alarm names a read metric; and the
thresholds, 42 and 30, are 70% and 50% of 60 seconds of a single unit, not of the 5 units this table
has. On AWS they are computed from the table's real capacity and change every time it moves. moto
records a policy and draws alarms of the right shape, and nothing behind them is real.

**And nothing scales.** moto publishes no metrics, so no alarm ever fires, the capacity stays where
`update-table` put it, and the history of scaling activities is not implemented at all: the `500` is
moto's server failing, not an answer. What AWS would do was not run here, and it is worth stating
plainly. When writes rise above 70% of capacity for two minutes, Application Auto Scaling raises the
capacity to bring them back to 70%, within the bounds of the target. When they fall well below for fifteen, it lowers it, subject to the day's allowance of decreases. Each step takes minutes from the
first busy request, and during those minutes the table serves what it has.
