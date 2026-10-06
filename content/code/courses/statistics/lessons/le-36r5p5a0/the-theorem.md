---
title: The central limit theorem
version: 1
---

The **central limit theorem** says, in plain language:

> When you take the mean of a large enough random sample, that mean comes from a distribution that is approximately **normal**, centred on the **population mean**, with a standard deviation equal to the **population standard deviation divided by the square root of the sample size**.

And it says this **whatever the shape of the population**: skewed, flat, lumpy, it does not matter, provided the population's standard deviation is finite and the observations are independent.

## The three parts

**The shape is normal.** The means pile up in a bell curve, even when the data does not. That is the surprising part, and the reason the normal distribution of lesson 8 matters far beyond bags of rice.

**The centre is the population mean.** The sample mean is unbiased: on average across samples, it hits μ exactly.

**The spread is σ ÷ √*n*.** The spread of the sample means is smaller than the spread of the data by a factor of √*n*. Lesson 12 gives that quantity a name, the **standard error**, and builds the confidence interval from it.

## In symbols

For random samples of size *n* from a population with mean μ and standard deviation σ, the sample mean *x̄* is approximately **normal, with mean μ and standard deviation σ ÷ √*n***.

For Horta's baskets, with σ = R$ 58.82, samples of 30 give means with a standard deviation of 58.82 ÷ √30 = **R$ 10.74**, and samples of 100 give 58.82 ÷ 10 = **R$ 5.88**.

## Why should averaging produce a bell?

An intuition, not a proof. A sample mean is a sum of many independent pieces, divided by a number. Each basket in the sample pushes the mean up or down a little. Extreme results need many pieces to push the same way at once — all thirty baskets large, say — and that is rare, because the pieces are independent. Middling results can happen in a huge number of ways. Many small independent pushes, most of them cancelling, produce the bell. It is the same reason lesson 8 gave for the bags of rice: many small independent effects added together.

The theorem was developed over more than a century, from Abraham de Moivre in the 1730s, who found the normal curve as an approximation to coin tossing, through Pierre-Simon Laplace, to a general proof in the early twentieth century.
