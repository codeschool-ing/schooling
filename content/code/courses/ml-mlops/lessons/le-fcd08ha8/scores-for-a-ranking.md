---
title: Scores for a ranking, not a cut
version: 1
---

Accuracy, precision and recall all need a threshold first. **A score that judges every threshold at
once judges the order the model puts members in**, and for a model whose output is a list to work
down, the order is the product.

Save this as `ranking.py`:

```python
"""ranking.py: scores that judge the order of the probabilities, not one cut of them."""
from sklearn.metrics import average_precision_score, roc_auc_score

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
test["p"] = lapse.predict_proba(test[COLUMNS])[:, 1]

print(f"ROC AUC            {roc_auc_score(test['lapsed'], test['p']):.3f}   (a coin: 0.5)")
print(f"average precision  {average_precision_score(test['lapsed'], test['p']):.3f}   "
      f"(a coin: {test['lapsed'].mean():.3f}, the share who lapse)")
for n in (100, 300, 530):
    top = test.nlargest(n, "p")
    print(f"of the top {n:3}, lapsed: {top['lapsed'].sum():3} ({top['lapsed'].mean():.0%})")
```

```
ana@dev:~/ml$ python ranking.py
ROC AUC            0.790   (a coin: 0.5)
average precision  0.522   (a coin: 0.169, the share who lapse)
of the top 100, lapsed:  75 (75%)
of the top 300, lapsed: 195 (65%)
of the top 530, lapsed: 263 (50%)
```

Three scores, three questions.

**ROC AUC, 0.790**, is the one lesson 3 used: pick one member who lapsed and one who stayed, and it
is the chance the model ranks the lapsed one higher. A coin scores 0.5, whatever share of members
lapse, which makes AUC easy to compare between datasets and also blind to how rare the positive
class is.

**Average precision, 0.522**, is the area under the precision-recall curve: precision averaged over
every point where recall rises. Its coin is not 0.5 but the share who lapse, **0.169**, because a
model that flags at random has a precision equal to that share at every threshold. The distance from
0.169 to 0.522 is the model's real lift over guessing, and it is the score that keeps rare outcomes
honest.

**Precision at k** answers the budget question exactly. Of the hundred members the model is surest
about, 75 lapsed; of the top three hundred, 195; of the top 530, which is as many as actually
lapsed, 263, so half. If marketing can send three hundred vouchers, **195 of them reach somebody who
was leaving**, and that sentence is the one to write in the report.

| the question | the score |
| --- | --- |
| does the model order members well, in general? | ROC AUC |
| how much better than chance is it at finding a rare outcome? | average precision, beside the base rate |
| how good is the list we can afford to act on? | precision at k, with k the budget |
