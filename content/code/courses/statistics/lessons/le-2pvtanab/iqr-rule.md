---
title: The IQR rule
version: 1
---

Lesson 6 already introduced the most widely used rule for flagging candidates. A value is a candidate outlier if it lies more than **1.5 IQR** beyond the box:

- below **Q1 − 1.5 × IQR**, or
- above **Q3 + 1.5 × IQR**.

These two lines are called the **fences**. The boxplot draws every value beyond them as a separate point, which is why boxplots are often the first place an outlier is seen.

## Applied to Horta's data

For the twelve delivery times, Q1 = 32.625, Q3 = 41.75 and the IQR = 9.125. The fences are 18.94 and 55.44 minutes. One delivery, the 61-minute one, lies beyond the upper fence. It went to Barão Geraldo, Horta's farthest neighbourhood, so it is a genuine extreme until somebody shows otherwise.

For the 400 baskets, Q1 = R$ 42.56, Q3 = R$ 106.38 and the upper fence is R$ 202.12. **Seventeen baskets** lie beyond it, from R$ 203.05 up to R$ 421.78.

## Seventeen candidates is not seventeen problems

On right-skewed data like the baskets, the IQR rule flags the long tail by design. The tail is not made of errors: it is made of real households doing big shops. A rule built for roughly symmetric data will always flag something on skewed data, and in 400 skewed baskets it flags about 4% of them.

That does not make the rule useless. It makes it a **list of things to look at**, which is all any of these rules is. For the baskets, a quick look at the seventeen — how many items each held, which customers placed them, whether any repeat suspiciously — is enough to say whether they belong.

## Why 1.5?

John Tukey chose it. On normally distributed data, the 1.5 IQR fences sit about 2.7 standard deviations from the mean, so they flag roughly 0.7% of values: about one in 140. That is rare enough to be worth a look and common enough to catch something in a few hundred values. A wider multiplier, 3 IQR, is sometimes used to flag only the "far out" values. The choice is a convention, not a law, and should be stated when the rule is used.

## Its strength

The IQR rule is built from quartiles, and quartiles are robust: the outliers it is looking for cannot move the fences much. That sounds like a technicality. The next section shows why it is the whole point.
