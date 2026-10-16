---
title: Three sets, and what each one is for
version: 1
---

`overfit.py` used three cutoffs for three jobs, and **the jobs are the point, not the names.**

| set | in overfit.py | what it is for | how often it is looked at |
| --- | --- | --- | --- |
| **training** | 31 August 2025 | the rows `fit` reads | every time a model is fitted |
| **validation** | 30 September 2025 | choosing between models: which depth, which features, which algorithm | as often as you like |
| **test** | 30 November 2025 | one honest estimate of the chosen model | **once**, at the end |

**Validation exists because choosing is a kind of learning.** Six depths were tried and the one
with the best validation score was kept. That choice used the validation rows, so their score for
the winner, 0.762, is a little flattering: with enough tries, one of them does well partly by luck.
The test rows played no part in any choice, so 0.769 is the number to report.

**A test set looked at twice is a validation set.** If the test score had disappointed and somebody
had tried depth 6 instead and checked again, the test rows would now be part of the choosing, and
there would be no honest number left. In a platform this is a process rule as much as a technical
one: the test rows are kept where training jobs do not read them, and the score on them is
computed by the release step, not by whoever is tuning.

## How big each one should be

There is no rule worth memorising. Two things decide it in practice. The **test set has to be
large enough that its score is not luck**: 3,130 members, 530 of them lapsed, is enough to tell
0.76 from 0.79; fifty members would not be. And for data that moves with time, like this, the
sets are **not chosen by size at all but by date**, which is section 07.

**Cross-validation** is the name for repeating the split several times on different slices and
averaging, common when rows are few. It answers the same question with less noise, and it has the
same weakness that section 06 shows for any split that ignores who and when.
