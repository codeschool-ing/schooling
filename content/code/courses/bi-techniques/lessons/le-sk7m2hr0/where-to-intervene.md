---
title: Where a fix can go
version: 1
---

A model sits in a chain: data is collected, inputs are built from it, a model is fitted, a threshold
turns scores into flags, and a decision acts on the flags. **A fix can go at any link**, and each has a
different price.

| link | what a fix there looks like | at Panela |
|---|---|---|
| **data** | collect what is missing, or more of a scarce group | more history from the North, which only time provides |
| **inputs** | build inputs that mean the same thing for every group | measure recency against the customer's own rhythm |
| **model** | reweight the scarce group, or fit with a fairness constraint | weight the North's customers more in training |
| **threshold** | a different threshold per group | a higher threshold for the North |
| **decision** | change what the flag does | let the club use order history, not a churn score |
| **use** | do not use the model for this decision | keep the churn score for offers only |

The order of the table is a rough order of preference, and the reasoning behind it is simple. **A fix
near the cause repairs the model for every decision it serves**; a fix near the end repairs one
decision and leaves the cause in place for the next person who reuses the model. When lesson 18 found
that the cause was a measurement, the inputs became the first place to look.

That preference is not a rule. Sometimes the cause cannot be reached: the data a group needs does not
exist, or will take a year to collect. Then a correction further down the chain, applied openly and
documented, is better than waiting. And sometimes the honest answer is in the last row: the decision
should not rest on this model at all.

Every fix has to be checked the same way the problem was found, **by running the audit again**. A fix
that was not audited is a hope.
