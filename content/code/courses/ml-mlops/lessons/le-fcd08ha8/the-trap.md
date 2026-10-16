---
title: The accuracy trap
version: 1
---

**Accuracy is the share of predictions that are right**, and it is the first score anybody asks for
because it needs no explaining. For the lapse model it is also nearly useless, and the reason is
one number from lesson 2: most members do not lapse.

Every program in this lesson trains the same model, so it is defined once. Save this as `model.py`:

```python
"""model.py: the lapse model, defined once, for every program that trains it."""
from sklearn.compose import make_column_transformer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

import features

COLUMNS = features.NUMERIC + features.CATEGORICAL


def make_model():
    return make_pipeline(
        make_column_transformer(
            (StandardScaler(), features.NUMERIC),
            (OneHotEncoder(handle_unknown="ignore"), features.CATEGORICAL),
        ),
        LogisticRegression(max_iter=1000),
    )


def trained(cutoff):
    rows = features.build(cutoff)
    return make_model().fit(rows[COLUMNS], rows["lapsed"])
```

`make_model` is lesson 2's pipeline: scaling, one-hot encoding and logistic regression. `trained`
builds the examples for a cutoff and fits a model to them. From here on, a program that needs the
lapse model imports it, and **the model has one definition in the project instead of one per
program**, which lesson 5 depends on.

Now the score. Save this as `accuracy.py`:

```python
"""accuracy.py: the lapse model's accuracy, and a model that knows nothing."""
from sklearn.metrics import accuracy_score

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")

predicted = lapse.predict(test[COLUMNS])
nobody = [0] * len(test)                       # "every member stays"

print(f"members in the test:      {len(test)}")
print(f"of whom lapsed:           {test['lapsed'].sum()} ({test['lapsed'].mean():.1%})")
print(f"accuracy, lapse model:    {accuracy_score(test['lapsed'], predicted):.1%}")
print(f"accuracy, 'nobody lapses': {accuracy_score(test['lapsed'], nobody):.1%}")
```

```
ana@dev:~/ml$ python accuracy.py
members in the test:      3130
of whom lapsed:           530 (16.9%)
accuracy, lapse model:    86.0%
accuracy, 'nobody lapses': 83.1%
```

**86.0% sounds like a model. 83.1% is a model that knows nothing**: it says every member stays, and
it is right about every member who stayed, which is most of them. Everything the lapse model learned
from ten features is worth 2.9 points of accuracy, and a manager shown 86% would never guess that.

The trap is general. Whenever one outcome is much commoner than the other, **accuracy measures
mostly how common the common outcome is.** Fraud is rarer than lapsing, and a fraud model that
never flags anything scores 99.9% on most payment data. The rarer the thing you care about, the
more accuracy rewards ignoring it.

What replaces it depends on what the model is for, and that takes the answers apart: not right or
wrong, but **right or wrong in which direction**.
