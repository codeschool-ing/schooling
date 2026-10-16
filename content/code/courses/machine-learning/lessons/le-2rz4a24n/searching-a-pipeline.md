---
title: Tuning a pipeline, without the leak
version: 1
---

A pipeline is an estimator, so lesson 9's search takes it whole. Two things change, and both are
improvements.

**The preparation is refitted inside every fold.** When `GridSearchCV` fits a candidate on the months
before May and scores it on May, it fits the whole pipeline on the earlier months: the medians, the
scaler's means, the encoder's categories, all from those months alone. Lesson 4's preparation leak,
and lesson 13's resampling leak, cannot happen, because there is nothing outside the pipeline to fit
on the wrong rows.

**A setting deep inside is named by its path.** The logistic regression's `C`, lesson 5's strength of
regularisation, is `logistic__C`: the step's name, two underscores, the setting. An imputer's strategy
would be `prepare__numbers__simpleimputer__strategy`. Long, and unambiguous.

Save this as `search.py`; it uses lesson 9's folds and score from `tuning.py`:

```python
# search.py
from sklearn.model_selection import GridSearchCV

from churn_model import build
from feira import by_time, load_churn
from tuning import time_folds, value_per_thousand

train, _ = by_time(load_churn())
search = GridSearchCV(build(), {"logistic__C": [0.01, 0.1, 1, 10]},
                      cv=list(time_folds(train)), scoring=value_per_thousand)
search.fit(train, train["churned"])
for C, score in zip(search.cv_results_["param_logistic__C"], search.cv_results_["mean_test_score"]):
    print(f"C = {C:<5}  R$ {score:5.0f} per thousand rows, averaged over three months")
```

`value_per_thousand` asks the model for `predict_proba`, and the pipeline answers it, so the scorer
written for gradient boosting in lesson 9 works unchanged on a different model.

```
ana@lab:~/ml$ python search.py
C = 0.01   R$   868 per thousand rows, averaged over three months
C = 0.1    R$   915 per thousand rows, averaged over three months
C = 1.0    R$   917 per thousand rows, averaged over three months
C = 10.0   R$   917 per thousand rows, averaged over three months
```

From C = 0.1 up the score is flat, R$ 915 to R$ 917 per thousand rows: the default of 1 is as good as
any. Only the strongest regularisation, 0.01, costs something. With 36 columns and 38,628 rows, there
is little for regularisation to protect against. That is lesson 9's conclusion again, from another
model: once the features are right, the dials matter less than the time spent on them suggests.
