---
title: Reading the residual
version: 1
---

**The residual is the decomposition's own report on what it failed to explain**, and it is the
part people skip. Lesson 1 said that noise with a pattern is not noise. The four largest residuals
from the last section are a pattern:

| week ending | residual | what happened |
|---|---|---|
| 16 Feb 2025 | 1.082 | no Carnival; in 2024 Carnival's Monday and Tuesday fell in this week of the year |
| 10 Mar 2024 | 1.078 | no Carnival; in 2025 it fell in this week of the year |
| 18 Feb 2024 | 0.930 | Carnival's Monday and Tuesday |
| 26 Nov 2023 | 1.067 | Black Friday, which in 2024 fell a week of the year later |

Three of them are **Carnival**, which fell on 21 February 2023, 13 February 2024 and 4 March
2025. A seasonal index is an average over the same week in different years. Carnival sat in a
February week in 2024 and in a March week in 2025, so the averaging put **half a Carnival in each
of those weeks**. The week that had Carnival came out lower than the half-Carnival index expected,
and the weeks that did not came out higher. A residual of 0.930 is a week seven per cent below what
trend and season predicted; 1.082 is eight per cent above.

The fourth is **Black Friday**. Its date follows a rule, the Friday after the fourth Thursday of
November, and the rule puts it in a different week of the year from one year to the next. The
index half-expected it in two weeks, and got it whole in one of them.

That is the general lesson: **a holiday that moves cannot be learnt from a fixed period**. A
decomposition smears it over every position it has ever occupied, and leaves behind a pair of
residuals, one high and one low, where the truth was one dip. Lesson 6 treats moving holidays as
what they are, a calendar effect modelled on its own.

## What to look for

Read a residual series with three questions, in this order.

1. **Where are the largest values, and do they have names?** A holiday, a promotion, an outage, a
   change of price. A large residual with no name is a question for whoever knows the business.
2. **Does it have a rhythm?** A weekly ripple means a weekly season was missed; a yearly one means
   the season was too stiff. Neither should survive a good decomposition.
3. **Does it drift?** Residuals that sit above 1 for months and then below 1 for months mean the
   trend was too smooth to follow a real change.

A clean residual is not proof the decomposition is right. A dirty one is proof something is wrong,
and it usually says what.
