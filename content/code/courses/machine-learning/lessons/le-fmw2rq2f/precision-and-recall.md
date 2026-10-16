---
title: Precision and recall
version: 1
---

Two questions matter about the credits, and each is one ratio from the confusion matrix.

**Precision: of the credits sent, how many reached somebody who was leaving?** True positives over
everything the model called positive, 348 over 348 + 363. At the break-even cut it is **0.489**: just
under half the credits land on a leaver. Precision is the metric of the retention team's budget,
because every false positive is R$ 40 spent on nobody.

**Recall: of the people who were leaving, how many got a credit?** True positives over everybody who
was really positive, 348 over 348 + 1,136. At the same cut it is **0.235**: the model reaches a quarter
of the leavers. Recall is the metric of the people the business loses without a word, because every
false negative is somebody who left and was never asked. It is also called **sensitivity**, or the
**true positive rate**.

Neither includes the true negatives, which is why both mean something on a rare class.

## The trade between them

Read the precision and recall columns of `metrics.py` together:

| cut | precision | recall |
|---|---|---|
| 0.5 | 0.603 | 0.079 |
| 0.4 | 0.589 | 0.131 |
| 0.278 | 0.489 | 0.235 |
| 0.2 | 0.417 | 0.328 |
| 0.1 | 0.283 | 0.493 |

**As the cut falls, recall rises and precision falls.** A lower cut sends more credits, reaches more
leavers, and spends more of them on people who were staying. There is no cut that wins both, and any
report that quotes one of the two alone can be made to look good by choosing the cut: a recall of 0.9
is easy, at a cut low enough to send everybody a credit.

**So the two are always reported together, at a stated cut.** And the choice of cut is not a question
either metric can answer. Lesson 1's table gave each cell a price, and lesson 11 turns those prices into
a cut. Precision and recall say what happens at a cut; the business says which cut it can afford.
