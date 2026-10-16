---
title: What can be checked on the day
version: 1
---

On the first of the month, the model's answers cannot be graded: nobody has left yet. What can be
checked is the input. The model learned from a population, and if this month's subscribers look
different from that population, its chances are being applied somewhere it has not been. That is
**data drift**: the inputs change.

The usual measure for one column is the **population stability index**. Cut the training values into
ten bins of equal count, see what share of this month's values falls in each, and add up how far each
share moved, weighted by how surprising the move is. It is 0 for a column that has not moved; by a rule
of thumb used widely in credit scoring, under 0.1 is stable, 0.1 to 0.25 is worth a look and above 0.25
is a large shift. For a word column the bins are its values. Save this as `inputs.py`:

```python
# inputs.py
import numpy as np
import pandas as pd

import stored
from feira import CATEGORICAL, NUMERIC, load_churn


def stability(before, after, bins=10):
    """Population stability index: how far a column has moved, 0 when not at all."""
    if before.dtype == "category":
        was = before.astype(str).value_counts(normalize=True)
        now = after.astype(str).value_counts(normalize=True)
        was, now = was.align(now, fill_value=0)
    else:
        before, after = before.dropna(), after.dropna()
        edges = np.unique(before.quantile(np.linspace(0, 1, bins + 1)))
        edges[0], edges[-1] = -np.inf, np.inf
        was = np.histogram(before, edges)[0] / len(before)
        now = np.histogram(after, edges)[0] / len(after)
    was, now = np.clip(was, 1e-4, None), np.clip(now, 1e-4, None)
    return float(np.sum((now - was) * np.log(now / was)))


_, card = stored.load("churn-2025-12")
train = load_churn(card["data"])
new = load_churn("data/churn_2026.csv")
months = {str(m.date())[:7]: rows for m, rows in new.groupby("snapshot")}

table = pd.DataFrame({m: {c: stability(train[c], rows[c]) for c in NUMERIC + CATEGORICAL}
                      for m, rows in months.items()})
print("stability index against the training rows (above 0.25 is a large shift):")
print(table.round(3).to_string())

for col in CATEGORICAL:
    unseen = {m: rows[col][~rows[col].isin(train[col].unique())] for m, rows in months.items()}
    for m, values in unseen.items():
        if len(values):
            print(f"{m}: {col} = {', '.join(values.unique())} in {len(values) / len(months[m]):.1%} of rows,"
                  f" never seen in training")
```

The training rows come from the card: `card["data"]` is the file the model learned from, which is one
more reason lesson 21 wrote it down. The `1e-4` keeps an empty bin from becoming a division by zero, and
it is why a value never seen before scores high rather than infinite.

```
ana@lab:~/ml$ python inputs.py
stability index against the training rows (above 0.25 is a large shift):
                   2026-01  2026-02  2026-03
age                  0.003    0.002    0.002
app_user             0.000    0.000    0.000
tenure_months        0.144    0.161    0.173
price_month          0.622    0.620    0.636
orders_90d           0.004    0.011    0.042
skips_90d            0.001    0.004    0.005
late_90d             0.002    0.002    0.002
complaints_90d       0.000    0.000    0.000
support_calls_90d    0.000    0.000    0.000
rating_90d           0.020    0.017    0.019
days_since_login     0.003    0.003    0.003
city                 0.001    0.001    0.001
payment              0.001    0.001    0.002
plan                 0.001    0.240    0.472
box                  0.000    0.000    0.001
channel              0.000    0.000    0.000
2026-02: plan = monthly in 4.0% of rows, never seen in training
2026-03: plan = monthly in 7.1% of rows, never seen in training
```

Three things moved, and each needs a person to say whether it matters:

- **`plan` jumps from 0.001 to 0.240 to 0.472**, and the last two lines say why: a plan the model has
  never seen, 4.0% of February and 7.1% of March. This is the one to act on. Lesson 15's encoder gives it
  zeros, lesson 19 showed that zeros make its chances partly an artefact, and a share that nearly doubled in a month is a share that will matter.
- **`price_month` is above 0.6 in every month.** That is September's price rise: most of the training
  rows are from before it, and every 2026 price is 12% higher. The index is right, and the alarm is old
  news. An alarm that has been ringing since September will be ignored by December, which is the case for
  measuring against **recent** months as well as against the training rows.
- **`tenure_months` sits at 0.14 to 0.17**, worth a look and no more: the business is growing, so each
  month has a few more new subscribers than the training months had.

And one thing did not move, which matters as much: **`city` is at 0.001.** The same share of
subscribers lives in each city as always. Keep that in mind for two sections.

Input checks also cover what this table cannot show: a column that is suddenly all missing, a value
that is impossible, a file with half the usual rows. Those are bugs in the road in, lesson 21's skew
again, and they are the most common thing a monthly check finds.
