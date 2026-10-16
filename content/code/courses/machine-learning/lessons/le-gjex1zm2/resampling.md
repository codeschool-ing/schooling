---
title: Oversampling and undersampling
version: 1
---

Resampling changes the training rows themselves until the classes are balanced. There are two
directions, and the last two rows of `rebalance.py` tried both:

- **Oversampling** copies leavers, drawn at random with replacement, until there are as many as
  stayers. Here that means 36,427 leaver rows made from 2,201 real ones, each repeated about sixteen
  times, and a training set nearly twice as large.
- **Undersampling** throws stayers away, at random, until there are as few as leavers. Here that
  keeps 2,201 of 36,427, one in sixteen, and the training set shrinks to 4,402 rows.

Back to the table. **Neither improved the ranking.** Oversampling lost a little, AUC 0.788 against
0.804, partly because a tree that sees the same leaver sixteen times learns that particular leaver's
details as if they were a pattern. Undersampling lost more on average precision, 0.285 against
0.322: it threw away 34,226 stayers, and with them most of what the model knew about who stays. Both
raised the average chance far above the truth, and both lost money at the default cut.

There is one honest argument for undersampling, and it is not about the class. **It makes training
cheap.** A file with a hundred million rows and one positive in a thousand trains on a fraction of
the time with the negatives thinned out. When the data is too big to fit, undersampling is a
reasonable way to fit it, as long as the chances are corrected afterwards, which a later section of
this lesson does.

### SMOTE, and other ways to invent leavers

Plain oversampling copies rows. **SMOTE** (Synthetic Minority Oversampling Technique) invents new ones
instead: it picks a leaver, picks one of its nearest leaver neighbours, and makes a row somewhere on
the line between the two. The idea is to fill in the space around the rare class rather than stack
copies on the same points. It lives in a separate library, `imbalanced-learn`, which this course does
not install.

It has the same limit as everything in this section, and two more. It adds no information: every
invented row is a blend of rows the model already had. It needs a distance between rows, which is
awkward with categorical columns such as `city` and `plan`. And the invented rows may not be possible
at all, a subscriber with 2.6 complaints and a payment method halfway between card and boleto. On
data like this, measure it against doing nothing and choosing the cut, as this lesson does, before
trusting it.

All three kinds of resampling share one more trap, which has nothing to do with whether they help and
everything to do with how they are measured. It is the next section.
