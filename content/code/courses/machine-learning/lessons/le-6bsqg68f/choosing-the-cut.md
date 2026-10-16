---
title: Where the cut comes from
version: 1
---

There are two honest ways to choose a cut before the test months are known, and one dishonest one
that looks like the most careful of all.

**From the costs.** If the chances are calibrated, the break-even line is the best cut by
construction, and it needs no data at all: 40 / 144. It moves only when the business's numbers do.

**From a validation period.** Fit the model on the earlier months, score a later stretch it did not
see, and pick whichever cut made the most money there. It needs no assumption about calibration,
and it pays for that with noise: the answer comes from a few hundred leavers.

**From the test months**, which is the dishonest one. The best cut on the months being reported is
the best cut by definition, and quoting the money it made is quoting a number nobody could have
earned.

The program compares all three. Save this as `choose_cut.py`:

```python
# choose_cut.py
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
early = train[train["snapshot"] < "2025-04-01"]
late = train[train["snapshot"] >= "2025-04-01"]
cuts = np.round(np.arange(0.05, 0.51, 0.01), 2)

def chances(learn, score):
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(learn[features], learn["churned"])
    return model.predict_proba(score[features])[:, 1]

def best(rows, chance):
    values = [net_value(rows["churned"], chance >= cut) for cut in cuts]
    return cuts[np.argmax(values)], max(values)

chosen, value = best(late, chances(early, late))
print(f"best cut on April to June: {chosen:.2f}, worth R$ {value:,.0f} there")

chance = chances(train, test)
for name, cut in [("chosen on April to June", chosen), ("break-even, from the costs", CREDIT / (SAVED * KEPT))]:
    print(f"test months, {name:27} {cut:.3f}  R$ {net_value(test['churned'], chance >= cut):,.0f}")
hindsight, value = best(test, chance)
print(f"test months, {'best in hindsight':27} {hindsight:.3f}  R$ {value:,.0f}")
```

```
ana@lab:~/ml$ python choose_cut.py
best cut on April to June: 0.33, worth R$ 7,256 there
test months, chosen on April to June     0.330  R$ 17,984
test months, break-even, from the costs  0.278  R$ 21,672
test months, best in hindsight           0.230  R$ 23,832
```

The validation period picked 0.33, and on the test months that cut made R$ 17,984, **R$ 3,688 less
than the cut from the costs**. Three months with 559 leavers are not enough to find the top of a
hill that is flat: a handful of leavers on one side of a cut or the other moves the best point by
several hundredths. The cut from the costs had no such noise in it, because it was not estimated.

Hindsight says 0.23 and R$ 23,832. **That number is the ceiling of this model on these months, and
it is not a result.** The R$ 2,160 between it and the break-even cut is what the price rise cost a
model that could not know about it.

For Feira em Casa, then, the rule Ana writes into the frame from lesson 1 is: **the cut is the
break-even line, computed from the business's numbers, on a model that `reliability.py` says is
calibrated.** The validation search is worth running as a check. If it lands far from the
break-even line, the chances are probably not honest, and the previous section says what to do.
