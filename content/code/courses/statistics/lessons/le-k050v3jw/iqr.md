---
title: The interquartile range
version: 1
---

The **interquartile range**, or IQR, is Q3 minus Q1: the width of the middle half of the data.

For the twelve delivery times, 41.75 − 32.625 = **9.125 minutes**. Half of Horta's deliveries fall in a band about nine minutes wide.

```localised
=QUARTILE.INC(A2:A13, 3) - QUARTILE.INC(A2:A13, 1)      9.125
```

## Robust, like the median

The IQR ignores the top quarter and the bottom quarter of the data. Change the slowest delivery from 61 minutes to 610, and the IQR does not move, while the standard deviation would grow from 9.77 to more than 160.

That makes the IQR to the standard deviation what the median is to the mean: **a robust measure of spread**. Its breakdown point is a quarter. To move it arbitrarily you would have to corrupt a quarter of the values, against one value for the standard deviation.

## Choosing between the IQR and the standard deviation

The two measure spread in different ways, and on skewed data they tell different stories.

For the 400 baskets, the standard deviation is R$ 58.89 and the IQR is R$ 63.82, from Q1 = R$ 42.56 to Q3 = R$ 106.38. The numbers are similar in size, but they do not describe the same thing: the IQR describes the middle half, where most customers are, and the standard deviation is pulled up by the long tail of big baskets.

The pairing is natural:

| centre | spread | when |
|---|---|---|
| mean | standard deviation | roughly symmetric data, or questions about totals |
| median | IQR | skewed data, or data that may hold extreme values |

**Report them in matched pairs.** A median with a standard deviation mixes a robust centre with a fragile spread, and the reader cannot tell which story the numbers are telling.

## The IQR as a ruler

The IQR also gives a scale for deciding whether a value is unusually far from the rest. A delivery 1.5 IQRs beyond Q3 is, by a widely used convention, far enough to deserve a look. For the twelve deliveries, that line is 41.75 + 1.5 × 9.125 = **55.44 minutes**, and one delivery, the 61-minute one, lies beyond it. The boxplot is built on exactly that ruler, and lesson 9 asks what to do with the values it flags.
