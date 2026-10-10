---
title: Classification, and the probability underneath it
version: 1
---

**Classification answers with a category.** Lapsed or not is the smallest case, two classes, and
it is called **binary**. A model that reads a support ticket and answers *delivery*, *payment* or
*refund* is **multi-class**, and nothing in this section changes for it except that there are three
probabilities instead of two.

Lesson 1's model read three numeric columns. This one reads all ten that `features.py` builds,
including the three that are words, and that changes what the program has to be. Save it as
`classify.py`:

```python
"""classify.py: the lapse model with every feature, categories included."""
from sklearn.compose import make_column_transformer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

import features

train = features.build("2025-09-30")
test = features.build("2025-11-30")
X = features.NUMERIC + features.CATEGORICAL

model = make_pipeline(
    make_column_transformer(
        (StandardScaler(), features.NUMERIC),
        (OneHotEncoder(handle_unknown="ignore"), features.CATEGORICAL),
    ),
    LogisticRegression(max_iter=1000),
)
model.fit(train[X], train["lapsed"])

test["p_lapse"] = model.predict_proba(test[X])[:, 1]
test["predicted"] = model.predict(test[X])
print(test[["member_id", "channel", "recency_days", "p_lapse", "predicted", "lapsed"]]
      .head(4).round(3).to_string(index=False))
print("predicted to lapse:", int(test["predicted"].sum()), "of", len(test))
print("actually lapsed:   ", int(test["lapsed"].sum()), "of", len(test))
```

**`make_pipeline` chains the steps into one object**, and that object is the model. Its first step
is a `ColumnTransformer` that treats the columns differently: it scales the seven numeric ones, as
lesson 1 did for k-means, and turns the three categorical ones into numbers in a way the next
section explains. The second step is the same logistic regression. **`fit` runs both steps on the
training rows, and `predict_proba` runs both on new rows**, so the scaling learned from September is
the scaling applied in November. Lesson 6 comes back to why that matters more than it looks.

```
ana@dev:~/ml$ python classify.py
 member_id channel  recency_days  p_lapse  predicted  lapsed
         1   store          17.0    0.129          0       0
         2   store           0.0    0.087          0       0
         3   store          11.0    0.121          0       0
         7   store          14.0    0.068          0       0
predicted to lapse: 248 of 3130
actually lapsed:    530 of 3130
```

## Two answers from one model

The model gives two things for each member, and they are easy to confuse.

`predict_proba` gives the **probability**: member 1 has a 0.129 chance of lapsing. `predict` gives
the **class**, which is that probability compared with **0.5**: 0.129 is below, so the class is 0.
The threshold is a default written into scikit-learn, not something the model learned.

**And at 0.5 the model calls 248 members lapsed, while 530 actually lapsed.** Much of that gap is the
threshold rather than the model: a threshold chosen for nobody's question. A member with a 0.4
chance of lapsing is somebody marketing would happily send a voucher to, and the default threshold
calls them "stays". Lesson 4 chooses the threshold from what a voucher costs and what a lost member
costs, which is the only honest way to choose one.

**This is the first thing to agree with a modeller about: which of the two you store.** Store the
class, and the threshold is frozen into every row, so changing it means rescoring everybody. Store
the probability, and the threshold is a parameter of whoever reads the table. The platform stores
the probability.
