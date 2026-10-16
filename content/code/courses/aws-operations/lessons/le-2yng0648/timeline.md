---
title: The timeline, built from what the systems recorded
version: 1
---

Every review starts with a timeline: what happened, in order, with times. Written from memory the next
day, it is wrong in the places that matter, the gaps between a cause and the first sign of it. **The
systems already recorded the timeline**, each in its own place: the deployment's creation time, the log
lines, the alarm's change of state. Collecting them is a short program.

The lab stages a small incident, compressed into half a minute: a deployment, then error lines in the
API's log group, then the alarm going into `ALARM` (set by hand, since moto evaluates no alarm). Then
the program reads the three sources back, each with its own API, and merges them:

```python
# timeline.py: one incident's events, from three sources, in time order
import datetime as dt

import boto3

events = []
deploy = boto3.client("codedeploy")
for d in deploy.list_deployments(applicationName="shop-api", deploymentGroupName="prod")["deployments"]:
    info = deploy.get_deployment(deploymentId=d)["deploymentInfo"]
    events.append((info["createTime"], "deploy", f"deployment {d[:8]} created"))

logs = boto3.client("logs")
for e in logs.filter_log_events(logGroupName="/shop/api", filterPattern="503")["events"]:
    t = dt.datetime.fromtimestamp(e["timestamp"] / 1000, dt.timezone.utc)
    events.append((t, "logs", e["message"]))

cloudwatch = boto3.client("cloudwatch")
for a in cloudwatch.describe_alarms(AlarmNames=["api-errors"])["MetricAlarms"]:
    events.append((a["StateUpdatedTimestamp"], "alarm", f'{a["AlarmName"]} {a["StateValue"]}'))

for t, source, what in sorted(events):
    print(f"{t.astimezone(dt.timezone.utc):%H:%M:%S}  {source:<6}  {what}")
```

```
ana@laptop:~/aws/incident$ python3 timeline.py
16:58:53  deploy  deployment 7fe87a08 created
16:59:01  logs    {"status":503,"path":"/checkout"}
16:59:05  logs    {"status":503,"path":"/checkout"}
16:59:08  logs    {"status":503,"path":"/cart"}
16:59:18  alarm   api-errors ALARM
```

Read it as a reviewer would. A deployment at 16:58:53; **eight seconds later**, the first 503 on
`/checkout`; the alarm at 16:59:18, seventeen seconds after the first error. Compressed as it is, the
shape is the one real incidents have: the change comes first, the symptom follows, and the alarm comes
last, because it waits for a pattern (lesson 10). Nobody had to remember any of it.

Three habits make a real timeline this easy:

- **every source in one time zone**, UTC in the tools and the local time added for people, never mixed;
- **a deployment record for every change**, including the ones made by hand in an emergency, so the
  question "what changed?" has an answer to read rather than to reconstruct;
- **the channel's own messages are a source**: when the commander decided to roll back, and when the
  graph turned, are times too, and the scribe's job is to make them exact.

The rest of the timeline, who did what and why, comes from the people, in the review, which is the next
section's subject.
