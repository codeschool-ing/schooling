---
title: The confidence interval
version: 1
---

The central limit theorem says the sample mean is approximately normal around the true mean, with a spread of one standard error. Lesson 8 said that 95% of a normal distribution lies within 1.96 standard deviations of its centre. Put the two together:

> In 95% of samples, the sample mean lands within 1.96 standard errors of the true mean.

Turn it around: if you go 1.96 standard errors either side of the sample mean, you catch the true mean in 95% of samples. That range is a **95% confidence interval**: the sample mean plus or minus 1.96 standard errors.

## For Horta's sample

82.39 ± 1.96 × 12.63 gives **R$ 57.64 to R$ 107.13**.

Horta can say: "the mean basket is R$ 82.39, with a 95% confidence interval of R$ 57.64 to R$ 107.13". The interval is wide because 40 baskets of a very varied quantity do not pin the mean down tightly. The last section of this lesson says how many baskets a narrower interval would need.

The true mean, R$ 82.78, is inside. In real life you would not know that; you would know only that the method catches the true mean in 95% of samples.

## Other levels

1.96 belongs to 95%. Other confidence levels use other multipliers, from the same normal curve:

| confidence | multiplier | interval for Horta's sample |
|---|---|---|
| 90% | 1.645 | narrower |
| 95% | 1.960 | R$ 57.64 to R$ 107.13 |
| 99% | 2.576 | wider |

More confidence costs width. A 99% interval catches the truth more often because it is wider. A 100% interval would run from zero to infinity and say nothing. 95% is a convention, chosen because it is a reasonable balance, and lesson 13 meets its twin, the significance level of 5%.

## What it needs

The interval inherits every assumption of the central limit theorem: a **random sample**, **independent** observations, and a sample **large enough** for the means to be close to normal. For very skewed data like the baskets, 40 is on the small side, and in a simulation later in this lesson the 95% intervals catch the true mean a little less than 95% of the time. And like the theorem, the interval says nothing about bias: a confidence interval from a convenience sample is a precise statement about the wrong population.
