---
title: Tests built on ranks
version: 1
---

The t tests and ANOVA compare means and assume the means behave as the central limit theorem says. With large samples that is usually safe. With small samples from skewed or heavy-tailed data, it may not be, and a single outlier can move a mean, and so a t statistic, a long way.

**Non-parametric** tests avoid the issue by replacing the values with their **ranks**: the smallest value gets rank 1, the next rank 2, and so on, with tied values sharing the average of their ranks. Ranks ignore how far apart the values are, so an outlier is just the largest rank, however extreme it is.

## The three most used

| instead of | use | compares |
|---|---|---|
| Welch's t, two groups | the Mann-Whitney test | whether values from one group tend to be larger |
| the paired t | the Wilcoxon signed-rank test | whether the differences tend to be positive or negative |
| ANOVA | the Kruskal-Wallis test | whether any group tends to have larger values |

## On Horta's data

**Centro against Cambuí, Mann-Whitney**: two-sided p = **0.21**. Same conclusion as Welch's 0.28: no clear difference.

**The training course, Wilcoxon signed-rank**: p = **0.047**, against the paired t test's 0.046. Eight of the ten couriers got faster, and the ranks of their changes agree.

**The four neighbourhoods, Kruskal-Wallis**: H = 83.5 with 3 degrees of freedom, p about 6 × 10⁻¹⁸. Same conclusion as ANOVA.

On this data the rank tests and the mean tests agree, which is the usual outcome when the data is reasonably well behaved. They disagree when outliers or strong skew drive the means.

## When to prefer ranks

- **Small samples from skewed data**, where the central limit theorem has not yet done its work.
- **Ordinal data**, such as star ratings, where lesson 2 warned that means rest on an assumption.
- **Outliers that are real** and should not dominate the conclusion.

## Their price

Rank tests answer a slightly different question — whether one group tends to have larger values, rather than whether the means differ — and they come with no simple confidence interval for the size of a difference in the original units. When the data is well behaved they are a little less powerful than the t test. They are a safety net, not a replacement, and reporting both, when they agree, is a reassuring check.
