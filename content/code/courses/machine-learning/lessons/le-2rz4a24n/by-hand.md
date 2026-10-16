---
title: What breaks when preparation is done by hand
version: 1
---

Every logistic regression in this course so far has been three or four objects held together by
the program around them: a dictionary of medians, a call to `get_dummies`, a `StandardScaler`, the
model. Each was fitted on the training rows and applied to the test rows, in the right order, by
hand. It worked, because the test rows came from the same file, read the same way, a few lines
later.

Now use the model on new data. In 2026 Feira em Casa exports `churn_2026.csv`, three new months of
subscribers in the same format, and the retention team wants their chances. Lesson 5's model is
fitted exactly as before and then asked about the new file. Save this as `by_hand.py`:

```python
# by_hand.py
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

train, _ = by_time(load_churn())
new = load_churn("data/churn_2026.csv")
medians = train[NUMERIC].median()

def table(rows):
    numbers = rows[NUMERIC].fillna(medians)
    words = pd.get_dummies(rows[CATEGORICAL], drop_first=True, dtype=float)
    return pd.concat([numbers, words], axis=1)

scale = StandardScaler().fit(table(train))
model = LogisticRegression(max_iter=1000).fit(scale.transform(table(train)), train["churned"])
print(f"churn_2026.csv: {len(new):,} rows; plans {sorted(new['plan'].unique())}")
chance = model.predict_proba(scale.transform(table(new)))[:, 1]
```

```
ana@lab:~/ml$ python by_hand.py
churn_2026.csv: 13,154 rows; plans ['fortnightly', 'monthly', 'weekly']
Traceback (most recent call last):
  File "/home/ana/ml/by_hand.py", line 20, in <module>
    chance = model.predict_proba(scale.transform(table(new)))[:, 1]
                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/sklearn/utils/_set_output.py", line 327, in wrapped
    data_to_wrap = f(self, X, *args, **kwargs)
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/sklearn/preprocessing/_data.py", line 1111, in transform
    X = validate_data(
        ^^^^^^^^^^^^^^
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/sklearn/utils/validation.py", line 3016, in validate_data
    _check_feature_names(_estimator, X, reset=reset)
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/sklearn/utils/validation.py", line 2868, in _check_feature_names
    raise ValueError(message)
ValueError: The feature names should match those that were passed during fit.
Feature names unseen at fit time:
- plan_monthly
```

The new file has a plan the old one never had, **monthly**, launched in 2026. `get_dummies` makes
columns from whatever values the table in front of it contains, so on the new file it made one more,
`plan_monthly`, and the scaler, which remembers the 22 columns it was fitted on, refused the 23rd.
Read the last line of the error, as lesson 1 said: it names the column.

The error is the good outcome. Worse ones are easy to arrange with the same code:

- If the new file had **lost** a value instead, say no subscriber on boleto that month, `get_dummies`
  would make one column fewer and the columns after it would shift. Without the names to check, a
  model fed plain arrays would read `plan_weekly` where it expects `payment_pix`, and say nothing.
- The medians live in a variable. A program that recomputes them from the new file, which is one
  careless line, gives the new rows a different fill from the one the model learned with.
- Lesson 14's seven columns would have to be rebuilt in exactly the same way, by whatever program
  scores the new file, and kept in step with the training program for as long as the model is used.

All three have one cause. **The preparation is part of the model**, and it lives outside it. The rest
of this lesson puts it inside, so that fitting the model fits the preparation, and using the model
applies it, the same way every time and on any rows.
