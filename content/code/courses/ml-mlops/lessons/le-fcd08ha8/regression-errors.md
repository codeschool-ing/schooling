---
title: How far off an amount is
version: 1
---

A regression is never right, only near, so its scores measure distance. Lesson 2 used one, the
**mean absolute error**. Two more are common, and the three disagree in a way worth seeing. Save
this as `errors.py`; it imports `examples` from lesson 2's `regress.py`, which should still be in
`~/ml`:

```python
"""errors.py: three ways to measure how far off the spend regression is."""
from sklearn.dummy import DummyRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, median_absolute_error, root_mean_squared_error

import features
from regress import examples

train, test = examples("2025-09-30"), examples("2025-11-30")
y = test["spend_next_90d"] / 100                      # in reais from here on

for name, model in (("average", DummyRegressor()), ("regression", LinearRegression())):
    model.fit(train[features.NUMERIC], train["spend_next_90d"] / 100)
    guess = model.predict(test[features.NUMERIC])
    print(f"{name:10}  MAE R$ {mean_absolute_error(y, guess):6.2f}   "
          f"RMSE R$ {root_mean_squared_error(y, guess):6.2f}   "
          f"median R$ {median_absolute_error(y, guess):6.2f}")

print(f"largest spends: {', '.join(f'R$ {v:.2f}' for v in y.nlargest(3))}")
```

```
ana@dev:~/ml$ python errors.py
average     MAE R$ 213.76   RMSE R$ 266.37   median R$ 194.21
regression  MAE R$ 179.49   RMSE R$ 231.68   median R$ 149.37
largest spends: R$ 1637.20, R$ 1537.70, R$ 1427.80
```

| score | how it is computed | what it is sensitive to |
| --- | --- | --- |
| **MAE**, mean absolute error | the average of the distances | every error equally |
| **RMSE**, root mean squared error | the square root of the average squared distance | large errors, much more than small ones |
| **median absolute error** | the middle distance | almost nothing about the largest errors |

**RMSE is larger than MAE for both models, by about R$ 50**, because a few members spent far more
than anybody predicted: R$ 1,637.20, R$ 1,537.70 and R$ 1,427.80 in 90 days, against an average
prediction near R$ 300. Squared, those few errors dominate. The median says the typical member is
predicted to within R$ 149.37, and it does not care about those three at all.

None of them is the right one in general. **RMSE fits when a large miss is much worse than a small
one**, such as stocking a shop, where running out costs more than a little too much. **MAE fits when
every real is a real.** The median describes the typical member and should never be the only score,
because a model can be good for the typical member and disastrous for the ones that matter most.

And each one means something only beside its baseline: the regression cuts MAE from R$ 213.76 to
R$ 179.49, RMSE from R$ 266.37 to R$ 231.68, and the median from R$ 194.21 to R$ 149.37. **The
improvement is real and modest on all three**, which is more information than any one of them
alone.
