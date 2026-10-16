---
title: The same result, twice
version: 1
---

A result that cannot be produced again cannot be checked, compared or trusted. Three things decide
whether a model fitted today can be fitted again next month and give the same answer: the data, the
randomness and the versions. The data is `make_data.py` and its fingerprints from lesson 1. The other
two are this section.

**Randomness hides in more places than it seems.** Every model in this course passes
`random_state=0`, and here is why. Save this as `seeds.py`; it fits lesson 2's gradient boosting four
times, twice without a seed and twice with one:

```python
# seeds.py
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
for seed in [None, None, 0, 0]:
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=seed)
    model.fit(train[features], train["churned"])
    send = model.predict_proba(test[features])[:, 1] >= CREDIT / (SAVED * KEPT)
    print(f"random_state={seed!s:4}  {model.n_iter_:3} trees  R$ {net_value(test['churned'], send):,.0f}")
```

```
ana@lab:~/ml$ python seeds.py
random_state=None   38 trees  R$ 21,120
random_state=None   41 trees  R$ 21,152
random_state=0      40 trees  R$ 21,672
random_state=0      40 trees  R$ 21,672
```

Nothing in the call says *random*, and yet two identical calls gave different models. With more than
ten thousand rows, `HistGradientBoostingClassifier` turns on lesson 8's early stopping by itself, and
early stopping sets aside a random tenth of the rows to decide when to stop. A different tenth, a
different number of trees, a different result: 38 trees and 41 here, R$ 21,120 and R$ 21,152. While this
lesson was being written, another pair of unseeded runs came out R$ 1,464 apart. Your own two lines will
almost certainly differ from these and from each other, which is the point. **With `random_state=0` the model is the same every
time**, and the same as every earlier lesson's R$ 21,672.

That is the other reason to fix the seed: a comparison between two settings is only a comparison if nothing else changed between the two
fits.

**The versions are the third thing.** A new release of scikit-learn can change a default, the number of
bins in a histogram, the solver of a logistic regression, and a changed default changes a number. That is
why lesson 1 pinned every library in `requirements.txt`, and why each lesson's capture script records the
versions it ran with. For a model that will be used, keep three things with it:

- the **pinned versions**, `requirements.txt` or the output of `pip freeze`;
- the **code that built it**, `churn_model.py`, at the commit that fitted it;
- the **data it learned from**, or a fingerprint of it, as lesson 1's `sha256sum` printed.

Lesson 21 saves the fitted pipeline to a file, and that file is only as useful as the record of which
code, which data and which versions produced it.
