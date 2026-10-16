---
title: Tuning, one alarm at a time
version: 1
---

The month's table names the alarms to change. Each one gets one of four moves, and the order is the
order to try them in:

1. **Fix the cause.** `disk-80` fires every night because the backup writes its temporary files to the
   data disk. Moving them elsewhere ends the pages and the risk together.
2. **Make it wait.** An alarm that fires on one bad five-minute period pages for every spike. Twelve
   periods out of twelve, an hour above the line, pages only for a disk that is really filling.
3. **Make it a ticket.** `db-cpu` and `queue-depth` are causes. When they matter, `api-errors` or
   `api-latency` page anyway; until then they are work for the morning.
4. **Delete it.** An alarm nobody has acted on in three months, and that would not have changed any
   decision, is noise with a name. Its metric stays on the dashboard.

The first move is the team's work, not an AWS command. The other three are a change to the alarm.

## Changing an alarm without losing it

The shop's five alarms all page, through `shop-page`:

```
ana@laptop:~/aws/oncall$ aws cloudwatch describe-alarms --query 'MetricAlarms[].[AlarmName,AlarmActions[0]]' --output text
api-errors	arn:aws:sns:sa-east-1:123456789012:shop-page
api-latency	arn:aws:sns:sa-east-1:123456789012:shop-page
db-cpu	arn:aws:sns:sa-east-1:123456789012:shop-page
queue-depth	arn:aws:sns:sa-east-1:123456789012:shop-page
disk-80	arn:aws:sns:sa-east-1:123456789012:shop-page
ana@laptop:~/aws/oncall$ TICKET=$(aws sns create-topic --name shop-ticket --query TopicArn --output text); echo $TICKET
arn:aws:sns:sa-east-1:123456789012:shop-ticket
```

**`put-metric-alarm` replaces the whole alarm.** There is no command to change only its actions. A call
naming `db-cpu` and the new topic and nothing else is refused, since the periods and the comparison are
required; one that gives those and forgets the dimensions makes a different alarm under the same name,
watching a metric nobody publishes. The safe way is to read the alarm, change the fields, and write all of it
back. `describe-alarms` returns more than `put-metric-alarm` accepts, its state and its timestamps among
them, so a small `jq` filter, `to-ticket.jq`, keeps only the settings, swaps the topic, and drops the
fields the alarm leaves empty, which the command line would otherwise refuse as `null`:

```
# to-ticket.jq: an alarm's settings, routed to the topic in $t
{AlarmName, AlarmDescription, Namespace, MetricName, Dimensions, Statistic,
 Period, EvaluationPeriods, DatapointsToAlarm, Threshold, ComparisonOperator,
 TreatMissingData, AlarmActions: [$t], OKActions: [$t]}
| with_entries(select(.value != null))
```

```
ana@laptop:~/aws/oncall$ jq --arg t "$TICKET" -f to-ticket.jq <(aws cloudwatch describe-alarms --alarm-names db-cpu --query MetricAlarms[0]) > db-cpu.json
ana@laptop:~/aws/oncall$ aws cloudwatch put-metric-alarm --cli-input-json file://db-cpu.json
ana@laptop:~/aws/oncall$ jq --arg t "$TICKET" -f to-ticket.jq <(aws cloudwatch describe-alarms --alarm-names queue-depth --query MetricAlarms[0]) > queue-depth.json
ana@laptop:~/aws/oncall$ aws cloudwatch put-metric-alarm --cli-input-json file://queue-depth.json
```

`disk-80` takes the second move as well as the third, an hour of periods before it says anything:

```
ana@laptop:~/aws/oncall$ jq --arg t "$TICKET" -f to-ticket.jq <(aws cloudwatch describe-alarms --alarm-names disk-80 --query MetricAlarms[0]) | jq ".EvaluationPeriods = 12 | .DatapointsToAlarm = 12" > disk-80.json
ana@laptop:~/aws/oncall$ aws cloudwatch put-metric-alarm --cli-input-json file://disk-80.json
```

```
ana@laptop:~/aws/oncall$ aws cloudwatch describe-alarms --query 'MetricAlarms[].[AlarmName,AlarmActions[0],EvaluationPeriods]' --output text
api-errors	arn:aws:sns:sa-east-1:123456789012:shop-page	5
api-latency	arn:aws:sns:sa-east-1:123456789012:shop-page	5
db-cpu	arn:aws:sns:sa-east-1:123456789012:shop-ticket	1
queue-depth	arn:aws:sns:sa-east-1:123456789012:shop-ticket	1
disk-80	arn:aws:sns:sa-east-1:123456789012:shop-ticket	12
```

Two alarms page, three make tickets, and `disk-80` waits twelve periods. In the month just measured that
is the 30 pages of the previous section instead of 121. Keep the JSON files: they are the alarms as they
are now, and the diff between two of them is the change the next review reads. Better still, the alarms
live in the CloudFormation or Terraform of lessons 4 to 7, where a change like this one is a pull request.

## Keeping it tuned

Alert fatigue comes back, because systems change and alarms do not. Three habits keep it away:

- **the handoff counts the pages**, alarm by alarm, and an alarm acted on less than half the time in a
  month gets one of the four moves;
- **every new alarm says who acts on it and what they do** in its description, so an alarm whose
  description is empty is the first candidate for the fourth move;
- **an alarm that never fires is tested**, with `set-alarm-state` as in lesson 10, because silence from
  a broken route reads the same as silence from a healthy service.
