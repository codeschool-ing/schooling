---
title: The standard deviation
version: 1
---

The **standard deviation** is the square root of the variance. It undoes the squaring of the units and brings the measure back to the scale of the data.

- Davi: √66 = **8.12 minutes**.
- Lia: √1.14 = **1.07 minutes**.

Now the numbers can be said aloud. Davi's deliveries typically sit about 8 minutes from his mean; Lia's about 1 minute from hers. Davi's standard deviation is nearly eight times Lia's, and that is the number Horta's dispatcher would want before promising anybody a delivery time.

## What the number means

The standard deviation is roughly **a typical distance from the mean**. It is not exactly the average distance — that was the mean absolute deviation, 6.5 minutes for Davi — because the squares give the far values extra weight. It is always at least as large as the mean absolute deviation, and usually a little larger.

A rough guide, which lesson 8 makes precise for one important shape: in a lot of real data, about two thirds of the values lie within one standard deviation of the mean. For Horta's twelve delivery times, with a mean of 38.96 and a standard deviation of 9.77 minutes, the band from 29.19 to 48.73 holds 8 of the 12. In the 400 baskets, 83% fall within one standard deviation of the mean, more than two thirds because the long right tail inflates the standard deviation. The guide is a guide, and the shape of the data decides how good it is.

## The symbols

The sample standard deviation is written *s*, and the sample variance *s*². The formula, with *x̄* the mean and *n* the number of values, is *s* = √( Σ(*x* − *x̄*)² ÷ (*n* − 1) ). The Σ, the Greek capital sigma, means "add up over all the values". Every piece of it is a step from the table in the previous section: deviation, square, add, divide by *n* − 1, square root.

## In a spreadsheet

With Davi's times in A2:A9:

```localised
=VAR.S(A2:A9)       66
=STDEV.S(A2:A9)     8.12403840463596
```

Those are the values LibreOffice Calc returned. The `.S` stands for *sample*, and divides by *n* − 1. Each also has a `.P` version, for *population*, which divides by *n*. On Davi's eight times, `STDEV.P` returns 7.60. The next section is about which one to pick, and the answer is almost always `.S`.

## Zero, and never negative

A standard deviation of zero means every value is the same: no spread at all. It can never be negative, because it is the square root of an average of squares. A negative standard deviation in a report is a mistake, every time.
