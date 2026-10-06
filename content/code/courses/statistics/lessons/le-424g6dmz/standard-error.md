---
title: The standard error
version: 1
---

Lesson 11 showed that sample means spread around the population mean with a standard deviation of σ ÷ √*n*. In practice σ, the population's standard deviation, is unknown. What you have is one sample, and its standard deviation *s*.

So the spread is estimated by putting *s* in σ's place: **SE = *s* ÷ √*n***.

This estimate has its own name, the **standard error** of the mean, or **SE**. It is the estimated standard deviation of the sampling distribution: how far, typically, a sample mean of this size lands from the true mean.

## Horta's sample of 40

Horta draws 40 orders at random from the month's 400. The sample has

- a mean of **R$ 82.39**,
- a standard deviation of **R$ 79.86**,
- so a standard error of 79.86 ÷ √40 = **R$ 12.63**.

With the data in A2:A41:

```localised
=STDEV.S(A2:A41)/SQRT(40)      12.6264621645681
```

Read that as: a mean of 40 baskets typically lands about R$ 13 from the true mean. The sample mean of R$ 82.39 is one such landing.

## Standard deviation versus standard error

The two are easily confused, and they answer different questions.

| | measures | for the sample of 40 |
|---|---|---|
| standard deviation, *s* | how spread out the **individual baskets** are | R$ 79.86 |
| standard error, *s* ÷ √*n* | how uncertain the **mean** is | R$ 12.63 |

The standard deviation describes the data, and does not shrink as the sample grows: baskets are as varied as they are. The standard error describes the estimate, and does shrink, because the mean of a larger sample is pinned down more tightly.

A report that writes "mean R$ 82.39 ± 79.86" is saying that individual baskets vary a lot. A report that writes "mean R$ 82.39 ± 12.63" is saying that the mean is known to about R$ 13. **Always say which one the ± is.**

## The population knew all along

Because the 400 baskets are the whole month, the true mean is known in this example: R$ 82.78. The sample missed it by R$ 0.39, much less than one standard error. That was luck as much as anything; the next section turns the standard error into a range that is right with a stated frequency.
