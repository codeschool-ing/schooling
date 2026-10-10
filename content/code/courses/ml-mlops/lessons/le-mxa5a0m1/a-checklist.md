---
title: A checklist before anybody reports a score
version: 1
---

Every leak in this lesson produced a score that looked better than the truth, and none produced an
error. So the defence is a set of questions asked about every training set before its score is
believed. **They are data questions, and the person who built the data is the one who can answer
them.**

| ask | the leak it catches | where it showed here |
| --- | --- | --- |
| Could each feature's value have been computed on the cutoff date, from data that existed then? | a column from today's table | `leak.py`: a negative recency, AUC 0.994 |
| Does any entity appear on both sides of the split, and should it? | the same member twice | `splits.py`: 0.766 against 0.750 |
| Is the test set later than the training set, by at least the label window? | training on a future the model will not have | the 90-day gap before 30 November |
| Has every label's window closed? | unfinished labels | `maturity.py`: 17% becomes 65.5% |
| Was anything fitted before the split? | preprocessing that saw the test rows | the pipeline in `classify.py` |
| Was the test set used to choose anything? | a test set that became a validation set | `overfit.py` opens it once |

**And one question that catches the rest: is the score too good?** An AUC of 0.994 on predicting
human behaviour 90 days ahead is not a triumph, it is a symptom. When a model suddenly gets much
better, the first suspect is the data, not the algorithm.

Lesson 5 turns several of these into checks a pipeline runs every time, and lesson 6 builds the
point-in-time join that makes the first row of this table true by construction.
