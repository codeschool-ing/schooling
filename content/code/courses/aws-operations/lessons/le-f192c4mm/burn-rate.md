---
title: Burn rate, and paging on the budget
version: 1
---

An alarm on the error rate (lesson 10) pages when 2% of requests fail, whatever that means for the month.
An alarm on the **budget** pages when the month is in danger. The quantity it watches is the **burn
rate**: how fast the budget is being spent, compared with spending it evenly.

> burn rate = error rate / (1 − SLO)

At a burn rate of 1, the budget lasts exactly the 30 days. At 14.4 it lasts about 50 hours, so one hour
at that rate spends 2% of the month's budget; at 36 it is gone in 20 hours. The thresholds widely used,
from Google's *Site Reliability Workbook*, page when the rate is above **14.4 over the last hour** (2%
of the budget gone in an hour) or above **6 over the last six hours** (5% gone), and open a ticket for
slower burns.

## Two windows, and why

A long window alone pages late and keeps paging after the problem is fixed, because an hour of history
stays bad for an hour. So each threshold is checked over **two windows**, a long one and one twelve
times shorter, and pages only when both burn: the long one says the problem is big enough to matter,
the short one says it is still happening.

Two programs show it. The first publishes an hour of the shop's traffic, a thousand requests a minute,
with 50 errors a minute during 25 minutes, either ending now (`ongoing`) or ending twenty minutes ago
(`recovered`), each under its own `Service` dimension:

```python
# hour.py SCENARIO: an hour of the shop's traffic, as two metrics per minute
import datetime as dt
import sys

import boto3

scenario = sys.argv[1]                        # "ongoing" or "recovered"
bad = range(1, 26) if scenario == "ongoing" else range(21, 46)

now = dt.datetime.now(dt.timezone.utc).replace(second=0, microsecond=0)
data = []
for k in range(60, 0, -1):                    # k minutes ago
    errors = 50 if k in bad else 1
    for name, value in (("Requests", 1000), ("Errors", errors)):
        data.append({"MetricName": name, "Value": value, "Unit": "Count",
                     "Dimensions": [{"Name": "Service", "Value": scenario}],
                     "Timestamp": now - dt.timedelta(minutes=k)})

cw = boto3.client("cloudwatch")
for i in range(0, len(data), 20):
    cw.put_metric_data(Namespace="Shop", MetricData=data[i:i + 20])
print(f"{scenario}: {len(data)} data points published")
```

The second reads the last hour and the last five minutes back and computes both burn rates, paging only
when both are above 14.4:

```python
# burn.py SERVICE: how fast the error budget is burning, over two windows
import datetime as dt
import sys

import boto3

SLO = 0.999                       # 99.9% of requests succeed, over 30 days
BUDGET = 1 - SLO
PAGE_ABOVE = 14.4                 # 2% of a 30-day budget in one hour

cw = boto3.client("cloudwatch")
now = dt.datetime.now(dt.timezone.utc).replace(second=0, microsecond=0)


def total(name, minutes):
    points = cw.get_metric_statistics(
        Namespace="Shop", MetricName=name,
        Dimensions=[{"Name": "Service", "Value": sys.argv[1]}],
        StartTime=now - dt.timedelta(minutes=minutes), EndTime=now,
        Period=60, Statistics=["Sum"])["Datapoints"]
    return sum(p["Sum"] for p in points)


burning = []
for label, minutes in (("1 hour", 60), ("5 min", 5)):
    errors, requests = total("Errors", minutes), total("Requests", minutes)
    burn = errors / requests / BUDGET
    burning.append(burn > PAGE_ABOVE)
    print(f"{label:>6}: {int(errors):>5} errors in {int(requests):>6} requests, burn rate {burn:5.1f}")
print("page" if all(burning) else "no page")
```

```
ana@laptop:~/aws/slo$ python3 hour.py ongoing
ongoing: 120 data points published
ana@laptop:~/aws/slo$ python3 burn.py ongoing
1 hour:  1285 errors in  60000 requests, burn rate  21.4
 5 min:   250 errors in   5000 requests, burn rate  50.0
page
```

The hour burned at 21.4 and the last five minutes at 50: both above 14.4, so it pages, and it should.
The same hour of errors, ended twenty minutes earlier:

```
ana@laptop:~/aws/slo$ python3 hour.py recovered
recovered: 120 data points published
ana@laptop:~/aws/slo$ python3 burn.py recovered
1 hour:  1285 errors in  60000 requests, burn rate  21.4
 5 min:     5 errors in   5000 requests, burn rate   1.0
no page
```

The hour is identical, 1,285 errors and a burn of 21.4. The last five minutes burned at 1.0, the rate of
one error a minute the service always has. **No page**, because there is nothing left to do: the
incident is over, and the budget it spent is now a number for the review. A single one-hour window
would have paged here, twenty minutes after recovery.

The data is synthetic and the windows are computed by the program from moto's sums; CloudWatch would do
the same from the same metrics with metric math, which the next section shows, and which moto does not
evaluate.
