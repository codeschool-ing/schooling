---
title: The arithmetic, at four sizes
version: 1
---

**The cheapest commitment is found by pricing a few sizes against the real hours, not by a rule of
thumb.** With an **illustrative** pay-as-you-go rate of 0.25 USD per instance-hour and a 1-year
reservation rate of 0.16, a discount of 36%, the month costs:

```kql
// commit.kql: a month of the workers at three commitment sizes, with illustrative rates
let payg = 0.25;          // USD per instance-hour, pay as you go (illustrative)
let reserved = 0.16;      // USD per instance-hour under a 1-year reservation (illustrative)
WorkerHours
| extend k = 1
| join kind=inner (datatable(committed: int) [0, 2, 3, 4] | extend k = 1) on k
| extend covered = min_of(Instances, committed), uncovered = max_of(Instances - committed, 0)
| summarize used_reserved_hours = sum(covered), payg_hours = sum(uncovered), hours = count() by committed
| extend cost = round(committed * hours * reserved + payg_hours * payg, 2),
         unused_pct = round(100.0 * (committed * hours - used_reserved_hours) / max_of(committed * hours, 1), 1)
| project committed, cost, unused_pct
| order by committed asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < commit.kql
committed  cost   unused_pct
0          517.0  0.0
2          387.4  0.0
3          442.6  22.2
4          497.8  33.3
```

The query pairs every hour with four candidate sizes, using the constant-key join of lesson 14. For each
size, the committed instances are paid every hour whether they run or not, and anything above them is
paid at the pay-as-you-go rate. `unused_pct` is the share of committed hours that had nothing to cover.

**Committing to the floor, 2, is the cheapest month: 387.40 USD against 517.00, a quarter less**, and none
of the reservation is wasted. Committing to 3 costs more than committing to 2, even though more of the
month's usage is discounted, because the third reserved instance is idle in 480 hours. At 4 the bill is
almost back to pay as you go, with a third of the reservation unused.

The general shape holds whatever the real prices are: **savings grow as the commitment rises to the floor,
and fall after it**, faster the steeper the discount. A savings plan changes the arithmetic only in that
its commitment is in dollars per hour rather than instances, which is why it suits a mix of services that
moves between them. The shop's order is: reserve the floor of the steady VMs, cover the rest of the
steady compute spend with a savings plan, and leave the peaks on pay as you go, which is what pay as you
go is for.
