---
title: What a baseline is for
version: 1
---

**A score on its own says nothing.** "The model is 94% accurate" sounds like a result, and lesson
1 already showed that a model which never predicts a cancellation scores exactly that on this data.
A number becomes a result only beside the number something simpler would have got, on the same
rows, measured the same way. That simpler thing is the **baseline**, and it is built before the
model, not after.

The order matters. A baseline built after the model is built by somebody who already knows what it
has to lose to, and it is chosen, without anybody meaning to, to lose. Built first, it is a
question asked in good faith: **how far does the obvious get?**

## Three kinds of baseline, in rising order of effort

| baseline | what it is | what beating it proves |
|---|---|---|
| **a constant** | the same answer for every row: the commonest class, or the mean | that the model uses the features at all |
| **a rule of thumb** | one condition a person would write: *three skipped boxes, send the credit* | that the model finds something an expert's sentence does not |
| **the current practice** | whatever the company does today, even if it is a spreadsheet and a hunch | that changing anything is worth the trouble |

Feira em Casa has no current practice, because the credit is new. So the bar is the other two:
**the constant**, which here means *send nobody* and is worth exactly R$ 0, and **the best rule a
person could write** from the same columns the model reads.

## Why a baseline is a model like any other

A rule has to be chosen, and choosing it is learning. If Ana tries five rules and keeps the one
that did best on the months she later tests on, the rule has seen the test, and its score is
flattered in the same way an overfitted model's is. **So a baseline obeys every rule a model
obeys**: it is chosen on the months it may learn from and scored on months it never saw. This
lesson does exactly that, and the rule it chooses turns out to be worth nothing on the months it
did not see, which is the most useful thing a baseline can teach.

## What "beating it" has to mean

A model that scores a little above the rule on one test set may have been lucky with which
subscribers happened to fall in it. Section 07 of this lesson measures that luck by resampling,
using the inference `statistics` taught, and the answer decides whether the difference is a
finding or a coincidence.
