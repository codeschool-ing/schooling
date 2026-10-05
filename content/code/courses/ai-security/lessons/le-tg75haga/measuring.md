---
title: Measuring a shortlist group by group
version: 1
---

Sixteen profiles show the mechanism and are too few to measure anything. The measurement is made on
the shortlist's real output over many decisions, together with a label saying which decisions were
right. In the lab, `data/shortlist-v1.csv` is that table: 312 applicants, the region of each,
whether a reviewer later judged them able to do the job (`good`), and whether the shortlist chose
them. **The counts were written by the course**, from a table in `guardlab/fairness.py`, so that the
metrics have something to disagree about.

```
ana@lab:~/guard$ head -3 data/shortlist-v1.csv
applicant,region,good,shortlisted
fr-0001,Sudeste,1,1
fr-0002,Sudeste,1,1
ana@lab:~/guard$ guard fairness data/shortlist-v1.csv --group region
region        n   base  selected    TPR    FPR  precision
Sudeste     200   0.60      0.56   0.80   0.20       0.86
Nordeste    100   0.50      0.35   0.60   0.10       0.86
Norte        12  too few to measure (fewer than 30)
reference: Sudeste
Nordeste against Sudeste
  selection ratio   0.62   below the four-fifths line (0.80)
  TPR gap           -0.20
  FPR gap           -0.10
  precision gap     +0.00
```

## Five rates, and the question each one answers

Every column is a rate inside one group, and each answers a different question:

| column | of whom | the question it answers |
|---|---|---|
| `base` | everybody in the group | how many were good: the base rate |
| `selected` | everybody in the group | how many the shortlist chose |
| `TPR` | the good ones | of those who could do the job, how many were shortlisted |
| `FPR` | the ones who were not good | of those who could not, how many were shortlisted anyway |
| `precision` | the shortlisted | of those the client saw, how many could do the job |

Read the Nordeste row against the Sudeste row with those questions in mind.

**Selection.** 35% of Northeastern applicants are shortlisted against 56% of Southeastern ones, and
the ratio between the two is 0.62. The *four-fifths rule* flags a ratio below 0.80 as adverse impact.
It comes from guidelines that US employment regulators published in 1978, and it is no law in
Brazil. Even where it applies it is a rule of thumb. It is still the most widely used first screen,
and 0.62 is well below it. Requiring the selection rates to be equal is called **demographic
parity**.

**TPR.** Of the Northeastern freelancers who could do the job, 60% were shortlisted; of the
Southeastern ones, 80%. The gap of −0.20 is the stand-in's CEP bonus showing up in aggregate: a good
freelancer in the Northeast is passed over twice as often, 40% against 20%. Requiring this gap to be
zero is called **equal opportunity**.

**Precision.** 0.86 in both. Of the people a client sees, the same share can do the job wherever they
live. Requiring this is called **predictive parity**, and by it the shortlist is fair.

That last line is what makes this hard. **A client looking at precision sees a fair shortlist; a
freelancer looking at TPR sees an unfair one.** Both are reading the same table correctly. Which
metric a report leads with decides what the report concludes, and that choice is usually made
without anybody noticing it was a choice.

## The group the table refuses to measure

The North has 12 applicants, and the tool prints no rates for it. With 6 good applicants, one more or
one fewer shortlisted moves the TPR by 0.17, so any gap it showed would be mostly chance. The cut-off
of 30 is the same one this platform's own item analysis uses before it judges a question.

Refusing is better than printing a number nobody should read, and it is still a finding: **the
group that is measured worst is usually the group with the most to lose from a bad model**, which is
the representation row of the previous section. The remedy is to collect more decisions before
concluding anything about the North, and not to drop the region from the report because its row is
empty.
