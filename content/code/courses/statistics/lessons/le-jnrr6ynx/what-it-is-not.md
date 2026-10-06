---
title: What a p-value is not
version: 1
---

Studies of how researchers read p-values find the same mistakes again and again. Each of these statements sounds reasonable, and each is wrong.

## "The probability that the null hypothesis is true"

The routing test's p-value of 0.165 does **not** mean there is a 16.5% chance that the new system makes no difference. The p-value was computed assuming the null is true, so it cannot also be the probability that it is true. It is the probability of the **data**, given the null, not the probability of the **null**, given the data.

The two can be very different. Suppose most routing tweaks a supplier offers do nothing at all. Then even a small p-value can come from a tweak that does nothing, because the useless tweaks vastly outnumber the useful ones. How likely a hypothesis is depends on what was plausible before the data, which the p-value ignores.

## "The probability that the result is due to chance"

This is the first mistake in other words. "Due to chance" means "the null is true", and the p-value is not the probability of that.

## "One minus p is the probability the alternative is true"

The filling machine's p-value of 0.0009 does not mean a 99.91% chance that the machine is off target. Same reason: the p-value is about the data under the null, and it says nothing direct about the probability of either hypothesis.

## "A small p-value means a big effect"

A p-value mixes the size of the effect with the size of the sample. A tiny effect measured on a huge sample can give a tiny p-value, and a large effect measured on a small sample can give a large one. The filling machine's 4.6 g overfill is significant because the bags are so consistent; the same 4.6 g with a spread of 40 g would not have been. **To learn how big an effect is, look at the estimate and its interval, not at p.**

## "A large p-value means there is no effect"

The routing test's 0.165 says the data is consistent with no effect. It is also consistent with an improvement of one or two minutes, as lesson 13 noted. Absence of evidence is not evidence of absence, and the next section's confidence interval makes that visible.

## "The result will replicate with probability 1 − p"

A p-value of 0.03 does not mean a 97% chance of getting a significant result again. A result that only just crossed 0.05 has roughly even chances of crossing it again in an identical study. Replication is a separate question with its own, less flattering, arithmetic.

In 2016 the American Statistical Association published a statement listing principles for using p-values, because misuse had become so widespread. Its first principle is the definition at the start of this lesson, and most of the rest are this section.
