---
title: MAE, the error in minutes
version: 1
---

The **mean absolute error** is the average distance between prediction and truth, ignoring the
sign:

`MAE = mean(|truth − prediction|)`

It is the metric every earlier lesson used under another name, and its great virtue is that **it is
in the target's own unit**. "Off by 5.02 minutes on average" needs no explaining to a logistics
manager. Every delivery counts in proportion to how wrong it was: one ten minutes off counts twice
as much as one five minutes off, and no more.

**The MAE is smallest when the prediction is the median.** That is a property of absolute
distance, not of this data. Picture five deliveries of 30, 32, 35, 40 and 120 minutes. A guess of
35, the median, is off by 5 + 3 + 0 + 5 + 85 = 98 minutes in total. Move the guess to 36 and the
three shorter deliveries each cost a minute more, while the two longer ones each cost a minute
less: 99 in total. Every step away from the middle adds more than it takes away. The size of the
120 never enters into it, only the fact that it is above the guess.

That explains the table. `boost_absolute` was fitted to minimise absolute error, so it aims at the
median delivery time for each kind of trip, and the metric that rewards medians ranks it first. The
two models fitted by squared error aim at the mean, which here sits above the median, because a few
deliveries take an hour or two longer than usual. Aiming at the mean costs them 0.85 and 1.21 minutes of
MAE.

So the first thing to know about any metric is **which summary of the target it rewards**:

| metric | is smallest at | so a model fitted for it predicts |
|---|---|---|
| MAE | the median | the typical delivery |
| squared error, and so RMSE | the mean | the typical delivery plus a share of the disasters |

A model should usually be fitted with the loss its metric rewards. When lesson 8 chose
`loss="absolute_error"`, it was choosing the MAE without saying so.
