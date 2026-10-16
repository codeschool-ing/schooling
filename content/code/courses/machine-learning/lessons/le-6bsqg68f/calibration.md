---
title: Calibrating a model that distorts
version: 1
---

When the distortion is the model's own, it can be repaired. **Calibration** fits a second, small
model that reads the first one's chance and returns an honest one, learned from rows the first
model did not train on. scikit-learn has two kinds:

- **sigmoid**, also called Platt scaling, fits lesson 5's S-shaped curve to the chances. Two
  numbers, so it needs little data, and it can only stretch and shift.
- **isotonic** fits any curve that only goes up. It can fix any distortion that keeps the order,
  and it needs more rows to do it without learning noise.

To see one at work, it helps to have a model that distorts. **`class_weight="balanced"` makes the
model treat every leaver as if it were about sixteen of them**, which lesson 13 uses on purpose and which
inflates every chance it gives. The program below trains a plain model and a weighted one on the
months to March 2025, keeps April to June to calibrate on, and then sends credits on the test months
at the break-even cut. Save this as `calibrate.py`:

```python
# calibrate.py
from sklearn.calibration import CalibratedClassifierCV
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.frozen import FrozenEstimator

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
early = train[train["snapshot"] < "2025-04-01"]
late = train[train["snapshot"] >= "2025-04-01"]

def booster(**settings):
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0,
                                           **settings)
    return model.fit(early[features], early["churned"])

plain, weighted = booster(), booster(class_weight="balanced")
models = {"plain": plain, "weighted": weighted}
for method in ["sigmoid", "isotonic"]:
    calibrator = CalibratedClassifierCV(FrozenEstimator(weighted), method=method)
    models[f"weighted, {method}"] = calibrator.fit(late[features], late["churned"])

cut = CREDIT / (SAVED * KEPT)
print(f"April to June: {late['churned'].mean():.3f} of rows cancelled")
print("model                chance on April to June   sent in test   net value")
for name, model in models.items():
    print(f"{name:20} {model.predict_proba(late[features])[:, 1].mean():23.3f}", end="")
    send = model.predict_proba(test[features])[:, 1] >= cut
    print(f" {send.sum():14,}   R$ {net_value(test['churned'], send):9,.0f}")
```

`FrozenEstimator` tells `CalibratedClassifierCV` that the model is already fitted and must not be
fitted again; it then learns only the correction, from the rows it is given.

```
ana@lab:~/ml$ python calibrate.py
April to June: 0.052 of rows cancelled
model                chance on April to June   sent in test   net value
plain                                  0.054            713   R$    18,856
weighted                               0.307          9,645   R$  -215,016
weighted, sigmoid                      0.052            636   R$    17,760
weighted, isotonic                     0.052            381   R$    13,848
```

Read the second column first. On April to June, 5.2% of rows cancelled. **The plain model said
5.4%, honest enough**, which confirms the previous section: before the price rise its chances meant
what they said. The weighted model said 30.7%, six times too much, and at the break-even cut it sent
9,645 credits and lost R$ 215,016. Same features, same trees, nearly the same ranking; only the level
was wrong, and the level is what a cut reads.

Both calibrators bring it back to 5.2% and back to making money. Neither beats the plain model, and
that is the usual result: **calibration repairs a distortion, it does not add information.** The
isotonic one does worse than the sigmoid, because three months held only 559 leavers, and a
curve free to take any shape learns some of their noise. The plain model also had an advantage
that is easy to miss. It needed no months set aside, while both calibrators had to give up April to
June, which on a real project would have been training data.

Three rules come out of this:

- **Calibrate when the model distorts**: class weights, resampling (lesson 13), and some algorithms
  that are known to, such as naive Bayes and support vector machines. Check with
  `reliability.py` first; a boosted model like this one is usually close already.
- **Calibrate on rows the model never saw**, later in time than the ones it learned from, for the
  same reason every score in this course is.
- **Calibration cannot fix the September problem.** The calibrator learns from April to June, and
  April to June were before the rise too.
