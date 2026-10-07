---
title: Fixing one gap opens another
version: 2
---

The obvious repair for a selection ratio of 0.62 is to shortlist more Northeastern applicants until
the rates match. `data/shortlist-v2.csv` is what Tarefa's shortlist looks like after that change: a
lower threshold for the Northeast, chosen so that the same share of each region is shortlisted. As
before, the counts were written by the course, and `shortlist.py` writes the table.

```
ana@lab:~/guard$ guard shortlist v2 > data/shortlist-v2.csv
ana@lab:~/guard$ guard fairness data/shortlist-v2.csv --group region
region        n   base  selected    TPR    FPR  precision
Sudeste     200   0.60      0.56   0.80   0.20       0.86
Nordeste    100   0.50      0.56   0.80   0.32       0.71
Norte        12  too few to measure (fewer than 30)
reference: Sudeste
Nordeste against Sudeste
  selection ratio   1.00
  TPR gap           +0.00
  FPR gap           +0.12
  precision gap     -0.14
```

The selection ratio is 1.00 and the TPR gap is zero: a good freelancer is shortlisted 80% of the time
in either region. Two other numbers moved the wrong way. The FPR gap went from −0.10 to +0.12, and
precision in the Northeast fell from 0.86 to 0.71. **A client now sees a Northeastern shortlist in
which more than one candidate in four cannot do the job**, against about one in seven from the
Southeast. Clients will notice that, and the freelancers it hurts are the Northeastern ones, whose
shortlist starts to look unreliable.

## Why it cannot all be equal

The cause is in the `base` column, which no change to the shortlist can move: 60% of Southeastern
applicants are good and 50% of Northeastern ones. Alexandra Chouldechova proved in 2017 that when
base rates differ, **no classifier that makes mistakes can have equal precision, equal TPR and equal
FPR across the groups at the same time**, and Jon Kleinberg, Sendhil Mullainathan and Manish Raghavan
proved a close relative of it for risk scores in 2016. Equalise two and the third
gives way. Version 1 kept precision equal and paid in TPR; version 2 bought TPR and paid in precision
and FPR. Neither is a bug in the shortlist. It is arithmetic.

That arithmetic assumes the base rates are true. Here they come from a reviewer's judgement, which is
the measurement row of the first section: if reviewers rate Northeastern work more harshly, the 0.50
is itself part of the bias, and equalising against it locks the bias in.

## Choosing is the work

So the question a team has to answer is not which shortlist is fair, but **which error it is less
willing to have fall unevenly**. Name the two errors in the terms of the people who suffer them:

- a **false negative** is a good freelancer who is never shown, and loses the job and the income;
- a **false positive** is a client who is shown somebody who cannot do the job, and loses time.

For a feature that decides who gets work, many teams decide that the freelancer's error is the
graver one and hold the TPR gap close to zero, accepting a precision gap and telling clients so.
Another team may decide otherwise. What makes either defensible is that the choice is **written down
with its numbers**, in the same document lesson 12 called the RIPD: the metric chosen, the reason,
the gaps measured, the date, and when they will be measured again. That is also what a review
request under art. 20 of the LGPD will ask to see.

## The repair that the measurement points at

Both versions treat the symptom by moving thresholds. The measurement in this lesson came from a
scorer with a bonus for Southeastern postcodes, and the cause is that bonus. Whether a postcode has
any business in the score depends on the job. For a remote logo design it has none, and the right fix
is to stop the scorer reading it. For a job that needs somebody on site, distance to the client is a
real requirement, and the honest feature is the distance itself, not *"is in the Southeast"*. The
next section is the test that finds a cause like that one decision at a time.
