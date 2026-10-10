---
title: The score that lies
version: 1
---

**A model scored on the rows it learned from is being asked whether it remembers them**, which is a
different question from whether it learned anything. A flexible enough model can remember every
row, and then it scores perfectly on them and badly on everything else.

The program below makes that visible with a **decision tree**, a model that splits the members
again and again on one feature at a time ("recency over 120 days?", then "fewer than three
visits?") until each leaf holds members with mostly one outcome. `max_depth` limits how many
questions deep it may go. Save it as `overfit.py`:

```python
"""overfit.py: a tree scored on the rows it learned from, and on rows it did not."""
from sklearn.metrics import roc_auc_score
from sklearn.tree import DecisionTreeClassifier

import features

X = features.NUMERIC
train = features.build("2025-08-31")
valid = features.build("2025-09-30")


def auc(model, rows):
    return roc_auc_score(rows["lapsed"], model.predict_proba(rows[X])[:, 1])


print("depth  train AUC  validation AUC")
scores = {}
for depth in (2, 4, 6, 8, 12, None):
    tree = DecisionTreeClassifier(max_depth=depth, random_state=0).fit(train[X], train["lapsed"])
    scores[depth] = auc(tree, valid)
    print(f"{str(depth):>5}  {auc(tree, train):9.3f}  {scores[depth]:14.3f}")

best = max(scores, key=scores.get)                       # chosen on validation only
tree = DecisionTreeClassifier(max_depth=best, random_state=0).fit(train[X], train["lapsed"])
test = features.build("2025-11-30")                      # opened once, at the end
print(f"chosen depth {best}; test AUC {auc(tree, test):.3f}")
```

The score in this lesson is **AUC**, a number from 0.5 to 1 that answers one question: pick a
member who lapsed and one who stayed at random, and how often does the model give the one who
lapsed the higher probability? 0.5 is a coin, 1 is a perfect ranking. Lesson 4 is about scores and
explains why this one fits the lapse question better than the most obvious one.

```
ana@dev:~/ml$ python overfit.py
depth  train AUC  validation AUC
    2      0.734           0.719
    4      0.795           0.762
    6      0.831           0.751
    8      0.871           0.723
   12      0.957           0.662
 None      1.000           0.636
chosen depth 4; test AUC 0.769
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-overfit\" aria-label=\"AUC of a decision tree against its maximum depth: 2, 4, 6, 8, 12 and no limit. On the training rows it rises steadily: 0.734, 0.795, 0.831, 0.871, 0.957, 1.000. On the validation rows it rises to 0.762 at depth 4 and then falls: 0.751, 0.723, 0.662, 0.636.\"><path d=\"M80.0 40.0 L80.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 230.0 L80.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.6</text><path d=\"M80.0 182.5 L560.0 182.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 182.5 L80.0 182.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"182.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.7</text><path d=\"M80.0 135.0 L560.0 135.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 135.0 L80.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.8</text><path d=\"M80.0 87.5 L560.0 87.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 87.5 L80.0 87.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"87.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.9</text><path d=\"M80.0 40.0 L560.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 40.0 L80.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.0</text><text x=\"80.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">AUC</text><path d=\"M80.0 230.0 L560.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"120.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"200.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"280.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><text x=\"360.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"440.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><text x=\"520.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">none</text><text x=\"320.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">maximum depth of the tree</text><path d=\"M120.0 166.3 L200.0 137.4 L280.0 120.3 L360.0 101.3 L440.0 60.4 L520.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><circle cx=\"120.0\" cy=\"166.3\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><circle cx=\"200.0\" cy=\"137.4\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><circle cx=\"280.0\" cy=\"120.3\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><circle cx=\"360.0\" cy=\"101.3\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><circle cx=\"440.0\" cy=\"60.4\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><circle cx=\"520.0\" cy=\"40.0\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><path d=\"M120.0 173.5 L200.0 153.0 L280.0 158.3 L360.0 171.6 L440.0 200.5 L520.0 212.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"120.0\" cy=\"173.5\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"200.0\" cy=\"153.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"280.0\" cy=\"158.3\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"360.0\" cy=\"171.6\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"440.0\" cy=\"200.5\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"520.0\" cy=\"212.9\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"200.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">best on validation</text><path d=\"M580.0 70.0 L610.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"618.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">training rows</text><path d=\"M580.0 96.0 L610.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"618.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">validation rows</text></svg>", "caption": "The deeper the tree, the better it remembers the rows it learned from and the worse it does on the next month. The gap between the lines is overfitting."}
```

**Read the two columns going down.** On the rows it trained on, the tree gets better with every
level, until with no limit it scores 1.000: it has memorised all of them. On the validation rows,
members as they stood a month later, it improves up to depth 4 and then gets worse at every step,
down to 0.636 for the tree that "learned" everything. The gap between the columns is called
**overfitting**: what the model learned about these particular members rather than about members.

The last line uses a third set of rows, and only once, and the next section is about why.
