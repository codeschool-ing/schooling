---
title: Refitting, and what it fixes
version: 1
---

On the first of March, January and February have labels. That is 8,614 more rows, including 174 on the
monthly plan, and enough to try the obvious response: fit lesson 15's pipeline again on everything known,
save it beside the old one, and compare the two on March, which neither has seen. Save this as
`refit.py`:

```python
# refit.py
import pandas as pd
from sklearn.metrics import roc_auc_score

import stored
from churn_model import build
from feira import CREDIT, KEPT, SAVED, load_churn, net_value

labels = pd.read_csv("data/churn_2026_labels.csv")
known = pd.read_csv("data/churn_2026.csv").merge(labels, on=["customer_id", "snapshot"])
earlier = pd.read_csv("data/churn.csv").drop(columns="cancel_reason")
pd.concat([earlier, known[known["snapshot"] < "2026-03-01"]]).to_csv("train_2026-02.csv", index=False)
history = load_churn("train_2026-02.csv")
stored.save(build().fit(history, history["churned"]), "churn-2026-02", "train_2026-02.csv", history)

march = load_churn("data/churn_2026.csv").merge(labels.astype({"snapshot": "datetime64[s]"}))
march = march[march["snapshot"] == "2026-03-01"]
left = march["churned"]
monthly = march["plan"] == "monthly"
rival = march["city"].isin(["Curitiba", "Belo Horizonte"])
print(f"March 2026: {len(march):,} subscribers")
print("model          AUC    chance  monthly plan  Curitiba + BH  credits  net value")
for name in ["churn-2025-12", "churn-2026-02"]:
    model, _ = stored.load(name)
    chance = pd.Series(model.predict_proba(march)[:, 1], index=march.index)
    send = chance >= CREDIT / (SAVED * KEPT)
    print(f"{name}  {roc_auc_score(left, chance):.3f}  {chance.mean():.3f}  {chance[monthly].mean():12.3f}"
          f"  {chance[rival].mean():13.3f}  {send.sum():7}  R$ {net_value(left, send):,.0f}")
print(f"what happened         {left.mean():.3f}  {left[monthly].mean():12.3f}  {left[rival].mean():13.3f}")
```

The training table is written to `train_2026-02.csv` before it is used, so the new card's fingerprint
is of exactly the rows the model learned from. `cancel_reason` is dropped because the 2026 rows do not
have it, and lesson 4 already showed it must never reach a model. The new model gets a new name,
**`churn-2026-02`**, and the old file is untouched: if the new one turns out worse, going back is
loading a different name.

```
ana@lab:~/ml$ python refit.py
March 2026: 4,540 subscribers
model          AUC    chance  monthly plan  Curitiba + BH  credits  net value
churn-2025-12  0.788  0.065         0.106          0.058      180  R$ 1,296
churn-2026-02  0.790  0.058         0.070          0.054      157  R$ 2,072
what happened         0.056         0.068          0.073
```

Read it column by column, against the last row.

- **AUC barely moved**, 0.788 to 0.790. The ranking was never the problem.
- **The overall level is fixed**: 0.058 against 0.056 that left. Two months of calmer data pulled it
  down.
- **The monthly plan is fixed**: 0.070 against 0.068. With 174 labelled rows it has a column of its own,
  and the artefact is gone.
- **Curitiba and Belo Horizonte are not**, and are now further off: 0.054 against 0.073. Two months of a
  competitor are a small part of twenty months of history in which those cities behaved like the
  others, and the overall level came down for everybody, them included.
- **The credits earned more**, R$ 2,072 against R$ 1,296, with 23 fewer sent. That is one month, and lesson
  2's bootstrap would give it a wide interval; the calibration columns are the firmer evidence.

**Refitting fixed what the data could see and left what it could not.** The monthly plan was a gap in the
data, and data filled it. The competitor is a change in the world that the columns do not describe, and
more rows of the same columns describe it only slowly. The ways forward are not technical alone: a column
the business can supply, *a competitor delivers in this city since this month*; or more weight on recent
months, through the model's sample weights, which costs stability everywhere else; or, while
those are decided, a person told that the model under-estimates two cities, and a credit budget for them
set by hand. All three are decisions for the people who own the credit. The model's part is to make the
error visible, by group, every month.

`churn-2026-02` is the better model for March, on every measure that is not noise, and it is the one to
load from April. That is a one-word change in `monthly.py`, and a new line in the record of which model
scored which month.
