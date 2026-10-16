---
title: Three ways the world moves
version: 1
---

Lessons 3 and 4 said a model is tested on later months because the world changes. This lesson has now
seen it change in three distinct ways, and they have names, because each is noticed differently and
answered differently.

| | what changes | here | seen by | when |
|---|---|---|---|---|
| **data drift** | the inputs: who the subscribers are | the monthly plan; higher prices | `inputs.py` | on the day |
| **concept drift** | what the inputs mean: the same subscriber's chance of leaving | the competitor in two cities | `where.py` | a month later, if the error is broken down |
| **label shift** | how common the outcome is overall | the price rise's after-effect ending | `labels.py` | a month later |

Two of the three cannot be seen until the labels arrive, and that is the uncomfortable centre of this
lesson. **A deployed model is always being judged on last month**, and the most damaging change, the
one where the world reacts differently to the same facts, is invisible on the day. What the day can
offer is a stand-in for the label: the **mean chance**, compared with the recent actual rate. If the
model says 6.5% in a month after three months of 5%, that does not prove anything, but it is the
earliest sign there is.

Two more points the names hide.

**Drift is not always a problem.** `price_month` drifted hugely and the ranking survived it: the model
had learned the effect of price, and higher prices moved chances in the direction it had learned. Data
drift matters when it takes the model **somewhere it has not been**, the monthly plan, and much less when
it moves along a road it already knows.

**The answer is not always to refit.** The price rise was temporary: a model refitted in December would
have learned September's panic and carried it into a calm January, which is roughly what happened to
`churn-2025-12`. A competitor is not temporary. Telling the two apart is a question about the business,
and the people who can answer it are usually not looking at the model.
