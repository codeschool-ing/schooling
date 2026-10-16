---
title: Which error, for which question
version: 1
---

Lesson 10 ended with a table of classification metrics and the question each one answers. The
regression table is shorter, and the same habit applies: name the question first, then pick the
number.

| question | metric | at Feira em Casa, best model |
|---|---|---|
| how many minutes off, for a typical delivery? | **MAE** | 5.02, `boost_absolute` |
| how bad are the worst misses? | **RMSE**, beside the MAE | 14.3, all three alike |
| how far off, as a share of the delivery? | **MAPE** | 8.7%, but it likes predicting low |
| better than the mean, and by how much? | **R²** | 0.397, the line; negative is an alarm |
| late or early, and how often? | **bias** and **share late** | +2.89 min, late 50.5% |
| how often is the promise kept? | **share late** at a chosen **quantile** | 13.7% at the 0.9 quantile |

Three habits follow, and they mirror lesson 10's.

**Fit with the loss the decision needs.** The metric a model is fitted with is the one it is good
at. A model fitted by squared error and judged by MAE is being judged on something it did not try to
do, and the same goes for a median model asked to make promises. Choose the target first: the median
for "typical", the mean for "on average across many", a high quantile for "a promise".

**Report the direction of the error, always.** Two numbers beside the MAE: the bias and the share on
the expensive side. Neither costs a line of thought to compute, and they are the two the MAE hides.

**Look at the errors, not only their average.** The histogram in the RMSE section showed a hump and
a tail at once, and no summary number shows both. Lesson 22 keeps looking at them,
month by month, as new labels arrive.

For Feira em Casa the decision is now written down. The app shows the 0.9 quantile as the promise.
`boost_absolute` stays in the planning tool, where the logistics team wants the typical time for
routing. The two models answer two questions, and nobody has to pretend that one number serves both.
