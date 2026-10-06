---
title: Reading a p-value
version: 1
---

The p-value connects directly to lesson 13's decision rule:

> **Reject the null hypothesis when the p-value is below α.**

That rule gives exactly the same decisions as comparing the test statistic with the critical value. For the routing test, p = 0.165 is above 0.05, so the null is not rejected; for the filling machine, p = 0.0009 is below 0.05, so it is rejected.

The p-value carries more than the decision, though. The critical value said only "beyond the line or not". The p-value says how far beyond, or how far short.

## A scale of surprise

Smaller p-values mean data that would be more surprising if the null were true:

| p-value | under the null, data this extreme happens |
|---|---|
| 0.165 | about one time in six |
| 0.05 | one time in twenty |
| 0.01 | one time in a hundred |
| 0.0009 | about one time in a thousand |

A useful habit is to read a p-value as that sentence rather than as a pass mark.

## There is no cliff at 0.05

A p-value of 0.049 and one of 0.051 are, for any practical purpose, the same evidence. For the routing test's 24 degrees of freedom, they correspond to t statistics of −1.722 and −1.700: a difference of 0.02 standard errors. One side of the line gets called "significant" and the other not, and that label makes them sound far more different than they are.

That is why a good report gives the **exact p-value**, not just "p < 0.05" or "not significant". A reader who sees p = 0.06 knows the data came close; a reader who sees "not significant" might think it came nowhere near.

## Very small p-values

A p-value is never exactly zero, and software that prints "p = 0.000" has rounded. Report it as "p < 0.001". And a tiny p-value is not a big effect: lesson 22 shows a difference of a fraction of a minute in delivery time producing a p-value smaller than anything in this lesson, because the sample was enormous.
