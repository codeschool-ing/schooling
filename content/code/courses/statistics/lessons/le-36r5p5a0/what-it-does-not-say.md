---
title: What the theorem does not say
version: 1
---

The central limit theorem is powerful enough to be misquoted often. Here are the claims it does **not** make.

## It does not make the data normal

The baskets are just as skewed with 400 of them as with 40. The theorem is about the **means of samples**, not the values in them. A large sample has a histogram that looks more and more like the **population** — skewed, if the population is skewed — while the means of many such samples look more and more like a bell. Confusing the two leads people to call skewed data "normal because n is large", which is wrong.

## "30 is enough" is not a law

For the baskets, means of 30 still had a skewness of 0.34. For populations with very heavy tails — incomes in a country, the sizes of insurance claims, the number of followers per account — the means of samples of 30, or of 300, can still be noticeably skewed, and a normal approximation can understate how often a sample mean lands far out. The heavier the tails, the larger the sample needs to be. For a few extreme distributions, whose standard deviation is infinite, the theorem does not apply at all.

## It needs random, independent observations

The theorem assumes each observation is drawn independently from the same population. A convenience sample of the 60 nearest deliveries has a mean that is beautifully stable and steadily wrong, as lesson 10 showed: the theorem describes the wobble around the target, and says nothing about whether the sample is aimed at the right target. **Bias is outside its reach.** Observations that are not independent, such as deliveries on the same rainy evening, also break it: they push together instead of cancelling.

## It is about the mean

The theorem, as stated here, is about the sample **mean**, and anything built like one: a proportion is a mean of zeros and ones, so it qualifies, which lesson 12 uses. Other statistics have sampling distributions too, often roughly normal for large samples, but with their own spreads. The median of samples of 30 baskets, for example, has a spread of R$ 8.91, smaller than the mean's R$ 10.67, because the median ignores the tail. Its formula is not σ ÷ √*n*.

## What it does say, once more

Take a large enough random sample, and its mean is approximately normally distributed around the true mean, with spread σ ÷ √*n*. That one sentence is what turns a single sample into a statement with a margin of error, and lesson 12 makes the turn.
