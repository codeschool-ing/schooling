---
title: "How much the line explains: R²"
version: 1
---

A line can be the best available and still be poor. **R²**, the **coefficient of determination**, measures how much of the variation in the response it accounts for.

## Splitting the variation

Without a regression, the best prediction for every delivery is the mean, 38.65 minutes. The total squared distance of the data from that mean is the **total sum of squares**: for the 120 deliveries, **13,174.20**.

With the line, that total splits into two parts:

- the part the line accounts for, the squared distances of the **predicted** values from the mean: **11,012.45**;
- the part left over, the squared **residuals**: **2,161.75**.

The two add up to the total. R² is the share accounted for:

**R² = 11,012.45 ÷ 13,174.20 = 0.836**

```localised
=RSQ(D2:D121, A2:A121)     0.835910261670024
=STEYX(D2:D121, A2:A121)   4.28017769397204
```

For a line with one predictor, R² is exactly the square of the correlation from lesson 17: 0.914² = 0.836.

## The size of a typical miss

R² is a proportion, with no units. The **residual standard deviation**, also called the standard error of the regression, gives the same information in minutes: **4.28**. A typical delivery lands about four minutes from the line. Without the line, a typical delivery lands 10.52 minutes from the mean, which is the standard deviation of the minutes.

For a delivery promise, the residual standard deviation is the more useful number. "The line explains 84% of the variation" is abstract. "Predictions are typically off by about four minutes" is something Horta can plan around.

## What R² does not say

A high R² does not mean the line is the right shape: Anscombe's curve in lesson 17 had r² = 0.67 with the wrong model. It does not mean the predictor causes the response: lesson 18. And a low R² does not make a slope useless. The number of items explains only 4% of the variation in delivery times, but its slope is still the best estimate of what an extra item costs.
