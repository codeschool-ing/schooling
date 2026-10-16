---
title: The split that respects time
version: 1
---

Everything above shuffles the rows before cutting them, and shuffling has an assumption inside it:
**that the order of the rows carries no information.** For Feira em Casa it carries a great deal.
The model will be used on 1 January 2026 to score January, having learned from everything before.
A shuffled split instead lets it learn from September to judge August, and the future leaks in.

What leaks is not a column but a world. In September 2025 every box became 12% dearer and more
people cancelled. A model that has seen September has learned what the price rise did; on
1 January it would have, legitimately, but on the first of every earlier month it could not have.
Save this as `time_split.py`:

```python
# time_split.py
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.model_selection import train_test_split

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

churn = load_churn()
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)


def judged(learn, check):
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(learn[features], learn["churned"])
    send = model.predict_proba(check[features])[:, 1] >= cut
    return net_value(check["churned"], send) / len(check) * 1000


learn, check = by_time(churn)
print(f"learn before July, judge July-December:   R$ {judged(learn, check):5.0f} per 1,000 rows")

learn, rest = train_test_split(churn, test_size=0.3, random_state=0)
check = rest[rest["snapshot"] >= "2025-07-01"]
print(f"learn from a random 70% of all 18 months: R$ {judged(learn, check):5.0f} per 1,000 rows")
```

```
ana@lab:~/ml$ python time_split.py
learn before July, judge July-December:   R$   893 per 1,000 rows
learn from a random 70% of all 18 months: R$  1007 per 1,000 rows
```

**The same model and the same test months, R$ 893 against R$ 1,007 per thousand rows.** The random
split is 13% more optimistic, and none of that 13% would be there on the day the model is used.
Neither number is the model being better or worse; one is a measurement of the situation the model
will be in, and the other is not.

## Walking forward through time

A time split can also be repeated, which is cross-validation's idea adapted to an arrow: for each
month, learn from everything before it and score that month. scikit-learn's `TimeSeriesSplit` does
the cutting for evenly spaced rows; for monthly snapshots the loop is clearer written out. Save this
as `walk_forward.py`:

```python
# walk_forward.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, load_churn, net_value

churn = load_churn()
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)

print("month       learned from  leavers  R$ per 1,000 rows")
for month in pd.date_range("2025-01-01", "2025-12-01", freq="MS"):
    learn = churn[churn["snapshot"] < month]          # everything known before it
    check = churn[churn["snapshot"] == month]
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(learn[features], learn["churned"])
    send = model.predict_proba(check[features])[:, 1] >= cut
    value = net_value(check["churned"], send) / len(check) * 1000
    print(f"{month:%Y-%m}     {len(learn):>10,}  {check['churned'].mean():6.1%}  {value:10.0f}")
```

```
ana@lab:~/ml$ python walk_forward.py
month       learned from  leavers  R$ per 1,000 rows
2025-01         17,931    5.8%         755
2025-02         21,122    5.5%         568
2025-03         24,415    5.2%         367
2025-04         27,797    5.0%         395
2025-05         31,300    5.5%         643
2025-06         34,906    4.9%         589
2025-07         38,628    4.7%         530
2025-08         42,461    5.0%         495
2025-09         46,423    7.2%        1182
2025-10         50,504    6.9%        1064
2025-11         54,602    6.9%         946
2025-12         58,739    6.0%        1127
```

Read the last column down. The model's value per thousand rows moves between R$ 367 and R$ 1,182
from month to month, and the jump is in **September**, when the leavers' share rose from 5.0% to
7.2%. More leavers means more credits worth sending, so the same model was worth twice as much in
the months after the price rise. A single random split averages all of this into one number and
hides it.

Two conclusions, and both are used for the rest of the course:

- **Score by time when the model will be used forward in time.** That is nearly every model a
  business deploys. A random split answers a question nobody will ask.
- **Expect the score to move with the world.** The walk-forward table is a preview of lesson 22,
  where the model meets 2026 and the world has moved again.
