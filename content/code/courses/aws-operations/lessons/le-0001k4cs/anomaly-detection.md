---
title: Cost Anomaly Detection, and what to page on
version: 1
---

AWS runs the same idea as `spike.py` as a service: **Cost Anomaly Detection**, part of Billing and Cost
Management, free to use. A **monitor** says what to watch: every AWS service separately, the most common
choice; or one account, a cost category of lesson 24, or a cost allocation tag. A **subscription** says who
hears about it, by e-mail or SNS, immediately, daily or weekly, and above what impact, in dollars or as a
percentage of the expected spend. Instead of a median, it learns each monitor's pattern, weekdays and
weekends included, and reports the root cause it can see: the service, the account, the region and the
usage type that moved.

```
ana@laptop:~/aws/bill$ aws ce create-anomaly-monitor --anomaly-monitor '{"MonitorName":"services","MonitorType":"DIMENSIONAL","MonitorDimension":"SERVICE"}' 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the CreateAnomalyMonitor operation (reached max retries: 2): <!doctype html>
```

moto has no anomaly detection, so this is AWS's documented behaviour, not run here. Created on the shop's
account, a service monitor with an immediate subscription above 20 USD of impact would have reported
CloudWatch on 9 October, with `SAE1-DataProcessing-Bytes` as the usage type that moved, the line lesson 9
priced.

## What to page on

Cost is slow compared with errors, and paging on every movement is lesson 14's fatigue again. A set that
works for a team the size of the shop's:

| signal | threshold | route |
|---|---|---|
| anomaly, one service | above 20 USD a day of impact | ticket, read the same day |
| anomaly, any | above 100 USD a day, or a new service nobody uses | page |
| budget, forecast | above 100% of the month | ticket |
| budget, actual | above 100% before the 20th | page |
| `EstimatedCharges` rate | three times the usual pace | page |

Two of the pages are there for a reason. **A service nobody uses appearing on the bill** is the signature of a stolen
credential, instances in a region the team never uses: lesson 19's GuardDuty finding, seen from the other
side. A bill growing three times faster than usual is a loop, a leak or an attack, whichever lesson it
belongs to. In both cases the bill
noticed first, and it should not be the last to.
