---
title: Measuring skewness
version: 1
---

"Skewed to the right" is a description. **Skewness** is a number for it: positive for a tail to the right, negative for a tail to the left, and close to zero for a symmetric shape.

## Where the number comes from

The standard measure works with the deviations from the mean, like the variance, but **cubes** them instead of squaring them. Cubing keeps the sign: a value far above the mean contributes a large positive cube, one far below a large negative one. In a symmetric distribution these cancel out. In a right-skewed one the far values above the mean outweigh those below, and the total comes out positive.

The deviations are first divided by the standard deviation, so that the result has no units and the same shape gives the same skewness whether it is measured in reais or in centavos. A spreadsheet's `SKEW` also applies a small correction for the sample size.

```localised
=SKEW(A2:A401)      2.1000341481596
```

That is LibreOffice Calc's answer for the 400 baskets. For the three shapes of the previous section:

| data | skewness |
|---|---|
| test scores | −1.37 |
| bags of rice | −0.05 |
| baskets | 2.10 |

## Reading the size

A common rough guide, and it is only a guide:

- between −0.5 and 0.5, **roughly symmetric**;
- between 0.5 and 1 in either direction, **moderately skewed**;
- beyond 1 in either direction, **strongly skewed**.

The bags at −0.05 are symmetric for every practical purpose. The baskets at 2.10 are strongly right-skewed, and the scores at −1.37 strongly left-skewed.

## A simpler measure from things you already have

A rougher measure, sometimes called **Pearson's median skewness**, needs only the mean, the median and the standard deviation:

```localised
3 × (mean − median) ÷ standard deviation
```

For the baskets: 3 × (82.78 − 66.74) ÷ 58.89 = **0.82**. It is smaller than the 2.10 that `SKEW` gives, because it measures something slightly different, but it has the same sign, and it turns the "mean versus median" rule of thumb into a number.

## Skewness is fragile

Because it cubes the deviations, skewness is even more sensitive to extreme values than the standard deviation. In a sample of 400 baskets, a single R$ 2,000 order would raise it sharply. A skewness from a small sample is a rough indication at best; with twelve values it can swing a long way when one value changes. Look at the histogram as well as the number.
