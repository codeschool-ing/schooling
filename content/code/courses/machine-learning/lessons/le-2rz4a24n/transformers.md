---
title: Transformers, and the contract they keep
version: 1
---

scikit-learn has two kinds of object, and they keep the same two-step contract.

- An **estimator that predicts**, such as `LogisticRegression`, learns from rows in `fit`, and then
  answers with `predict` or `predict_proba`.
- A **transformer**, such as `StandardScaler`, `SimpleImputer` or `OneHotEncoder`, learns from rows in
  `fit`, and then changes rows with `transform`.

**Whatever is learned is learned in `fit`, and only there.** A scaler's means, an imputer's medians, an
encoder's list of categories: all of them are stored on the object, with names ending in an underscore,
and `transform` only reads them. That is the whole guarantee, and it is easy to see. Save this as
`contract.py`:

```python
# contract.py
import pandas as pd
from sklearn.impute import SimpleImputer

from feira import by_time, load_churn

train, test = by_time(load_churn())
imputer = SimpleImputer(strategy="median")
imputer.fit(train[["rating_90d"]])
print(f"fit: the median of the training rows is {imputer.statistics_[0]}")
filled = imputer.transform(test[["rating_90d"]])
print(f"transform: {test['rating_90d'].isna().sum():,} test rows had no rating; "
      f"afterwards {pd.isna(filled).sum()} have none")
```

```
ana@lab:~/ml$ python contract.py
fit: the median of the training rows is 4.2
transform: 1,872 test rows had no rating; afterwards 0 have none
```

The imputer learned 4.2 from the training rows and filled the test rows' gaps with it. Calling
`transform` on another thousand rows, next year, fills them with 4.2 again. That is the property the
dictionary of medians in `by_hand.py` had only by the programmer's care.

`fit_transform` does both at once, and is only ever called on the rows being learned from. A call to
`fit_transform` on test rows is lesson 4's preparation leak in one line, and it is the commonest way to
make it.

Two more transformers complete the toolkit:

- **`FunctionTransformer`** wraps any function from a table to a table. It learns nothing, which makes it
  right for lesson 14's flags, whose thresholds are written down, and wrong for anything computed from
  the data, such as a median.
- **`ColumnTransformer`** sends different columns to different transformers, numbers to one, words to
  another, and puts the results side by side. Columns not named in it are dropped.

A **pipeline** chains transformers and ends with a model, and it is itself an estimator: `fit` fits
every step in order, each on the output of the one before, and `predict_proba` runs every step's
`transform` and then the model. The next section builds one.
