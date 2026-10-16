---
title: R², measured against the mean
version: 1
---

**R²**, the coefficient of determination, compares the model's squared errors with those of the
simplest possible prediction, the mean of the truth:

`R² = 1 − sum((truth − prediction)²) / sum((truth − mean of truth)²)`

1 is perfect. 0 is no better than predicting the mean. And despite the square in its name it can be
**negative**: a model worse than the mean scores below zero. Writing it out makes those three facts
easy to check. Save this as `r2.py`:

```python
# r2.py
import pandas as pd

predictions = pd.read_csv("predictions.csv")
truth = predictions["minutes"]

def r2(truth, guess):
    return 1 - ((truth - guess) ** 2).sum() / ((truth - truth.mean()) ** 2).sum()

print(f"the test months' own mean       R² {r2(truth, truth.mean()):6.3f}")
print(f"the median by hour              R² {r2(truth, predictions['by_hour']):6.3f}")
print(f"the line                        R² {r2(truth, predictions['line']):6.3f}")
usual = (truth - predictions["line"]).abs() <= 30
print(f"the line, without stuck ones    R² {r2(truth[usual], predictions['line'][usual]):6.3f}")
print(f"a constant of 60 minutes        R² {r2(truth, 60):6.3f}")
```

```
ana@lab:~/ml$ python r2.py
the test months' own mean       R²  0.000
the median by hour              R²  0.021
the line                        R²  0.397
the line, without stuck ones    R²  0.870
a constant of 60 minutes        R² -0.732
```

Three things to read in it.

**R² is RMSE in disguise.** It is built from the same squared errors, so it ranks models exactly as
RMSE does on the same rows, and it inherits the same weakness: the line explains 39.7% of the
variation with the stuck deliveries in, and 87.0% without them. The model did not get better
between the two lines; the rows it was asked about changed.

**R² depends on the rows as much as on the model.** The denominator is how spread out the truth is.
The same model scored on a set of very similar deliveries gets a low R², and on a set that mixes
short and long trips a high one, with exactly the same errors in minutes. That makes R² useless for
comparing models scored on different data, and a poor answer to "is this good enough?". A
logistics manager can judge "off by five minutes". Nobody can judge "explains 40% of the variance"
without knowing what was there to explain.

**Below zero means worse than knowing nothing.** A constant guess of 60 minutes scores −0.732. Real
models reach negative R² more often than people expect, usually on new months that differ from the
ones they learned from, since the mean in R²'s formula is the mean of the test rows. That number was
not available to the model, so beating it is not guaranteed.

R² is worth printing because it is the number a statistician expects to see, and because a negative
one is an alarm. As the main metric for a decision it says too little.
