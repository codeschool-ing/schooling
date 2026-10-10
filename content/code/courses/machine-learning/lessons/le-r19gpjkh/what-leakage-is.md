---
title: What leakage is
version: 1
---

**Leakage is information in the training data that will not exist at the moment the model is
used.** The model learns from it, as it learns from everything, and the validation score rewards it
for doing so, because the validation rows carry the same information. Then the model is used, the
information is not there, and the score was a description of a world that does not exist.

The common picture is a careless mistake: somebody left the answer in the table. That happens, and
it is the easy case, because the score is so good that everybody gets suspicious. **The leaks that
cost money are the ones that make a model slightly better**: a few points on a score nobody
expected to be perfect, through a column that has a sensible name and a sensible reason to be there.

There are four ways in, and this lesson has an example of each:

| the way in | what carries it | where it is in this course |
|---|---|---|
| **the target, in disguise** | a column written because of the outcome | `cancel_reason`, section 03 |
| **the future** | a column computed later than the moment of prediction | `days_since_last_order`, section 04 |
| **the preparation** | a step fitted on every row before the split | choosing columns, section 05 |
| **the split** | relatives or later rows on both sides | lesson 3, recalled in section 06 |

All four have the same test, and it is lesson 1's second framing question asked of every column
and every step: **on the first of the month, before the credit goes out, would this be known, and
would it have this value?**

## Why validation does not catch it

Validation protects against a model memorising its training rows. It cannot protect against
information that both sides share, because a leak is not a difference between training and
validation; it is a difference between **the data and the world**. Both halves of a split come from
the same export, written by the same systems on the same day, and a column that knows the future
knows it on both sides. That is why the only reliable defence is to ask where each column comes
from, which is section 08, and why two columns of `churn.csv` were left out of `feira.py`'s lists in
lesson 2.
