---
title: Imputing from similar rows
version: 1
---

**The better guess for a missing value is the value of rows like it.** That is the whole idea of
imputation beyond the centre: group by what you know, and take the group's median, or the value of
the nearest similar row, or a prediction from a model of the other columns.

It works exactly as well as the columns you group by predict the missing value. **For MAR blanks
that is the cure**: if the blanks depend on a visible column, filling within groups of that column
compares like with like. The previous section showed the limit too: filling birth years by signup
channel changed nothing, because channel does not predict age.

Three families, from simplest to most elaborate:

| method | fills a blank with | good when |
|---|---|---|
| group median | the median of rows sharing some columns | one or two columns explain most of the value |
| nearest neighbours | the values of the *k* most similar rows | several columns together explain it |
| model-based | a prediction from the other columns, once or several times | the relationship is strong and known |

The last one has a refinement worth knowing by name: **multiple imputation** fills each blank
several times with plausible values, runs the analysis on every completed copy and combines the
results, so the uncertainty of the guess ends up in the final error bars instead of disappearing.
It is the statistician's answer to the shrinking spread of the previous section. `statistics`
covers the inference it feeds; this course stops at knowing when it is worth the trouble.

## Where imputation stops

None of these methods fixes MNAR. A model of delivery times built from the recorded ones has never
seen a delivery over 119 minutes, so it predicts values below 120 for the very rows that are known
to be above it. **Imputation borrows from the rows you have, and MNAR means the rows you have are
the wrong ones to borrow from.** The delivery times need a different move, and it is the humblest
one in this lesson.
