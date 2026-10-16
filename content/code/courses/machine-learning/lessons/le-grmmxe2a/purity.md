---
title: Purity, and how the best cut is chosen
version: 1
---

"Separates the classes best" needs a number. The tree measures how **mixed** a group of rows is, and
picks the cut after which the two halves are, on average, least mixed. A group of only stayers, or
only leavers, is perfectly **pure**. A group of half and half is as mixed as two classes get.

The usual measure is **Gini impurity**: the chance that two rows drawn at random from the group, with
replacement, belong to different classes. With a share `p` of leavers, it is `1 − p² − (1 − p)²`,
which is 0 for a pure group and 0.5 at half and half. The other common one is **entropy**, `−p log₂ p
− (1 − p) log₂ (1 − p)`, from information theory, which ranges from 0 to 1 and nearly always picks
the same cuts.

The quality of a cut is the **gain**: the impurity before, minus the impurity of the two halves
weighted by their sizes. Here is the calculation for three candidate cuts on the training months,
done by hand. Save this as `purity.py`:

```python
# purity.py
import numpy as np

from feira import by_time, load_churn

train, _ = by_time(load_churn())
y = train["churned"].to_numpy()


def gini(labels):
    p = labels.mean()
    return 1 - p**2 - (1 - p)**2


def entropy(labels):
    p = labels.mean()
    return -sum(q * np.log2(q) for q in (p, 1 - p) if q > 0)


print(f"all {len(y):,} rows: leavers {y.mean():.3f}  gini {gini(y):.4f}  entropy {entropy(y):.4f}")
for name, mask in [("rating_90d <= 3.59", train["rating_90d"] <= 3.59),
                   ("skips_90d >= 3", train["skips_90d"] >= 3),
                   ("age <= 30", train["age"] <= 30)]:
    left, right = y[mask.to_numpy()], y[~mask.to_numpy()]
    after = (len(left) * gini(left) + len(right) * gini(right)) / len(y)
    print(f"{name:20} {len(left):6,} rows at {left.mean():.3f}, {len(right):6,} at {right.mean():.3f}"
          f"  gini after {after:.4f}  gain {gini(y) - after:.4f}")
```

```
ana@lab:~/ml$ python purity.py
all 38,628 rows: leavers 0.057  gini 0.1075  entropy 0.3153
rating_90d <= 3.59    3,172 rows at 0.271, 35,456 at 0.038  gini after 0.0992  gain 0.0082
skips_90d >= 3        2,355 rows at 0.183, 36,273 at 0.049  gini after 0.1054  gain 0.0020
age <= 30             9,384 rows at 0.061, 29,244 at 0.056  gini after 0.1075  gain 0.0000
```

**The rating cut wins by a wide margin.** It sends 3,172 rows to a side where 27.1% leave and keeps
the other 35,456 at 3.8%, and the weighted impurity falls from 0.1075 to 0.0992. The skips cut finds
a smaller, less extreme group and gains a quarter as much. The age cut separates nothing at all: 6.1%
against 5.6% leaves the impurity where it was, to four decimal places.

The tree does exactly this, for every column and every possible threshold, and keeps the best. Two
consequences follow from how the choice is made:

- **Columns with many possible cuts get more chances.** A column with thousands of distinct values
  offers thousands of thresholds and can find a cut that looks good by luck. Lesson 19 shows how that
  biases the importance a tree reports.
- **A tree cares about order, not units.** `rating_90d <= 3.6` is the same cut whether the rating is
  measured in stars or in hundredths of a star. Scaling, which lessons 5 and 6 needed, makes no
  difference to a tree at all.
