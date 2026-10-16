---
title: Composite alarms, and paging on the symptom
version: 1
---

The shop has an alarm on errors, one on latency, one on a queue's depth and one on the database's CPU.
During one incident all four fire within two minutes, and the person on call gets four pages for one
problem, and for a while cannot tell which is the cause and which are the consequences. **A composite
alarm** combines other alarms with a rule, and only the composite pages:

```
ALARM("api-errors") AND ALARM("api-latency")
```

```
ALARM("api-errors") OR (ALARM("api-latency") AND NOT ALARM("api-deploying"))
```

The rule language has `ALARM`, `OK` and `INSUFFICIENT_DATA` as functions of an alarm's name, joined with
`AND`, `OR` and `NOT`. The second rule pages on errors at once, and on latency only when no deployment
is running, because a canary slows things for a minute on purpose.

## The symptom, not the cause

The four alarms are of two kinds. Errors and latency are **symptoms**: customers feel them. Queue depth
and database CPU are **causes**, or candidates for one: a deep queue matters only if it makes requests
slow or failing. The rule that keeps on-call humane is to **page on symptoms and record causes**: the
composite of symptoms wakes a person; the cause alarms stay on the dashboard and in the notification,
where the person paged will look first, and wake nobody by themselves.

The contrary habit, paging on every cause, pages for a database at 80% CPU that nobody noticed because
customers did not, and trains people to acknowledge pages without reading them. Lesson 14 counts what
that costs.

## In the lab, and on AWS

```
ana@laptop:~/aws/alarms$ aws cloudwatch put-composite-alarm --alarm-name api-down --alarm-rule 'ALARM("api-errors") AND ALARM("api-latency")' 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the PutCompositeAlarm operation (reached max retries: 2): <!doctype html>
```

moto does not implement composite alarms, so no rule above was run. On AWS, a composite alarm also
accepts an **actions suppressor**: an alarm that, while it is in `ALARM`, stops the composite from
notifying, with a wait period around it. A deployment alarm as the suppressor is the documented way to
silence pages during a planned change without editing any alarm.

## What alarms cost

```
ana@laptop:~/aws/alarms$ python3 price.py AmazonCloudWatch AlarmMonitorUsage
AmazonCloudWatch, sa-east-1, published 2026-10-07
  Global-CW:AlarmMonitorUsage              0.000000 USD per Alarms     Global
  SAE1-CW:AlarmMonitorUsage                0.135000 USD per Alarms     $0.135 per alarm metric month (standard resolution) - South America (Sao Paulo)
  SAE1-CW:CompositeAlarmMonitorUsage       0.675000 USD per Alarms     $0.675 per composite alarm month - South America (Sao Paulo)
  SAE1-CW:HighResAlarmMonitorUsage         0.405000 USD per Alarms     $0.405 per alarm metric month (high resolution) - South America (Sao Paulo)
  SAE1-CW:LogAlarmMonitorUsage             0.100000 USD per Alarms     $0.10 per Alarm in South America (Sao Paulo)
  SAE1-CW:PromQLAlarmMonitorUsage          0.100000 USD per Alarms     $0.10 per Alarm in South America (Sao Paulo)
```

Thirteen and a half cents a month per standard alarm, three times that for high resolution, and 67.5
cents for a composite. Forty alarms cost 5.40 USD a month. **Alarms are cheap; pages are not**, and the
cost of an alarm worth having is the attention it takes, which the next lessons measure.
