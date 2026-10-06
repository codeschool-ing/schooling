---
title: An interval for a proportion
version: 1
---

Lesson 1 showed that a yes/no column coded 1 and 0 has a mean equal to the share of yeses. Lesson 11 noted that this makes a proportion a mean, so the central limit theorem covers it. That gives a confidence interval for a proportion almost for free.

## The standard error of a proportion

For a 0/1 variable with a share *p̂* of ones, the standard deviation works out to √(*p̂*(1 − *p̂*)), so the standard error of the proportion is **SE = √(*p̂* × (1 − *p̂*) ÷ *n*)**, and the 95% interval is *p̂* ± 1.96 × SE.

## Horta's satisfaction survey

Horta surveys 400 randomly chosen customers, and **248** say they are satisfied with their deliveries. The sample proportion is 248 ÷ 400 = **0.62**.

- SE = √(0.62 × 0.38 ÷ 400) = **0.0243**.
- The margin is 1.96 × 0.0243 = **0.0476**, a little under 5 percentage points.
- The 95% interval is **0.572 to 0.668**: between about 57% and 67% of all customers are satisfied.

This is where the "margin of error" in a news report on an opinion poll comes from: "62%, with a margin of error of 5 points" is this calculation, with the 95% left unsaid.

## When it works

The normal approximation behind this interval needs enough of each outcome. A common rule: **at least 10 yeses and 10 noes** in the sample. The survey's 248 and 152 are plenty.

Horta's twelve orders with three late deliveries fail it badly: 3 late and 9 on time. The formula would give 0.25 ± 0.245, an interval from 0.005 to 0.495, which pretends to a precision twelve orders cannot have. For small counts, statistical software offers better intervals for a proportion, of which the **Wilson interval** is the usual choice; the formula above is for samples where both counts are comfortably large.

## The worst case for the margin

The term *p̂*(1 − *p̂*) is largest when *p̂* = 0.5, where it is 0.25. So for any sample size, the widest the margin can be is 1.96 × √(0.25 ÷ *n*). For 400 people, that is 4.9 points; the survey's 62% gave 4.8. That worst case is what the next section uses to plan a survey before its results exist.
