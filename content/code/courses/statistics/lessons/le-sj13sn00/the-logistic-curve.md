---
title: Odds, log-odds and the logistic curve
version: 1
---

Logistic regression gets its S-shape by fitting a straight line on a different scale, and converting back.

## Odds

The **odds** of an event are its probability divided by the probability that it does not happen:

**odds = p ÷ (1 − p)**

A probability of 0.2 is odds of 0.2 ÷ 0.8 = **0.25**, one to four. A probability of 0.5 is odds of 1, even. A probability of 0.8 is odds of **4**, four to one. Odds run from 0 to infinity: they have a floor but no ceiling.

## Log-odds

Taking the natural logarithm of the odds removes the floor too. The **log-odds**, or **logit**, run from minus infinity to plus infinity, and are symmetric around a probability of one half:

| probability | odds | log-odds |
|---|---|---|
| 0.1 | 0.111 | −2.197 |
| 0.2 | 0.25 | −1.386 |
| 0.5 | 1 | 0 |
| 0.8 | 4 | 1.386 |
| 0.9 | 9 | 2.197 |

## The model

Logistic regression models the log-odds as a straight line:

**log-odds of a complaint = a + b × minutes**

A line on this scale can take any value without producing an impossible probability, because every log-odds value converts back to a probability between 0 and 1:

**p = 1 ÷ (1 + e^(−log-odds))**

For Horta's 400 orders the fitted model is

**log-odds = −8.463 + 0.1485 × minutes**

At 45 minutes the log-odds are −8.463 + 0.1485 × 45 = −1.778, the odds are 0.169, and the probability is **0.145**. The probability reaches one half where the log-odds are zero: at 8.463 ÷ 0.1485 = **57.0 minutes**.

## How it is fitted

Least squares does not suit a binary outcome. Logistic regression uses **maximum likelihood** instead: it chooses the coefficients under which the complaints that actually happened would have been most probable. There is no formula for the answer; software finds it by repeated improvement, in a handful of steps. Spreadsheets have no built-in function for it, but once the coefficients are known, a probability is one formula. With a delivery time of 45 minutes:

```localised
=1/(1+EXP(-(-8.7357+0.1489*45)))           0.115556402479762
=1/(1+EXP(-(-8.7357+0.1489*45+0.8864)))    0.240708336203664
```

Those use the model with first orders, in the next section: a returning customer and a first-time one, both at 45 minutes.
