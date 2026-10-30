---
title: Burn rate: how fast the budget is going
version: 1
---

**Burn rate is the error rate divided by the error rate the objective allows.** At 99.5%, the allowed
rate is 0.5%. A burn rate of 1 spends the budget exactly over the period; 2 spends it in half the period;
100 spends a week's budget in about an hour and forty minutes. It is the number that says how urgent a
failure rate is, which the failure rate alone does not.

```kql
// burn.kql: how fast checkout spent its budget, hour by hour on Thursday afternoon
let objective = 99.5;
AppRequests
| where Name == "POST /checkout"
| where TimeGenerated between (datetime(2026-10-15 15:00) .. datetime(2026-10-15 20:00))
| summarize valid = count(), bad = countif(not(Success)) by hour = bin(TimeGenerated, 1h)
| extend error_rate = round(100.0 * bad / valid, 2)
| extend burn_rate = round(error_rate / (100.0 - objective), 1)
| order by hour asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < burn.kql
hour                  valid  bad  error_rate  burn_rate
2026-10-15T15:00:00Z  203    0    0.0         0.0
2026-10-15T16:00:00Z  229    0    0.0         0.0
2026-10-15T17:00:00Z  220    103  46.82       93.6
2026-10-15T18:00:00Z  207    3    1.45        2.9
2026-10-15T19:00:00Z  207    1    0.48        1.0
```

The hour from 17:00 UTC burned at **93.6**: at that rate the whole week's allowance goes in under two
hours. The hours either side burned at zero, and the hour after at 2.9, a few stragglers. A 1.45% error
rate does not sound alarming on its own; as a burn rate of 2.9 it says the budget would last a little over
two days at that pace, which is worth a ticket and not a page.

That is the use of burn rate: **it puts every failure rate on one scale**, whatever the objective, so that
the same alert logic works for a service at 99.9% and one at 99%. The thresholds in the next section are
burn rates for that reason.
