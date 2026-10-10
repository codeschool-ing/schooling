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
