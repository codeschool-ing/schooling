---
title: Evaluating an alarm yourself, because moto will not
version: 1
---

Ten minutes in the life of the shop's API: quiet, then errors above 10 in most minutes, then nothing
at all. The loop publishes one data point per minute, in the past, from eleven minutes ago to four
minutes ago; for the last three minutes it publishes nothing, as an API that has crashed publishes
nothing:

```sh
now=$(date -u +%s)
for pair in 11:0 10:1 9:0 8:12 7:15 6:0 5:14 4:16; do
  m=${pair%:*} v=${pair#*:}
  aws cloudwatch put-metric-data --namespace Shop --metric-name Errors5xx \
    --dimensions Service=api --unit Count --value "$v" \
    --timestamp "$(date -u -d "@$((now - m * 60))" +%Y-%m-%dT%H:%M:%SZ)"
done
```

```
ana@laptop:~/aws/alarms$ aws cloudwatch describe-alarms --alarm-names api-errors --query 'MetricAlarms[0].[StateValue,StateReason]' --output text
OK	Unchecked: Initial alarm creation
```

The data is there and the alarm is still `OK`, unchecked. What CloudWatch would have decided is a
question with a precise answer, and a short program can give it. It is a **model of the evaluation AWS
documents**, not CloudWatch's code: it reads the data points back with `boto3`, the Python library the
AWS command line is built on (moto installed it), and applies M of N minute by minute, with each of the
four ways of treating missing data:

```python
# alarm.py: what CloudWatch would decide, minute by minute, for one alarm
import datetime as dt
import sys

import boto3

THRESHOLD, M, N = 10, 3, 5            # 3 of the last 5 minutes above 10
TREAT = sys.argv[1] if len(sys.argv) > 1 else "missing"

now = dt.datetime.now(dt.timezone.utc).replace(second=0, microsecond=0)
minutes = [now - dt.timedelta(minutes=k) for k in range(12, 0, -1)]
points = boto3.client("cloudwatch").get_metric_statistics(
    Namespace="Shop", MetricName="Errors5xx",
    Dimensions=[{"Name": "Service", "Value": "api"}],
    StartTime=minutes[0], EndTime=now, Period=60, Statistics=["Sum"],
)["Datapoints"]
value = {p["Timestamp"].replace(second=0, microsecond=0): p["Sum"] for p in points}

state = "INSUFFICIENT_DATA"
for i, minute in enumerate(minutes):
    window = [value.get(m) for m in minutes[max(0, i - N + 1):i + 1]]
    if TREAT == "breaching":
        window = [THRESHOLD + 1 if v is None else v for v in window]
    elif TREAT == "notBreaching":
        window = [0 if v is None else v for v in window]
    present = [v for v in window if v is not None]
    if not present:
        state = state if TREAT == "ignore" else "INSUFFICIENT_DATA"
    elif sum(v > THRESHOLD for v in present) >= M:
        state = "ALARM"
    elif TREAT != "ignore" or len(present) == len(window):
        state = "OK"
    shown = "-" if value.get(minute) is None else int(value[minute])
    print(f"{minute:%H:%M}  {shown:>3}  {state}")
```

The four treatments differ only in what a minute with no data counts as: **`notBreaching`** counts it
as good, `breaching` as bad, `missing` leaves it out (and with nothing left, the state is
`INSUFFICIENT_DATA`), `ignore` keeps the alarm in the state it was in. The times printed are UTC.

## The alarm that went quiet when the service died

The shop's alarm treats missing data as not breaching:

```
ana@laptop:~/aws/alarms$ python3 alarm.py notBreaching
16:29    -  OK
16:30    0  OK
16:31    1  OK
16:32    0  OK
16:33   12  OK
16:34   15  OK
16:35    0  OK
16:36   14  ALARM
16:37   16  ALARM
16:38    -  ALARM
16:39    -  OK
16:40    -  OK
```

Read the right-hand column down. The errors start at 16:33; by 16:36, three of the last five minutes
are above 10, and the alarm fires. Then **the API stops publishing at all**, and two minutes later the
alarm is back to `OK`. The last three minutes have no data, `notBreaching` counts them as good, and
only two bad minutes are left in the window. **The worst outage of the hour, a service that is down,
reads as recovery.**

The same data under the other treatments:

```
ana@laptop:~/aws/alarms$ python3 alarm.py breaching | tail -4
16:37   16  ALARM
16:38    -  ALARM
16:39    -  ALARM
16:40    -  ALARM
ana@laptop:~/aws/alarms$ python3 alarm.py ignore | tail -4
16:37   16  ALARM
16:38    -  ALARM
16:39    -  ALARM
16:40    -  ALARM
```

`breaching` and `ignore` both hold the alarm in `ALARM` through the silence. Which is right depends on
what silence means for the metric:

| the metric | silence means | treat missing data as |
|---|---|---|
| errors counted by a metric filter with `defaultValue=0` | nothing to count | `notBreaching`: the zero is published, real silence is rare |
| errors published by the application itself | the application may be down | `breaching`, or a second alarm on the heartbeat |
| a batch job's success, once a night | the job did not run | `breaching` |
| latency from a service with no traffic at night | no requests, nothing wrong | `notBreaching` or `ignore` |

The shop's first alarm was configured for the first row and fed by the second. That mismatch is the
lesson; the fix is either `breaching`, or **a separate alarm on the traffic itself**, which fires when
requests per minute drop to zero. On AWS, the evaluation would have happened every minute without
anybody running anything, and the decisions in the right-hand column are the ones CloudWatch documents
for this configuration; they were computed here, not observed.
