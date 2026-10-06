---
title: The logic of a test
version: 1
---

A hypothesis test answers one kind of question: **is the pattern in the sample bigger than chance alone would produce?**

The answer is never proved directly. Instead, the test assumes the opposite — that there is no pattern, only chance — and asks whether the data fits comfortably with that assumption. If it does not, the assumption is rejected, and the pattern is said to be **statistically significant**.

## The courtroom

The structure is the same as a criminal trial.

| trial | test |
|---|---|
| the defendant is presumed innocent | the null hypothesis is assumed true |
| the prosecution presents evidence | the sample is collected |
| guilt must be shown beyond reasonable doubt | the data must be very unlikely under the null |
| the verdict is guilty or not guilty | the null is rejected or not rejected |

The last row is the one people get wrong. A trial never declares anybody **innocent**: it declares them **not guilty**, meaning the evidence was not strong enough. A test is the same. **Failing to reject the null hypothesis is not proof that it is true.** It means the data did not provide enough evidence against it.

## Why argue backwards?

It would be more natural to ask "how likely is it that the new routing helps?". The classical test does not answer that, because it treats the truth as fixed and only the data as random — the same view lesson 12 took of confidence intervals. What it can compute is how likely the data is under a precise assumption. "The new routing changes nothing" is precise: it says the mean is 40 minutes. "The new routing helps" is vague: by one minute? by ten? So the test works from the precise statement, and asks whether the data can live with it.

## Four steps

Every test in the rest of this course follows the same steps.

1. **State the hypotheses**: the null and the alternative.
2. **Choose the significance level**, before seeing the data.
3. **Compute a test statistic** from the sample: how far the data is from what the null predicts, in units of its own noise.
4. **Decide**: reject the null if the statistic falls where the null says it rarely would.

The next four sections take one step each, and the last runs the whole thing on Horta's deliveries.
