---
title: The burn rate
version: 1
---

An alert on the SLI needs a threshold, and the obvious one is wrong. *Page when availability falls
below 99.5%* fires on any five minutes in which more than one checkout in two hundred fails, which at
night may be one failure out of fifty requests, and says nothing about whether the month is in
danger.

The useful question is **how fast the budget is being spent**. That is the **burn rate**: the error
ratio divided by the error ratio the objective allows.

> burn rate = (1 − SLI) / (1 − SLO)

With an objective of 99.5%, the allowed error ratio is 0.5%. A burn rate of 1 means checkouts fail at
exactly 0.5%, which spends the budget in exactly one window, 28 days. A burn rate of 2 spends it in
14 days; a burn rate of 28 spends it in one day.

| burn rate | budget lasts | in one hour, spends |
|---|---|---|
| 1 | 28 days | 0.15% |
| 3 | 9.3 days | 0.45% |
| 14.4 | 1.9 days | 2.1% |
| 200 | 3.4 hours | 30% |

**The burn rate turns *how bad* into *how urgent*.** A rate of 14.4 sustained for an hour costs 2% of
the month's budget, which is worth waking somebody for, because left alone it empties the budget in
under two days. A rate of 3 is a problem for tomorrow: it would take nine days, and a ticket is enough.
Those two numbers, 14.4 and 3, are not laws; they are the pair the Google SRE workbook proposes, and a
team can derive its own from how much budget it is willing to lose before somebody acts.

The burn rate is also blind in a useful way: it does not care about traffic. Fifty failures in an
hour of five thousand checkouts and one failure in an hour of a hundred are both a 1% error ratio,
a burn rate of 2, and the same share of the month's promise. What it cannot handle is **no traffic**:
a ratio of nothing over nothing is undefined, which is exactly when lesson 14's synthetic checkout
earns its place. At three in the morning, with nobody buying, a failing probe is the only signal there
is, and it is worth a page of its own if the shop sells at that hour.
