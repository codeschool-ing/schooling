---
title: Why one tree is not enough
version: 1
---

A tree is built greedily, one cut at a time, and every cut depends on the ones above it. Change the
training rows a little and an early cut can move, and then everything below it is a different tree.
That is the property this section measures and lesson 8 exploits. Save this as `unstable.py`; it
fits a tree three levels deep on five different random halves of the training months:

```python
# unstable.py
from sklearn.tree import DecisionTreeClassifier

from feira import NUMERIC, by_time, load_churn

train, _ = by_time(load_churn())
for seed in range(5):
    sample = train.sample(frac=0.5, random_state=seed)            # another half of the rows
    tree = DecisionTreeClassifier(max_depth=3, random_state=0)
    tree.fit(sample[NUMERIC], sample["churned"])
    t = tree.tree_
    root = f"{NUMERIC[t.feature[0]]} <= {t.threshold[0]:.2f}"
    second = sorted({NUMERIC[f] for f in t.feature[1:] if f >= 0})
    print(f"sample {seed}: root {root:26} below it: {', '.join(second)}")
```

```
ana@lab:~/ml$ python unstable.py
sample 0: root rating_90d <= 3.60         below it: complaints_90d, rating_90d, skips_90d, tenure_months
sample 1: root rating_90d <= 3.58         below it: complaints_90d, skips_90d, tenure_months
sample 2: root rating_90d <= 3.59         below it: complaints_90d, rating_90d, skips_90d, tenure_months
sample 3: root rating_90d <= 3.60         below it: rating_90d, skips_90d, tenure_months
sample 4: root rating_90d <= 3.59         below it: days_since_login, late_90d, skips_90d, tenure_months
```

**The root is stable**: every half chooses the rating, at a threshold between 3.58 and 3.60. That cut
is so much better than any other, as `purity.py` showed, that no reasonable sample would pick
something else. **Below it, the trees disagree.** Sample 4 brings in `days_since_login` and
`late_90d`, which no other sample uses, and drops `complaints_90d`, which three of the others lean on.
Five samples, four different sets of lower questions.

On data with no single dominant column, even the root moves, and the trees differ from the top.
Either way the conclusion is the same: **a single tree has high variance.** The particular rows it
was given leave a strong mark on it, so its predictions for an individual subscriber can change
noticeably from one fit to the next.

There is an upside hidden in that. If each tree is a noisy but different guess, **averaging many of
them cancels much of the noise**, in the same way the average of many noisy measurements is better
than any one of them. That idea, applied with some care about how the trees are made different, is
the random forest, and it is the first section of lesson 8.
