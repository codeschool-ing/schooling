---
title: Putting the chances back
version: 1
---

A model trained on a balanced sample learns chances for a world where half the rows are leavers.
Scored on the real one, every chance is too high. **If the resampling is known, the correction is
arithmetic**, with no data and no second model.

Undersampling kept every leaver and a share *s* of the stayers. That multiplied the odds of leaving,
chance over one minus chance, by 1 / *s*. Multiplying the model's odds by *s* undoes it:

`corrected = chance × s / (chance × s + 1 − chance)`

Save this as `correct.py`; it undersamples, fits, and corrects:

```python
# correct.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
leavers, stayers = train[train["churned"] == 1], train[train["churned"] == 0]
rows = pd.concat([leavers, stayers.sample(len(leavers), random_state=0)])
share_kept = len(leavers) / len(stayers)

model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
chance = model.fit(rows[features], rows["churned"]).predict_proba(test[features])[:, 1]
corrected = chance * share_kept / (chance * share_kept + 1 - chance)

cut = CREDIT / (SAVED * KEPT)
print(f"stayers kept in the sample: {share_kept:.3f}")
print(f"test months: {test['churned'].mean():.3f} cancelled")
for name, c in [("undersampled", chance), ("corrected", corrected)]:
    print(f"{name:13} mean chance {c.mean():.3f}   sent {(c >= cut).sum():6,}"
          f"   R$ {net_value(test['churned'], c >= cut):9,.0f}")
```

The name `share_kept` is there because `KEPT` is already taken: it is `feira.py`'s worth of a
subscriber who stays.

```
ana@lab:~/ml$ python correct.py
stayers kept in the sample: 0.060
test months: 0.061 cancelled
undersampled  mean chance 0.342   sent 12,150   R$  -309,024
corrected     mean chance 0.057   sent  1,019   R$    17,992
```

At the break-even cut the uncorrected model sent 12,150 credits, half the test rows, and lost
R$ 309,024. **Corrected, it says 5.7% where 6.1% happened**, and makes R$ 17,992: the September
problem of lesson 11 again, slightly low, but back in the right world.

The correction is exact only for what the resampling did. It knows nothing of other distortions, and
the model trained on 4,402 rows is still a weaker ranker than the one trained on all of them. So
the order of preference is:

1. **Do not resample, and choose the cut** from the costs, as lesson 11 did.
2. If the data is too large to fit, **undersample and correct with the formula**.
3. If something else distorted the chances, class weights included, **calibrate** them on held-out
   months, as lesson 11's `calibrate.py` did.
