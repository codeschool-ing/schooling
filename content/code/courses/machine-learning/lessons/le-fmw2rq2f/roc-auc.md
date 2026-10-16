---
title: ROC AUC, and what the number means
version: 1
---

The area under the ROC curve, **AUC**, summarises the curve in one number: 0.5 for the diagonal, 1.0
for a perfect model. Lesson 4 used it before explaining it; here is what it means, which is more
useful than the geometry. **AUC is the probability that a randomly chosen leaver gets a higher score
than a randomly chosen stayer.** That can be checked directly, by drawing pairs. Save this as
`ranking.py`:

```python
# ranking.py
import numpy as np
import pandas as pd
from sklearn.metrics import average_precision_score, roc_auc_score

scores = pd.read_csv("scores.csv")
y, chance = scores["churned"].to_numpy(), scores["chance"].to_numpy()
print(f"ROC AUC {roc_auc_score(y, chance):.3f}   average precision {average_precision_score(y, chance):.3f}")
print(f"leavers among all test rows: {y.mean():.3f}")

rng = np.random.default_rng(0)
leaver = rng.choice(chance[y == 1], 100_000)
stayer = rng.choice(chance[y == 0], 100_000)
print(f"a random leaver scored above a random stayer in {np.mean(leaver > stayer):.1%} of 100,000 pairs")
```

```
ana@lab:~/ml$ python ranking.py
ROC AUC 0.804   average precision 0.322
leavers among all test rows: 0.061
a random leaver scored above a random stayer in 80.4% of 100,000 pairs
```

**The area is 0.804, and in 100,000 random pairs a leaver outscored a stayer 80.4% of the time.** The
two are the same quantity, computed two ways. So AUC is about ranking and nothing else: it does not
care what the scores are, only their order, and it does not depend on any cut.

That makes it good for some jobs and wrong for others.

**It is good for comparing models before a cut is chosen**, and for spotting the impossible: lesson 4's
0.958 was a model ranking leavers far better than behaviour allows. It does not change when the scores
are all multiplied or shifted, so a model with badly calibrated probabilities can have an excellent
AUC.

**It is wrong for judging a decision.** The credit goes to the top few hundred subscribers a month, and
AUC weighs the order among the bottom twenty thousand exactly as much as the order at the top. Two
models with the same AUC can differ a great deal in the region where the credits are actually sent.

The second number `ranking.py` printed is the subject of the next section.
