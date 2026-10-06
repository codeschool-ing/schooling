---
title: One-sided and two-sided tests
version: 1
---

The alternative hypothesis can point in one direction or in both.

A **one-sided** test has an alternative such as μ < 40: only a difference in one direction counts. Horta's routing question is one-sided, because the claim is that deliveries got **faster**; slower deliveries would not support the supplier.

A **two-sided** test has an alternative such as μ ≠ 1000: a difference in either direction counts. The filling machine is two-sided, because a machine that overfills wastes rice and one that underfills breaks the law, and both mean it is off target.

## Why the choice matters

The significance level, usually 5%, is the share of results that will count as evidence against the null. A one-sided test puts all 5% in one tail. A two-sided test splits it, 2.5% in each tail, so each tail's threshold is further out.

For Horta's 25 deliveries, with 24 degrees of freedom, the thresholds are:

| test | reject the null when the statistic is |
|---|---|
| one-sided, μ < 40 | below −1.71 |
| two-sided, μ ≠ 40 | below −2.06 or above 2.06 |

A one-sided test is easier to pass in the direction it looks, and blind in the other.

## Choose before the data

The direction must be decided **before** seeing the data, from the question being asked. Choosing it afterwards — looking at the sample, seeing it went down, and then running a one-sided test for "down" — halves the threshold in your favour without any justification, and makes a 5% test into a 10% test in practice.

When in doubt, use **two-sided**. It is the default in most software and most reports, and it is the honest choice whenever a difference in the unexpected direction would also be worth knowing about. A new routing system that made deliveries slower is something Horta would very much want to hear, which is an argument for testing it two-sided too. This lesson keeps the one-sided version, because that is the claim the supplier made, and notes where the two differ.
