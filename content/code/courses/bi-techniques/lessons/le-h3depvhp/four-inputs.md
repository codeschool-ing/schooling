---
title: Four numbers decide the size
version: 1
---

A test is a bet against chance: with few visitors, the two groups differ by luck alone, and a real
effect smaller than that luck cannot be seen. **The sample size is the number of visitors at which
the effect you care about stands out from the luck**, and it is set by four numbers, all chosen
before the test.

| input | Panela's value | what it means | if you make it smaller |
|---|---|---|---|
| **baseline rate** | 4.2% | how many visitors convert today | rates near 0 or 100% need more visitors for the same lift |
| **minimum detectable effect**, MDE | +0.6 points | the smallest lift worth finding, from lesson 7's hypothesis | many more visitors: the next section quantifies it |
| **significance level**, α | 5%, two-sided | the chance of a false alarm when nothing changed | more visitors |
| **power**, 1 − β | 80% | the chance of detecting the effect if it is really there | fewer visitors, and more real effects missed |

Two of these come from `statistics` lesson 15. **α is the type I error rate**: declaring a winner
that is not one. **β is the type II error rate**: missing a winner that is one, and power is its
complement. The conventions, 5 per cent and 80 per cent, mean a test is set up to accept four
times more risk of missing an effect than of inventing one, which reflects that shipping a change
that does nothing usually costs more than not shipping one that helps.

**The baseline comes from data, not from hope.** Panela's 4.2 per cent is the conversion the plan
expects in the control group. If the real rate turns out different, the test's power changes with
it, which lesson 10 checks.

**The MDE comes from the business, not from statistics.** It is the smallest effect that would pay
for the change. A common mistake is to set it from what the team expects to see; a test sized for
an optimistic expectation is too small to detect a realistic one.
