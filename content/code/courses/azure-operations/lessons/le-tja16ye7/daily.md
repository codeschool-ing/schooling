---
title: The daily cost, and what the built-in detector made of it
version: 1
---

**The bill is a time series, one point a day, and a time series can be watched.** Load lesson 24's
`cost.kql` again if the emulator restarted, and look at October:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'CostDaily | where Date >= datetime(2026-10-01) | summarize cost = round(sum(Cost), 2) by Date | order by Date asc'
Date                  cost
2026-10-01T00:00:00Z  82.04
2026-10-02T00:00:00Z  82.89
2026-10-03T00:00:00Z  82.04
2026-10-04T00:00:00Z  83.47
2026-10-05T00:00:00Z  82.41
2026-10-06T00:00:00Z  82.47
2026-10-07T00:00:00Z  82.12
2026-10-08T00:00:00Z  82.96
2026-10-09T00:00:00Z  91.73
2026-10-10T00:00:00Z  91.25
2026-10-11T00:00:00Z  91.16
2026-10-12T00:00:00Z  90.57
2026-10-13T00:00:00Z  91.1
2026-10-14T00:00:00Z  91.51
2026-10-15T00:00:00Z  90.34
2026-10-16T00:00:00Z  91.33
2026-10-17T00:00:00Z  91.09
2026-10-18T00:00:00Z  91.21
```

A reader sees it at once: about 82 USD a day until the 8th, and about 91 from the 9th, every day since. A
step, not a spike: something changed on the 9th and has cost nine dollars a day more ever since.

KQL has a function built for this kind of question, `series_decompose_anomalies()`, which breaks a series
into a baseline, a seasonal part and a residual, and flags the days whose residual is unusual. Run over the
sixty days:

```kql
// anomalies.kql: the daily total as a series, and the days the engine calls anomalous
CostDaily
| make-series cost = sum(Cost) default = 0 on Date from datetime(2026-08-20) to datetime(2026-10-19) step 1d
| extend (flag, score, expected) = series_decompose_anomalies(cost, 2.5)
| mv-expand Date to typeof(datetime), cost to typeof(real), flag to typeof(int), score to typeof(real), expected to typeof(real)
| where flag != 0
| project Date, cost = round(cost, 2), expected = round(expected, 2), score = round(score, 1)
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < anomalies.kql
Date  cost  expected  score
```

**It flagged nothing.** That is a real result, worth more than a tidy one. `make-series` built the daily
series, the function scored every day, and none passed the threshold of 2.5; the scores for the 9th and
after stayed below 0.2 when the course looked at them. The function judges each day against the series'
own decomposition, and here the higher level was absorbed into it rather than singled out. A detector is
only as good as the shape of change it is built to see, and the shape here is a sustained step.

Cost Management offers **anomaly alerts** on a subscription, which run Microsoft's own model over the daily
cost and e-mail when it finds something; they were not run here, and they deserve the same test before
you rely on them: does it flag the change you care about, in your data?
