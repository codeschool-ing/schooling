---
title: A rule you can read: today against the usual
version: 1
---

**The shop's daily check compares each day with the median of the fourteen days before it**, and flags a
day more than 5% above. The median rather than the average, so that one strange day does not move the
baseline. Fourteen days, so that a weekly pattern is inside the window. And 5%, because the shop's daily noise
is a fraction of that, which the first eight days of October show.

```kql
// usual.kql: each day against the median of the fourteen days before it
let daily = CostDaily | summarize cost = sum(Cost) by Date;
daily
| extend k = 1
| join kind=inner (daily | project before = Date, earlier = cost | extend k = 1) on k
| where before between ((Date - 14d) .. (Date - 1d))
| summarize cost = take_any(cost), usual = percentile(earlier, 50) by Date
| extend ratio = round(cost / usual, 3)
| where Date >= datetime(2026-10-05)
| project Date, cost = round(cost, 2), usual = round(usual, 2), ratio, flag = ratio > 1.05
| order by Date asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < usual.kql
Date                  cost   usual  ratio  flag
2026-10-05T00:00:00Z  82.41  82.04  1.005  False
2026-10-06T00:00:00Z  82.47  82.07  1.005  False
2026-10-07T00:00:00Z  82.12  82.38  0.997  False
2026-10-08T00:00:00Z  82.96  82.38  1.007  False
2026-10-09T00:00:00Z  91.73  82.38  1.113  True
2026-10-10T00:00:00Z  91.25  82.41  1.107  True
2026-10-11T00:00:00Z  91.16  82.47  1.105  True
2026-10-12T00:00:00Z  90.57  82.47  1.098  True
2026-10-13T00:00:00Z  91.1   82.82  1.1    True
2026-10-14T00:00:00Z  91.51  82.89  1.104  True
2026-10-15T00:00:00Z  90.34  82.96  1.089  True
2026-10-16T00:00:00Z  91.33  83.47  1.094  True
2026-10-17T00:00:00Z  91.09  90.34  1.008  False
2026-10-18T00:00:00Z  91.21  90.57  1.007  False
```

The join pairs every day with every other, and `where` keeps the fourteen before it, the constant-key
pattern of lessons 14 and 22. **The rule flags the 9th, the first day of the step**, and every day after it
for a week, at about 10% above the usual.

And then, on the 17th, it stops. Not because anything was fixed: because by then the fourteen-day median
has eight of the expensive days in it, and **the new level has become the usual.** That is the most
important line in this lesson's output. An alert on a change in cost has a window in which it means
something, and the window is about as long as its baseline. A team that lets the flag sit for a week has
accepted the new cost without deciding to.

So the shop's check runs every morning, as a log search alert of lesson 12's kind over the cost export in
the workspace, and its notification goes to the team that owns the meter that moved, which is the last
section's question.
