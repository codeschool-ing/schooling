---
title: Power
version: 1
---

The **power** of a test is the probability that it rejects the null hypothesis when a particular effect is really there:

**power = 1 − β**

It is the probability of finding what you are looking for, if it exists. A study with 80% power for a two-minute improvement will detect a real two-minute improvement four times out of five.

## The power of Horta's trial

Horta's trial had 25 deliveries, a standard deviation of about 6 minutes and a one-sided test at 5%. How often would it detect a real improvement? A simulation answers directly: generate 4,000 trials of 25 deliveries under each true improvement, run the test on each, and count the rejections.

| true improvement | simulated power |
|---|---|
| 1 minute | 21% |
| 2 minutes | 48% |
| 3 minutes | 79% |

For a two-minute improvement, the trial was roughly a **coin toss**: it would find the improvement about half the time and miss it about half the time. For a one-minute improvement, it would miss it four times out of five.

So lesson 13's non-significant result says much less than it seemed. The trial was simply not large enough to have a good chance of detecting an improvement of the size that would matter.

## What drives power

Four things, all visible in the previous section's picture.

- **The size of the effect.** Bigger effects move the alternative curve further from the null, and are easier to see.
- **The sample size.** More data narrows both curves, through the √*n* in the standard error.
- **The noise.** A smaller standard deviation narrows both curves too: measuring more precisely is like having more data.
- **The significance level.** A larger α moves the line towards the alternative and raises power, at the cost of more false alarms.

Of the four, the sample size is usually the one you control.

## A formula, roughly

For a one-sided test of a mean, a normal approximation gives the power as the area of the standard normal curve below *δ* ÷ SE − 1.645, where *δ* is the true improvement and SE the standard error. For a two-minute improvement with SE = 1.2: 2 ÷ 1.2 − 1.645 = 0.022, and the area below 0.022 is 0.51. Close to the simulated 48%; the small difference is the t distribution's thicker tails at 24 degrees of freedom.

```localised
=NORM.S.DIST(2/(6/SQRT(25)) - NORM.S.INV(0.95), TRUE)      0.508701453763093
```
