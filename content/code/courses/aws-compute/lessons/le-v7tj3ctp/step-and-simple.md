---
title: "Step and simple scaling: you write the thresholds"
version: 1
---

Before target tracking there were policies that do exactly what they are told. **You write the
alarm, the threshold and the amount, and the policy adds or removes that amount when the alarm
fires.** They are more work and less forgiving, and they are still the right tool when the
response has to be asymmetric in a way a target cannot express: add a lot quickly, remove one at a
time.

## Simple scaling, and the cooldown

A **simple scaling** policy has one adjustment. When its alarm fires it applies it, and then it
waits for the **cooldown**, 300 seconds by default, before it will respond to anything again. The
cooldown exists because the new instances take minutes to change the metric, and without it the
same alarm would fire again and again on the evidence of a load the first adjustment has already
answered.

`execute-policy` runs a policy by hand, as if its alarm had fired, and this one moto implements:

```
ana@laptop:~/aws$ aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name add-two --policy-type SimpleScaling --adjustment-type ChangeInCapacity --scaling-adjustment 2 --cooldown 300
ana@laptop:~/aws$ aws autoscaling execute-policy --auto-scaling-group-name web --policy-name add-two
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text
4	4
ana@laptop:~/aws$ aws autoscaling execute-policy --auto-scaling-group-name web --policy-name add-two --honor-cooldown
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text
6	6
```

Two to four, as the policy says. **The second call is where moto and AWS part.** `--honor-cooldown`
asks AWS to respect the cooldown, and on AWS a call 300 seconds or less after the first would not
scale; moto ignored the option and went to six. A group in this lab can be scaled by a simple
policy as often as you like, which is a fact about moto and not about the policy.

## Step scaling

A **step scaling** policy replaces the single adjustment with a table. Each row is a range of the
metric, measured from the alarm's threshold, and the number of instances to add in that range.
With an alarm at 60% CPU, the policy below adds one instance when the breach is from 0 to 20
points, and three when it is 20 points or more. The lower bound of a range is included and the
upper is not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A horizontal axis of average CPU from 0 to 100%. A dashed line marks the alarm threshold at 60%. Below it, no action. From 60 to 80%, a breach of 0 to 20 points, the step adds one instance. From 80% up, a breach of 20 points or more, it adds three. An arrow marks a reading of 85%, which falls in the second step.\"><defs><marker id=\"st-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60.0\" y=\"70\" width=\"372.0\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"432.0\" y=\"70\" width=\"124.0\" height=\"70\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"556.0\" y=\"70\" width=\"124.0\" height=\"70\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"246.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no action</text><text x=\"246.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the alarm is not in ALARM</text><text x=\"494.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\" font-weight=\"600\">+1</text><text x=\"494.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">breach 0 to 20</text><text x=\"618.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\" font-weight=\"600\">+3</text><text x=\"618.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">breach 20 and up</text><path d=\"M60.0 180 L694.0 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><path d=\"M60.0 176 L60.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0%</text><path d=\"M184.0 176 L184.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"184.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20%</text><path d=\"M308.0 176 L308.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"308.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40%</text><path d=\"M432.0 176 L432.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"432.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">60%</text><path d=\"M556.0 176 L556.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"556.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">80%</text><path d=\"M680.0 176 L680.0 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100%</text><text x=\"694.0\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CPU</text><path d=\"M432.0 40 L432.0 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"432.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">alarm threshold</text><path d=\"M587.0 228 L587.0 146\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><text x=\"579.0\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a reading of 85% is 25 above: three instances</text></svg>", "caption": "The two rows of the policy, drawn against the metric. The ranges are measured from the alarm threshold, not from zero, so the same table moves with the alarm if the threshold is changed."}
```

So a reading of 85% is 25 points above the threshold, falls in the second row, and adds three.
Step scaling has no cooldown: it responds to every alarm evaluation, and it avoids counting the
same rise twice by treating instances that are still warming up as already there. Asked to run the
policy for a reading of 85, moto gives up:

```
ana@laptop:~/aws$ aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name cpu-steps --policy-type StepScaling --adjustment-type ChangeInCapacity --metric-aggregation-type Average --step-adjustments MetricIntervalLowerBound=0,MetricIntervalUpperBound=20,ScalingAdjustment=1 MetricIntervalLowerBound=20,ScalingAdjustment=3
ana@laptop:~/aws$ aws autoscaling execute-policy --auto-scaling-group-name web --policy-name cpu-steps --metric-value 85 --breach-threshold 60

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**That 500 is moto failing on a call it does not implement**, as it did with instance refresh in
lesson 4. On AWS the same call would add three instances, because `--metric-value 85` and
`--breach-threshold 60` put the breach in the second step.

Three adjustment types decide what the number in a row means. `ChangeInCapacity` adds or removes
that many instances. `ExactCapacity` sets the count to it. `PercentChangeInCapacity` adds that
share of the current capacity, with `MinAdjustmentMagnitude` as a floor so that 10% of a group of
four still adds one.

## The alarm that drives it

A step or simple policy is driven by a CloudWatch alarm that you create and point at the policy's
ARN. Here is one, set to `ALARM` by hand to see what follows:

```
ana@laptop:~/aws$ STEPS=$(aws autoscaling describe-policies --auto-scaling-group-name web --policy-names cpu-steps --query 'ScalingPolicies[0].PolicyARN' --output text)
ana@laptop:~/aws$ aws cloudwatch put-metric-alarm --alarm-name web-cpu-high --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=AutoScalingGroupName,Value=web --statistic Average --period 60 --evaluation-periods 3 --threshold 60 --comparison-operator GreaterThanThreshold --alarm-actions "$STEPS"
ana@laptop:~/aws$ aws cloudwatch set-alarm-state --alarm-name web-cpu-high --state-value ALARM --state-reason "set by hand to see what follows"
ana@laptop:~/aws$ aws cloudwatch describe-alarms --alarm-names web-cpu-high --query "MetricAlarms[].[StateValue,StateReason]" --output text
ALARM	set by hand to see what follows
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text
6	6
```

moto stored the alarm, accepted its new state and connected it to nothing: six before, six after.
**On AWS an alarm whose action is a scaling policy invokes that policy every time it is evaluated in
`ALARM`**, so this one would have added three. Alarms, metrics and their dimensions are the
subject of `aws-operations` lessons 8 to 10; for this lesson the point is the wiring, which is the
alarm naming the policy and not the other way round.

## Which one

Start with target tracking. It writes its own alarms, it scales in on its own, and its one number
is easy to argue about. Reach for step scaling when you need the response to be steeper than
proportional, such as three instances at once for a sharp rise. Simple scaling is mostly what you
find in older configurations; there is nothing it does that a one-row step policy does not do
better.
