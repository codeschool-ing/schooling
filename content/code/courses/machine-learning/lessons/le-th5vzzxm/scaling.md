---
title: Scale, the default penalty, and correlated columns
version: 1
---

Three things about linear models that are invisible until they cause a wrong conclusion.

## Unscaled weights cannot be compared

In `linear.py`, distance's weight is 2.60 and items' is 0.37, and the tempting reading is that
distance matters seven times more. It means nothing of the kind. Distance runs from under one
kilometre to about thirty, items from 4 to 30, and a weight is *per unit*: change the unit of
distance to metres and its weight becomes 0.0026, with exactly the same model.

`StandardScaler` subtracts each column's mean and divides by its standard deviation, so every
column is measured in *standard deviations from typical*. After that, weights are comparable: each
says how much one typical-sized change in that column moves the prediction. `logistic.py` scaled
for that reason, and it is why its ranking means something.

## LogisticRegression is regularised by default

scikit-learn's `LogisticRegression` applies a **ridge penalty unless told otherwise**, with
strength set by `C`, which is the inverse of section 04's `alpha`: smaller `C`, stronger penalty.
The default is `C=1`. Two consequences follow:

- **scaling changes the model**, not just the reading of it. The penalty treats every weight alike,
  so a column on a large scale, which needs only a small weight, is barely penalised, and one on a
  small scale is penalised hard. Unscaled, the penalty quietly favours columns by their units;
- **the weights are shrunk**, by a little when there are many rows, as here. Somebody who reports
  them as "the effect of rating" is reporting a slightly shrunk number. To turn the penalty off,
  pass `C=np.inf`, and expect the solver to need more steps.

`LinearRegression` has no penalty at all; `Ridge` and `Lasso` are its penalised versions.

## Correlated columns share their weight

When two columns carry the same information, a linear model can put the weight on either, or split
it between them, and the predictions barely change. `orders_90d` and `skips_90d` are two views of one
habit: a weekly subscriber who skips more orders less. Their individual weights are then unstable,
and a small change in the training rows can move weight from one to the other, or even flip a
sign.

This is the main reason **not to read a weight as the importance of a column**. A column whose
information is shared with another may get a small weight and still be useful; drop its partner and
its weight jumps. Ridge reduces the instability by spreading weight across correlated columns; lasso
tends to keep one and zero the other, and which one it keeps can depend on luck. Lesson 19 measures
importance in a way that does not depend on weights at all.
