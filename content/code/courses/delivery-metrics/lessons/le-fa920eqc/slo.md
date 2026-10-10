---
title: The objective, and why it is not 100%
version: 1
---

A **service level objective**, or SLO, is the target for an SLI over a window of time:

```localised
99.9% of charge attempts are good, over any 30 days
```

Both halves matter. The number says how good is good enough, and the window says over how long the team is judged. A **rolling** window of 30 days moves forward a day at a time, so a bad afternoon counts for exactly 30 days and then leaves; a calendar month resets on the 1st, which makes the last day of the month either a free pass or a disaster depending on what happened earlier.

## What each nine buys

It helps to turn a percentage into time, as if every request failed for a continuous stretch:

| objective | bad allowed in 30 days | as continuous downtime |
|---|---|---|
| 99% | 1 in 100 | 7 hours 12 minutes |
| 99.5% | 1 in 200 | 3 hours 36 minutes |
| 99.9% | 1 in 1,000 | 43 minutes |
| 99.99% | 1 in 10,000 | 4 minutes 19 seconds |

Each extra nine is ten times stricter, and it costs far more than ten times as much: 43 minutes a month is time enough for a person to be paged, open a laptop and roll back a release; four minutes is not, so a 99.99% service needs the rollback to happen without anybody.

## Why not 100%

**100% is the wrong objective for nearly everything**, for three reasons that each stand alone.

- **The user cannot see it.** A shop's terminal sits on a shop's Wi-Fi and a mobile network that fail more often than 1 in 1,000. Past a point, the team's improvements disappear into somebody else's outages.
- **It forbids change.** Every release carries some risk. An objective of 100% says no risk is acceptable, which, followed honestly, means never releasing, and followed dishonestly means releasing anyway and hiding the results.
- **It cannot be met, so it stops meaning anything.** The first bad charge breaks it, and an objective that is always broken is ignored from the second month.

## Choosing the number

The best starting point is **what users have been getting without complaining**. If the SLI has been around 99.95% for months and the shops are content, an objective of 99.9% leaves room for the team to take risks and still keeps the shops where they are; an objective of 99.99% promises something nobody has asked for, and pays for it with every release.

The number is a **product decision**, not an engineering one. It says how much unreliability the business accepts in exchange for change, and the people who own the product sign it beside the team that runs it.

## SLO and SLA

An **SLA**, a service level agreement, is a contract with a customer, with a penalty when it is broken: a refund, a credit. An SLO is internal. Teams keep the SLO stricter than any SLA, so that the alarm rings while there is still time to act before the contract is broken. The Billing team's shops have an SLA of 99.5% on card charges; the team's objective is 99.9%.
