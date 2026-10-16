---
title: When the answers arrive
version: 1
---

A month after each run, the month's answers exist: who left during January is known by the first of
February. `churn_2026_labels.csv` holds them for all three months, the way the company's system would
have delivered them one month at a time. Now the scores can be graded, and the grading is the same as in
every lesson: does the ranking hold, is the level honest, and what did the credits earn. Save this as
`labels.py`:

```python
# labels.py
import pandas as pd
from sklearn.metrics import roc_auc_score

from feira import CREDIT, KEPT, SAVED

scores = pd.concat(pd.read_csv(f"scores/2026-0{m}.csv") for m in [1, 2, 3])
labels = pd.read_csv("data/churn_2026_labels.csv")
rows = scores.merge(labels, on=["customer_id", "snapshot"], validate="one_to_one")

for month, g in rows.groupby("snapshot"):
    sent = g[g["credit"]]
    promised = (SAVED * KEPT * sent["chance"] - CREDIT).sum()
    delivered = SAVED * KEPT * sent["churned"].sum() - CREDIT * len(sent)
    print(f"{month[:7]}: chance {g['chance'].mean():.3f}, left {g['churned'].mean():.3f}, "
          f"AUC {roc_auc_score(g['churned'], g['chance']):.3f}, "
          f"value promised R$ {promised:,.0f}, delivered R$ {delivered:,.0f}")
```

`validate="one_to_one"` makes the merge fail if a subscriber appears twice on either side, which is a
cheap way to find out on the day that the scores and the labels do not describe the same people.
**Promised** is what the model's own chances said the credits would earn: each credit is worth R$ 144
times the chance that its subscriber was leaving, minus R$ 40. **Delivered** is lesson 2's net value, from
what happened.

```
ana@lab:~/ml$ python labels.py
2026-01: chance 0.061, left 0.049, AUC 0.810, value promised R$ 3,600, delivered R$ 1,904
2026-02: chance 0.065, left 0.047, AUC 0.808, value promised R$ 4,723, delivered R$ 2,008
2026-03: chance 0.065, left 0.056, AUC 0.788, value promised R$ 4,783, delivered R$ 1,296
```

**The ranking held.** AUC 0.810 and 0.808, close to the 0.818 lesson 15 measured on the test months,
and 0.788 in March, a little lower. The people the model put at the top were still, mostly, the
people who left.

**The level did not.** The model said 6.1% to 6.5% would leave, and 4.9%, 4.7% and 5.6% did. The price
rise's after-effect was over by January, and a model fitted on the months that included it kept
expecting it. Lesson 11 warned about exactly this: a decision that compares a chance with a fixed number
inherits the error in the chance.

**And the credits earned about half of what was promised**, or less: R$ 1,904 against R$ 3,600 in January,
R$ 1,296 against R$ 4,783 in March. Still positive, so the program was still worth running. But a
team that planned a budget on the promised figure would be explaining a gap of R$ 7,898 by the end of
March, and the explanation is not "the model got worse". It is that the model is as good at ordering
people as it was, and too pessimistic about how many of them would leave. The next section looks for
where.
