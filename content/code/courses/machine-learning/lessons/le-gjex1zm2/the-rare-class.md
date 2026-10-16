---
title: What a rare class does
version: 1
---

Feira em Casa's churn is a **rare class**: the thing being looked for is a small share of the rows.
How small is worth knowing exactly. Save this as `balance.py`:

```python
# balance.py
from feira import by_time, load_churn

train, test = by_time(load_churn())
for name, rows in [("training months", train), ("test months", test)]:
    leavers = rows["churned"].sum()
    print(f"{name:16} {len(rows):6,} rows  {leavers:5,} leavers  {leavers / len(rows):5.1%}"
          f"  one in {len(rows) / leavers:4.1f}")
```

```
ana@lab:~/ml$ python balance.py
training months  38,628 rows  2,201 leavers   5.7%  one in 17.6
test months      24,257 rows  1,484 leavers   6.1%  one in 16.3
```

One row in seventeen. By the standards of the problems where this question comes up, that is
mild. Fraud runs at one in a thousand, a rare disease at one in ten thousand, a defective part on a
good production line at fewer still. Every earlier lesson has already met what such a class does,
without naming it as one subject:

- **Accuracy goes blind** (lesson 10). A model that never predicts the class scores 94% here,
  99.9% on fraud.
- **The default cut is far off** (lessons 10 and 11). A chance has to be very high to pass 0.5 when
  almost everybody is negative, so a model run with `predict` finds almost nobody: 194 credits
  sent, 117 leavers reached out of 1,484.
- **The curves need choosing** (lesson 10). ROC AUC flatters a model on a rare class, and the
  precision-recall curve keeps the class in view.

A whole family of remedies exists for this, and most tutorials reach for one before anything else:
**reweight the classes, or resample them until they are balanced**. This lesson tries each on the
churn model and measures what it buys. The measuring is the point. The remedies are easy to apply,
and easy to apply to a problem they do not fix.

Before that, one distinction that decides most of what follows. A class can be rare in two ways that
look alike and are not: **a small share of the rows**, or **a small number of rows**. The next
section separates them.
