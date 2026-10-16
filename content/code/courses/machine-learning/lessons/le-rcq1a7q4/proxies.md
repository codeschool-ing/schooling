---
title: The proxy you kept
version: 1
---

A proxy is a column that carries a protected characteristic without naming it. The test for one is
direct: try to predict the characteristic from the columns the model keeps. If that works, the model can
use age without being given it. Save this as `proxies.py`:

```python
# proxies.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import roc_auc_score

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

train, test = by_time(load_churn())
others = [c for c in NUMERIC if c != "age"] + CATEGORICAL

for name, older in [("65 or over", 65), ("50 or over", 50)]:
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(train[others], train["age"] >= older)
    guess = model.predict_proba(test[others])[:, 1]
    print(f"is the subscriber {name}? AUC {roc_auc_score(test['age'] >= older, guess):.3f}, "
          f"from columns that do not include age")

band = pd.cut(train["age"], [17, 24, 34, 49, 64, 99], labels=["18-24", "25-34", "35-49", "50-64", "65+"])
summary = pd.DataFrame({"app_user": train.groupby(band, observed=True)["app_user"].mean(),
                        "boleto": train.groupby(band, observed=True)["payment"]
                                       .apply(lambda p: (p == "boleto").mean())})
print(summary.round(2).T.to_string())
```

```
ana@lab:~/ml$ python proxies.py
is the subscriber 65 or over? AUC 0.872, from columns that do not include age
is the subscriber 50 or over? AUC 0.765, from columns that do not include age
age       18-24  25-34  35-49  50-64   65+
app_user   0.95   0.87   0.72   0.52  0.27
boleto     0.04   0.10   0.18   0.24  0.32
```

**Columns without age pick out the over-65s with an AUC of 0.872.** Two of them do most of the work, and
the bottom table shows them. 95% of the youngest band uses the app and 27% of the oldest; 4% of the youngest
pay by boleto and 32% of the oldest. Neither column is about age, both are reasonable things for a churn
model to read, and together they say a great deal about how old someone is.

The proxies do something more specific than that. `app_user` also decides whether `days_since_login`
exists, so a missing login is itself an age signal. And lesson 19 found that paying by boleto adds about
0.48 to the log-odds of leaving. If older subscribers leave more partly *because* they are older, a model
without age will put some of that effect on boleto, and boleto-paying subscribers of every age will be
treated as if they shared it.

There is no list of proxies to remove. In data about people, almost everything correlates with something
protected: postcode with race and income, first name with sex, shopping habits with religion, typing speed
with age. Removing every correlated column would remove the model. **The defence is measurement**: keep the
protected characteristic for auditing, print the tables of this lesson for every model that goes live, and
look again whenever the model or the data changes.
