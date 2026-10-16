---
title: "Target tracking: name a number and let AWS do the arithmetic"
version: 1
---

The picture most people bring is a rule: if the CPU goes above 70%, add one instance. That is a
scaling policy, and the oldest kind. **Target tracking is a thermostat instead.** You name a metric
and the value you want it to sit at, and the group works out, every time the metric moves, how
many instances would put it back at that value. You never write the threshold or the step; AWS
writes both, as alarms it owns.

## The arithmetic it does

The assumption underneath is that the metric is shared out over the instances: twice the
instances, half the CPU each. Under that assumption the capacity needed is the current capacity
times the metric over the target. Six instances averaging 75% CPU, with a target of 50%, need
6 × 75 / 50 = 9. When the answer is not a whole number, a scale-out rounds up, because 8.4
instances at 50% means nine.

That assumption is also how to choose the metric. **A good target metric falls when instances are
added.** Average CPU does, for a service whose work is computation. `ALBRequestCountPerTarget`,
the requests each instance receives from the load balancer, does too, and it is often the better
one for a web service, because it rises with the traffic itself rather than with one of its
effects. The length of a queue does not: ten more consumers do not make the queue shorter by
being there, only by working through it, so for a queue the metric is the backlog per instance,
which lesson 21 comes back to. The predefined metrics are `ASGAverageCPUUtilization`,
`ASGAverageNetworkIn`, `ASGAverageNetworkOut` and `ALBRequestCountPerTarget`; anything else is a
custom metric you publish.

## A group to scale

The group for this lesson is lesson 4's, made again in an empty moto with a maximum of twelve, and
with the template written inline rather than as a file:

```
ana@laptop:~/aws$ aws ec2 create-launch-template --launch-template-name web --launch-template-data '{"ImageId": "ami-0629d059c178d0eac", "InstanceType": "t3.micro"}' --query LaunchTemplate.LaunchTemplateId --output text
lt-8d61d7dd4606f9a1c
ana@laptop:~/aws$ SUBNETS=$(aws ec2 describe-subnets --query 'join(`,`, Subnets[].SubnetId)' --output text)
ana@laptop:~/aws$ aws autoscaling create-auto-scaling-group --auto-scaling-group-name web --launch-template 'LaunchTemplateName=web,Version=$Default' --min-size 2 --max-size 12 --desired-capacity 2 --vpc-zone-identifier "$SUBNETS" --default-instance-warmup 180
```

The last option, `--default-instance-warmup`, is the subject of the last section of this lesson.

## The policy, and what moto leaves out

```
ana@laptop:~/aws$ aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name cpu-50 --policy-type TargetTrackingScaling --target-tracking-configuration '{"PredefinedMetricSpecification": {"PredefinedMetricType": "ASGAverageCPUUtilization"}, "TargetValue": 50}'
ana@laptop:~/aws$ aws autoscaling describe-policies --auto-scaling-group-name web --policy-names cpu-50
{
    "ScalingPolicies": [
        {
            "AutoScalingGroupName": "web",
            "PolicyName": "cpu-50",
            "PolicyARN": "arn:aws:autoscaling:sa-east-1:123456789012:scalingPolicy:c322761b-3172-4d56-9a21-0ed9d6161d67:autoScalingGroupName/web:policyName/cpu-50",
            "PolicyType": "TargetTrackingScaling",
            "StepAdjustments": [],
            "TargetTrackingConfiguration": {
                "PredefinedMetricSpecification": {
                    "PredefinedMetricType": "ASGAverageCPUUtilization"
                },
                "TargetValue": 50.0
            },
            "PredictiveScalingConfiguration": {}
        }
    ]
}
ana@laptop:~/aws$ aws cloudwatch describe-alarms
{
    "MetricAlarms": [],
    "CompositeAlarms": []
}
```

Three answers, and two of them are moto's. **On AWS, `put-scaling-policy` prints the policy's ARN
and a list of the alarms it created**, and moto prints nothing. The description has the ARN, so
the policy exists. The empty `describe-alarms` is the real gap: AWS creates two CloudWatch alarms
for every target tracking policy, named `TargetTracking-web-AlarmHigh-` and
`TargetTracking-web-AlarmLow-` followed by an id, and moto creates neither. **moto also keeps no
metrics, so in this lab the policy never moves the group**: there is no CPU to measure and no
alarm to fire. Everything from here to the end of this section is AWS's documented behaviour,
not something you can watch happen.

The alarms belong to the policy, and AWS's documentation says not to edit or delete them; deleting
the policy deletes them. They are not symmetric. The high alarm fires after a few minutes above
the target, and the low one waits much longer below it before the group removes anything, because
removing an instance that has to come back five minutes later pays for a boot that served nobody.

## When there is more than one

A group may carry several target tracking policies, say CPU at 50% and requests per instance at
1,000. **The group scales out when any of them asks for more, and scales in only when all of them
agree to less.** That rule is what makes a second policy safe to add: it can only make the group
larger, never smaller than the first one wants.

Two settings change the shape of a policy:

- `DisableScaleIn` turns the policy into one that only adds. Something else, a schedule or a
  person, then decides when the group shrinks.
- The target is a value, not a band. A target of 50% means the group will run at 50% when the load
  is steady, which is the **headroom** the policy keeps: the other half is what absorbs a rise in
  the minutes before new instances are serving.

That last point is the real decision in a target tracking policy, and it is a cost decision.
Tracking CPU at 50% means paying for roughly twice the capacity the steady load uses. Tracking it
at 80% pays for a quarter more, and leaves the group saturated for every minute its new instances
take to arrive. Lesson 4's instance refresh arithmetic had the same shape: time against capacity,
and the service decides which it can spare.
