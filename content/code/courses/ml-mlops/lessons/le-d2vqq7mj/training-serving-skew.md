---
title: Training-serving skew
version: 1
---

A model learns what its features meant **in the code that computed them for training**. When it is
used, somebody computes the features again, often somebody else, often in another language, inside
the application that asks for the prediction. **If the two computations differ, the model gets
numbers that mean something other than what it learned**, and nothing anywhere raises an error.
That is **training-serving skew**, and it is the commonest way a good model goes quietly wrong in
production.

Here is how it happens at Ponto Final. The website team wants a lapse score on a member's page, and
they compute the features in their own service. They store money in reais, as their screens show
it, and the online share as a percentage. Every column has the right name. This program feeds the
same test members to the same saved model twice, once with this course's features and once with
theirs. Save it as `skew.py`:

```python
"""skew.py: the same model, fed features computed by somebody else's code."""
import joblib
import pandas as pd
from sklearn.metrics import roc_auc_score

from model import COLUMNS
from project import ROOT

model = joblib.load(ROOT / "models/lapse.joblib")
ours = pd.read_csv(ROOT / "data/test.csv")

# the website team's copy of the features: money in reais, shares in percent
theirs = ours.copy()
theirs["spend_180d"] = ours["spend_180d"] / 100
theirs["basket_avg"] = ours["basket_avg"] / 100
theirs["online_share"] = ours["online_share"] * 100


def top_300(rows, p):
    return set(rows.assign(p=p).nlargest(300, "p")["member_id"])


p_ours = model.predict_proba(ours[COLUMNS])[:, 1]
p_theirs = model.predict_proba(theirs[COLUMNS])[:, 1]
for name, p in (("our features", p_ours), ("their features", p_theirs)):
    print(f"{name:15} mean p {p.mean():.3f}  AUC {roc_auc_score(ours['lapsed'], p):.3f}")
shared = top_300(ours, p_ours) & top_300(theirs, p_theirs)
print(f"members in both top-300 lists: {len(shared)}")
print(f"members whose probability moved by more than 0.1: {(abs(p_ours - p_theirs) > 0.1).sum()}")
```

```
ana@dev:~/ml$ python skew.py
our features    mean p 0.177  AUC 0.793
their features  mean p 0.157  AUC 0.770
members in both top-300 lists: 281
members whose probability moved by more than 0.1: 160
```

**The model answered every member both times.** With the website's features the average probability
fell from 0.177 to 0.157, AUC fell from 0.793 to 0.770, 19 of the top 300 members were different
people, and **160 members' probabilities moved by more than 0.1.** Each of those numbers is
plausible on its own; a probability of 0.157 does not look wrong. The scaler inside the model
expected spend in cents, received reais, and shrank every member's spending a hundredfold, and the
online share went the other way.

The defence is not care, because everybody was careful. **It is having one implementation of the
features, used by both training and serving.** In this course that is `features.py`, imported by
every step, and lesson 6 turns it into a feature store that the website asks instead of computing
its own. Where two implementations cannot be avoided, the second-best defence is a test that feeds
both the same raw rows and fails if their features differ.
