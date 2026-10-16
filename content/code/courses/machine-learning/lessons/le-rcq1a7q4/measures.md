---
title: Fair by which measure
version: 1
---

The table in `by_age.py` printed three numbers per band, and each is a different definition of fair, with
a name in the literature:

| definition | asks | the column in `by_age.py` |
|---|---|---|
| **demographic parity** | does every group get the benefit at the same rate? | `credited` |
| **equal opportunity** | does every group's *deserving* members get it at the same rate? | `recall` |
| **predictive parity** | is a credit equally likely to reach a leaver in every group? | `precision` |

There is a fourth worth knowing, **calibration within groups**: a chance of 0.3 means 30% in every group,
lesson 11's honesty checked band by band.

Each one sounds like the right definition when read alone, and they cannot all hold at once. The reason is
in the second column of the table: **the groups leave at different rates**, 5.2% in the 25-34 band, 7.4%
in the youngest. When base rates differ, a model that gives every group the same share of credits must
either reach a smaller share of the young leavers or waste more credits on the 25-34 band. A model that
reaches the same share of leavers everywhere must credit the young more often. Equal precision and equal
recall cannot both hold with unequal base rates, except for a perfect model. This is a theorem, proved
independently by several researchers around 2016, and no amount of tuning gets round it.

So **fairness is a choice of definition, and the choice is not technical.** For Feira em Casa's credit:

- **Equal opportunity** fits best. The credit is meant for people about to leave; the fair question is
  whether a young leaver and an old leaver have the same chance of being offered it.
- **Demographic parity** fits decisions where the benefit should go to every group in proportion whatever
  their rates, a scholarship scheme, say, and fits a retention credit badly: it would mean giving credits to
  stayers in one band to match the leavers in another.
- **Predictive parity** matters most where a positive prediction is a burden, a fraud flag or a security
  check, and the question is whether being flagged means the same thing for everyone.

The model with age had recalls of 0.267, 0.216, 0.234 and 0.240 in the four large bands. That is not
equal, and whether the gap is big enough to act on is a judgement about a number with noise in it. Lesson
2's bootstrap, run per band, would say how much.
