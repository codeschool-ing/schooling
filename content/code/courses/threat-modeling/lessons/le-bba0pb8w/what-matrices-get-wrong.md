---
title: What matrices get wrong
version: 1
---

In 2008 the risk analyst Louis Anthony Cox published a paper with an unambiguous title, *What's
wrong with risk matrices?*, and showed mathematically what the previous section showed with nine
risks. Four of his findings explain every oddity in Vereda's table.

| problem | what it means | at Vereda |
|---|---|---|
| **range compression** | very different values fall into the same band | R$ 60,000 and R$ 200,000 are both impact 4; one event a year and three are both likelihood 4 |
| **ties** | different risks get the same score and look equal | T14, T08 and T11 all score 4, with expected losses from R$ 2,400 to R$ 9,000 |
| **reversal** | a lower risk gets a higher score than a larger one | T01 scores 9 at R$ 6,000 a year; T13 scores 5 at R$ 15,000 |
| **ordinal arithmetic** | band positions are multiplied as if they were quantities | "3 × 3 = 9 > 1 × 5 = 5" treats the step from band 1 to band 2 like the step from band 4 to band 5, though the bands cover very different amounts |

Cox's conclusion was that a matrix can rank risks **worse than random** in some cases, which sounds
extreme and is shown by reversals like T01's: a ranking that puts the cheaper risk above the dearer
one is worse than a coin flip for that pair.

### Why matrices are everywhere anyway

They are quick, they look like analysis, and they need no estimates anybody has to defend. Those are
also the reasons they fail: **a matrix lets a team skip the step where the numbers are argued
about**, and the argument is where most of the value of a risk analysis is. Two people who agree that
a risk is "likely" can mean once a year and once a month, and the matrix will never show it.

### When a matrix is good enough

There are honest uses:

- **Screening.** Sorting fifty threats into "look at these first" and "later" in an hour, before any
  numbers exist. A coarse sort is what a matrix does well.
- **When a framework requires one.** Some standards and auditors ask for a matrix. Produce it from
  the quantitative estimates, so the bands are filled from numbers rather than from adjectives, and
  keep the numbers beside it.
- **When the numbers would be pure invention.** For a system with no history and no reference class,
  a team may honestly be unable to give a range. A matrix at least does not pretend to precision.

### What to do instead, by default

For the few risks that matter most, do what lessons 9 and 10 did: estimate frequency and loss as
ranges, simulate, and show the curve. For the rest, a matrix filled from those same estimates is
fine, as long as nobody reads its ties and its reversals as findings. Vereda keeps both: the matrix
on the slide daniel's board sees each quarter, built by `matrix.py` from `risks.csv`, and the curve
on the page after it.
