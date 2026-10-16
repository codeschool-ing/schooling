---
title: MAPE, the error as a percentage
version: 1
---

The **mean absolute percentage error** divides each error by the truth before averaging:

`MAPE = mean(|truth − prediction| / truth)`

Its appeal is that it has no unit. "Off by 8.7%" can be compared across a model of delivery minutes
and a model of monthly revenue, and managers like a percentage. Its trouble is the same division,
in two ways.

**Small truths make huge percentages.** A delivery of 15 minutes predicted at 25 is 67% off; one of
60 predicted at 70 is 17% off, for the same ten minutes. Here the shortest delivery took 15 minutes,
so nothing explodes. On a target that can be zero, such as units sold on a quiet day, MAPE divides by
zero and is meaningless, and on one that is often close to zero it is dominated by those rows.

**It is lopsided.** Under-predicting can cost at most 100%: predict zero and you are exactly 100% off,
however long the delivery took. Over-predicting has no ceiling. So a model chosen by MAPE is pulled
towards predicting too little. The program below shifts every `boost_absolute` prediction 10% down
and 10% up, and asks both metrics which is worse. Save this as `mape.py`:

```python
# mape.py
import pandas as pd
from sklearn.metrics import mean_absolute_error, mean_absolute_percentage_error

predictions = pd.read_csv("predictions.csv")
truth = predictions["minutes"]
print("every prediction    MAE    MAPE")
for name, factor in [("10% lower", 0.9), ("as fitted", 1.0), ("10% higher", 1.1)]:
    guess = predictions["boost_absolute"] * factor
    print(f"{name:16} {mean_absolute_error(truth, guess):6.2f} "
          f"{mean_absolute_percentage_error(truth, guess):7.1%}")
```

```
ana@lab:~/ml$ python mape.py
every prediction    MAE    MAPE
10% lower          7.17   12.9%
as fitted          5.02    8.7%
10% higher         6.62   13.0%
```

**The two metrics disagree about the direction.** In minutes, predicting 10% too low is worse,
because of the long deliveries in the tail. In percentages, predicting 10% too high is very slightly
worse, because the division gives more weight to the short deliveries and to errors on the high side.
On a delivery promise that matters: the metric that likes low predictions is the one that makes
promises the van cannot keep.

Use MAPE to **report** an error to somebody who thinks in percentages, on a target that is never
near zero. Be careful choosing a model by it, and do not choose one by it when being late is the
expensive mistake.
