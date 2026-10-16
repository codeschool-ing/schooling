---
title: The churn model as one object
version: 1
---

Lesson 14's best logistic regression has three stages: add the seven columns, prepare numbers and words
differently, fit the model. As a pipeline it lives in one file, which every later program imports,
the way `feira.py` and `tuning.py` are imported. Save this as `churn_model.py`:

```schooling-example
{
  "language": "python",
  "file": "churn_model.py",
  "parts": [
    {
      "code": "# churn_model.py\n\"\"\"Lesson 14's logistic regression, as one object that can be fitted and used anywhere.\"\"\"\nfrom sklearn.compose import ColumnTransformer\nfrom sklearn.impute import SimpleImputer\nfrom sklearn.linear_model import LogisticRegression\nfrom sklearn.pipeline import Pipeline, make_pipeline\nfrom sklearn.preprocessing import FunctionTransformer, OneHotEncoder, StandardScaler\n\nfrom feira import CATEGORICAL, NUMERIC\n",
      "note": "The third shared file of the course, after `feira.py` and `tuning.py`: the whole churn model as one object."
    },
    {
      "code": "SHAPES = [\"unhappy\", \"skip_streak\", \"gone_quiet\", \"young\", \"tenure_capped\", \"box_price\",\n          \"late_and_new\"]\n\ndef add_shapes(rows):\n    rows = rows.copy()\n    rows[\"unhappy\"] = (rows[\"rating_90d\"] < 3.6).astype(float)\n    rows[\"skip_streak\"] = (rows[\"skips_90d\"] >= 3).astype(float)\n    rows[\"gone_quiet\"] = (rows[\"days_since_login\"] > 21).astype(float)\n    rows[\"young\"] = (rows[\"age\"] < 25).astype(float)\n    rows[\"tenure_capped\"] = rows[\"tenure_months\"].clip(upper=24)\n    boxes = rows[\"plan\"].astype(str).map({\"weekly\": 4, \"fortnightly\": 2, \"monthly\": 1})\n    rows[\"box_price\"] = rows[\"price_month\"] / boxes\n    rows[\"late_and_new\"] = rows[\"late_90d\"] * (rows[\"tenure_months\"] < 6)\n    return rows\n",
      "note": "**Lesson 14's seven columns**, now a function from a table to a table. It learns nothing from the data, every threshold is written here, so it is safe to run on any rows."
    },
    {
      "code": "\ndef build(C=1.0):\n    numbers = make_pipeline(SimpleImputer(strategy=\"median\", add_indicator=True), StandardScaler())",
      "note": "**The numbers** get the training median where they have a gap, a column saying the gap was there, and the scaler. `make_pipeline` names its steps after their classes."
    },
    {
      "code": "    words = OneHotEncoder(handle_unknown=\"ignore\")",
      "note": "**The words** become one-hot columns, and a value never seen in training becomes zeros instead of an error: the monthly plan of 2026."
    },
    {
      "code": "    prepare = ColumnTransformer([(\"numbers\", numbers, NUMERIC + SHAPES),\n                                 (\"words\", words, CATEGORICAL)])",
      "note": "**`ColumnTransformer` sends each list of columns to its own treatment** and puts the results side by side. Columns it is not told about are dropped, which is how `churned`, `customer_id` and the two leaky columns of lesson 4 stay out."
    },
    {
      "code": "    return Pipeline([(\"shapes\", FunctionTransformer(add_shapes)),\n                     (\"prepare\", prepare),\n                     (\"logistic\", LogisticRegression(C=C, max_iter=2000))])",
      "note": "**The pipeline is the three steps in order**, with names. `fit` runs each step's `fit` on the training rows and passes the result on; `predict_proba` runs each step's `transform` and then the model."
    }
  ]
}
```

Then fit it and score the test months. Save this as `pipeline.py`:

```python
# pipeline.py
from sklearn.metrics import roc_auc_score

from churn_model import build
from feira import CREDIT, KEPT, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
model = build().fit(train, train["churned"])
chance = model.predict_proba(test)[:, 1]
print("steps:", " -> ".join(model.named_steps))
columns = model.named_steps["prepare"].get_feature_names_out()
print(f"{len(columns)} columns reach the logistic regression, from {columns[0]} to {columns[-1]}")
print(f"test months: AUC {roc_auc_score(test['churned'], chance):.3f}, "
      f"net value R$ {net_value(test['churned'], chance >= CREDIT / (SAVED * KEPT)):,.0f}")
```

**The pipeline is given the raw table**, `train` and `test` as `load_churn` returns them, with every
column including `churned`. Nothing is prepared outside it.

```
ana@lab:~/ml$ python pipeline.py
steps: shapes -> prepare -> logistic
36 columns reach the logistic regression, from numbers__age to words__channel_referral
test months: AUC 0.818, net value R$ 22,184
```

AUC 0.818, as in lesson 14. The net value is R$ 22,184 rather than R$ 22,712, and the difference has
a cause: `OneHotEncoder` keeps every value as a column, where `get_dummies` dropped the first of each. Two tables that are
nearly the same give a logistic regression two slightly different problems. It is a small reminder that
**rebuilding preparation is itself a change to the model**, and the pipeline is now the version that is
measured, used and kept.

The 36 columns have names, `numbers__age` to `words__channel_referral`, built from the step names, so
the weights in lesson 5's style can still be read off: `model.named_steps["logistic"].coef_` holds them
in the same order. Lesson 19 reads a model this way.
