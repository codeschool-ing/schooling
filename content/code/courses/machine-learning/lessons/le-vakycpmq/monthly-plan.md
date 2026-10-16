---
title: Why the monthly plan looks risky
version: 1
---

Lesson 15 scored `churn_2026.csv` and found the new monthly plan's subscribers at a chance of about 0.11,
against 0.05 and 0.07 for the other plans, and left the question of why to this lesson. Lesson 15's model
is a logistic regression, so the question has an exact answer: each column's **contribution** to a
subscriber's log-odds is its prepared value times its weight, and comparing the average contributions of
monthly subscribers with everyone else's shows which columns make the difference. Save this as
`monthly.py`:

```python
# monthly.py
import pandas as pd

from churn_model import build
from feira import load_churn

history = load_churn()
new = load_churn("data/churn_2026.csv")
model = build().fit(history, history["churned"])
prepared = model[:-1].transform(new)
weights = model.named_steps["logistic"].coef_[0]
contribution = pd.DataFrame(prepared.toarray() * weights if hasattr(prepared, "toarray")
                            else prepared * weights,
                            columns=model.named_steps["prepare"].get_feature_names_out())

monthly = (new["plan"] == "monthly").to_numpy()
gap = contribution[monthly].mean() - contribution[~monthly].mean()
print(f"{monthly.sum()} monthly subscribers against {(~monthly).sum():,} on the other plans")
print("columns that push the monthly plan's chances up, in log-odds:")
print(gap.sort_values(ascending=False).head(5).round(2).to_string())
print(f"all columns together: {gap.sum():+.2f}")
```

`model[:-1]` is the pipeline without its last step, so `transform` gives the 36 prepared columns the
logistic regression reads. The encoder may return them as a sparse table, and `toarray` makes it an
ordinary one.

```
ana@lab:~/ml$ python monthly.py
496 monthly subscribers against 12,658 on the other plans
columns that push the monthly plan's chances up, in log-odds:
numbers__tenure_capped                  0.67
words__plan_weekly                      0.36
words__plan_fortnightly                 0.28
numbers__missingindicator_rating_90d    0.10
numbers__rating_90d                     0.09
all columns together: +0.94
```

Two different reasons, and only one of them is about the subscribers.

**`tenure_capped`, +0.67, is real.** Monthly subscribers joined in 2026, so every one of them has a
short tenure, and short tenure is one of the strongest signals of leaving the model has. That part of the
risk would hold for any new joiner on any plan.

**`plan_weekly` and `plan_fortnightly`, +0.36 and +0.28, are an artefact.** Every subscriber on a known
plan gets one of those two weights, both negative, as the payment weights were in the first section.
A monthly subscriber gets zeros in both, as lesson 14's `handle_unknown="ignore"` arranged, so they
miss a negative weight that everyone else receives. The model is not saying the monthly plan is risky.
It has never seen the monthly plan, and *"neither of the plans I know"* happens to sit at the intercept,
above both known plans.

So of the +0.94 that separates the two groups, about two thirds comes from a plan the model knows nothing
about being read as a value it never learned. That is worth saying to the retention team before they send
monthly subscribers credits they may not need, and it is the strongest argument there is for **refitting
once the new plan has a few months of labels**, which lesson 22 does.
