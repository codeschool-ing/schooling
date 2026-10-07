---
title: Why divide by n − 1?
version: 1
---

The sample variance divides the sum of squares by *n* − 1 instead of *n*. It looks like a fussy correction, and it fixes a real bias.

## The problem: the sample's own mean is too close

The deviations are measured from the **sample's** mean, not from the true mean of everything the sample came from. The true mean is unknown — that is usually why you took a sample. And the sample's own mean has one property that biases the result: it is the point that makes the sum of squared deviations **as small as it can be**. Measure the same eight values from any other point, the true mean included, and the sum of squares comes out larger.

So a sum of squares around the sample mean is systematically a little too small, and dividing it by *n* gives a variance that is too small on average. Dividing by the smaller number *n* − 1 inflates it by exactly the right amount.

## Seeing it on a population you can list

Take a tiny population whose true variance is known: three delivery times, **30, 35 and 43 minutes**. Their mean is 36, and their variance, divided by *n* because this is the whole population, is **28.67**.

Now draw every possible sample of two times, with replacement, so that each draw is independent of the other. There are nine: (30, 30), (30, 35), (30, 43), (35, 30) and so on. For each sample, compute the variance both ways and average across the nine:

| divide by | average of the nine sample variances |
|---|---|
| *n* = 2 | 14.33 |
| *n* − 1 = 1 | 28.67 |

Dividing by *n* gets it wrong by half, on average. Dividing by *n* − 1 hits the population's 28.67 exactly. That is what statisticians mean when they say the *n* − 1 version is **unbiased**: averaged over every sample you could have drawn, it lands on the truth.

## Degrees of freedom

The usual name for *n* − 1 is the **degrees of freedom**. Once the sample mean is fixed, only *n* − 1 of the deviations are free to vary: the last one is forced, because they must add up to zero. Davi's first seven deviations are −13, −9, −4, 0, 3, 5 and 9; the eighth must be 9 to make the total zero. Eight values, seven independent pieces of information about spread.

The phrase comes back in lessons 12 to 16, where every test statistic carries its degrees of freedom.

## When to divide by n

Divide by *n* only when the data **is** the whole population and you want to describe it, not to infer anything beyond it: the salaries of Horta's nine staff, if the question is about those nine people and nobody else. In practice that is rare, and the difference shrinks as *n* grows: with 400 baskets, dividing by 399 or 400 changes the standard deviation in the fourth significant figure.
