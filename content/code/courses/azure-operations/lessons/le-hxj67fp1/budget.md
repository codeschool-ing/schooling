---
title: The objective, and the budget it leaves
version: 1
---

**A service level objective is a target for an indicator over a period**: 99.5% of checkouts available,
measured over the week. The number is the shop's choice, and a good one is neither the best the service
has ever done nor a wish: it is the level below which customers start to notice and leave, which for a
shop is a business question asked with data.

**The error budget is what the objective allows to fail.** At 99.5% of 29,863 checkouts, the week allows
149 failed ones. That allowance is what makes the objective useful, because it turns an argument about
risk into arithmetic:

```kql
// budget.kql: the week's error budget for checkout availability, at an objective of 99.5%
let objective = 99.5;
AppRequests
| where Name == "POST /checkout"
| summarize valid = count(), bad = countif(not(Success))
| extend allowed = round(valid * (100.0 - objective) / 100, 0)
| extend spent_pct = round(100.0 * bad / allowed, 1), left = allowed - bad
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < budget.kql
valid  bad  allowed  spent_pct  left
29863  130  149.0    87.2       19.0
```

The week met its objective, 130 failures against 149 allowed, and **spent 87% of its budget**, almost all
of it in 42 minutes on Thursday afternoon. Nineteen failures are left.

What the shop does with that number is written down in advance, as an **error budget policy**, and agreed
between the people who ship and the people who are paged:

- budget healthy: release as usual, try things;
- budget mostly spent: releases go on, and each one waits for the canary of lesson 3 to finish clean;
- budget exhausted: only fixes and reliability work ship until the window rolls past the bad days.

The point of the policy is that nobody has to win an argument on the day. With 19 failures left, the next
release that breaks checkout for five minutes exhausts the week, and everybody knew that before it shipped.
