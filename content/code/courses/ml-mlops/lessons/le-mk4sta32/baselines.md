---
title: Every score needs something to beat
version: 1
---

R$ 179.49 of error sounds bad for members who spend a few hundred reais, and a lapse model that
flags the right members sounds good. **Neither sentence means anything until it says compared with
what.** The comparison that always exists is the **baseline**: the dumbest prediction that uses no
features at all.

| task | the baseline |
| --- | --- |
| classification | always predict the commonest class |
| regression | always predict the average of the training label |
| recommendation | recommend the most popular titles the member does not own |

scikit-learn has the first two as models of their own, so they go through the same `fit` and
`predict` as the real ones. Save this as `baseline.py`; it imports `examples` from `regress.py`:

```python
"""baseline.py: what the two models are worth against guessing."""
from sklearn.dummy import DummyClassifier, DummyRegressor
from sklearn.metrics import mean_absolute_error

import features
from regress import examples

train, test = examples("2025-09-30"), examples("2025-11-30")
X = features.NUMERIC

always_stays = DummyClassifier(strategy="most_frequent").fit(train[X], train["lapsed"])
print("always 'stays' predicts lapsed for", int(always_stays.predict(test[X]).sum()), "members")

average = DummyRegressor(strategy="mean").fit(train[X], train["spend_next_90d"])
guess = average.predict(test[X])
print(f"everybody spends the average: R$ {guess[0] / 100:.2f} each")
print(f"mean absolute error: R$ {mean_absolute_error(test['spend_next_90d'], guess) / 100:.2f}")
```

```
ana@dev:~/ml$ python baseline.py
always 'stays' predicts lapsed for 0 members
everybody spends the average: R$ 304.01 each
mean absolute error: R$ 213.76
```

**"Always stays" predicts that nobody lapses**, because most members do not: a model with no
information at all, and lesson 4 will show it scoring 83% on the most common measure there is.
That is the trap that lesson is named for.

**"Everybody spends the average" is wrong by R$ 213.76 a member.** The regression was wrong by
R$ 179.49, so the features bought an improvement of R$ 34.27, about a sixth. That is the honest
size of what the model knows, and it is the number to put in front of whoever asked for it.

## Why the baseline is the platform's business

A modeller computes it once, while choosing a model. **The platform has to keep computing it**,
because a baseline moves too: if most members started lapsing, "always stays" would get worse and a
model could look better while knowing less. Lesson 9 tracks a model's score in production, and the
number it tracks is always a pair: the model, and the baseline on the same rows.
