---
title: Bagging, many trees on many samples
version: 1
---

Lesson 7 ended with a weakness: a single tree changes a good deal when its training rows change.
**Bagging** turns that into a strength. Draw a bootstrap sample of the training rows, the same
resampling with replacement that lesson 2 used to measure luck, and fit a tree to it. Draw another
and fit another. Do it a hundred times, and average the hundred trees' predictions. The name is
short for *bootstrap aggregating*.

Each tree is deep and noisy, and each is noisy in its own way, because each saw a slightly different
set of rows. **The average keeps what the trees agree on and cancels much of what each invented.**
Save this as `bagging.py`; the trees each require 20 rows a leaf, so each is deep but not unlimited:

```python
# bagging.py
import pandas as pd
from sklearn.ensemble import BaggingClassifier
from sklearn.tree import DecisionTreeClassifier

from feira import CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
cut = CREDIT / (SAVED * KEPT)
tree = DecisionTreeClassifier(min_samples_leaf=20, random_state=0)
for n in [1, 10, 100]:
    bag = BaggingClassifier(tree, n_estimators=n, random_state=0, n_jobs=-1)
    bag.fit(train[NUMERIC], train["churned"])
    send = bag.predict_proba(test[NUMERIC])[:, 1] >= cut
    print(f"{n:3} trees, each on a bootstrap sample: {send.sum():5,} credits, "
          f"R$ {net_value(test['churned'], send):8,.0f}")
```

```
ana@lab:~/ml$ python bagging.py
  1 trees, each on a bootstrap sample: 1,090 credits, R$    8,096
 10 trees, each on a bootstrap sample:   791 credits, R$   21,496
100 trees, each on a bootstrap sample:   787 credits, R$   23,384
```

**One tree on one bootstrap sample makes R$ 8,096. Ten make R$ 21,496, and a hundred R$ 23,384**, more
than any single model so far, including lesson 2's gradient boosting. Nothing about the individual
trees changed between the three lines; only how many were averaged.

Two things make this work, and both are worth naming because the rest of the lesson rests on them.

**The trees must be different.** Averaging a hundred copies of one tree gives that tree. The
bootstrap makes each tree's rows different, so their mistakes are different, and different mistakes
partly cancel.

**Each tree must be good on its own.** Averaging a hundred guesses that know nothing gives a guess
that knows nothing. The trees here are deep enough to find the rating, the complaints and the skips
on their own; bagging removes their noise, not their ignorance.

Adding more trees never makes a bagged model overfit, in the sense lesson 3 meant: the hundredth
tree changes the average less than the tenth did, and the test value settles rather than falling.
More trees cost time and memory, and past a few hundred they buy almost nothing.
