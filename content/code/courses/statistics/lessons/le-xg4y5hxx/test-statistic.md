---
title: The test statistic
version: 1
---

The **test statistic** turns the sample into one number that says how far the data is from what the null hypothesis predicts, measured in units of the noise.

For a test about a mean, it is the **t statistic**:

```localised
t = (sample mean − value under the null) ÷ SE
```

The top is the **signal**: the difference between what was observed and what the null says. The bottom is the **noise**: the standard error from lesson 12, how much sample means wobble by chance. A t of 3 means the sample mean is three standard errors from the null's value; a t of 0.5 means it is half a standard error away, well within ordinary wobble.

## Signal over noise

The ratio is the whole idea, and it explains three things.

- A **bigger difference** gives a bigger t. A mean of 35 is more convincing evidence against 40 than a mean of 39.
- **Noisier data** gives a smaller t. If delivery times vary wildly, a three-minute drop could easily be chance.
- **More data** gives a bigger t for the same difference, because the standard error shrinks with √*n*. Lesson 22 returns to this, because with enough data even a trivial difference produces a large t.

## Its distribution under the null

If the null hypothesis is true, and the sample is random, the t statistic follows the **t distribution with *n* − 1 degrees of freedom**: the same distribution lesson 12 used for intervals. That is what makes the test possible: the null predicts the shape of the curve the statistic should fall on, and the test checks where it actually fell.

## For Horta's deliveries

The 25 deliveries under the new routing have a mean of **38.9 minutes** and a standard deviation of **5.52**, so the standard error is 5.52 ÷ √25 = **1.10**. Against the null's 40:

```localised
t = (38.9 − 40) ÷ 1.10 = −1.00
```

The sample mean is one standard error below 40. Whether that is far enough is the next section's question.
