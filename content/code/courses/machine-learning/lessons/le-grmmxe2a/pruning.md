---
title: Pruning, and the other brakes
version: 1
---

`max_depth` stops every branch at the same depth, which is crude: some branches have enough rows to
go deeper usefully and others ran out of evidence long before. scikit-learn has finer brakes, and
two of them do most of the work:

- **`min_samples_leaf`**: no leaf may hold fewer than this many training rows. A branch stops when
  splitting further would make a leaf too small to trust, however deep it is.
- **`ccp_alpha`**: **cost-complexity pruning**. The tree is grown fully, then the branches that add
  the least purity for each extra leaf are cut back, one by one, until what remains is worth its
  size. Larger values prune harder.

Save this as `pruning.py`:

```python
# pruning.py
from sklearn.tree import DecisionTreeClassifier

from feira import CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
cut = CREDIT / (SAVED * KEPT)
for name, settings in [("no limits", {}),
                       ("min_samples_leaf=200", {"min_samples_leaf": 200}),
                       ("ccp_alpha=0.0003", {"ccp_alpha": 0.0003})]:
    tree = DecisionTreeClassifier(random_state=0, **settings).fit(train[NUMERIC], train["churned"])
    send = tree.predict_proba(test[NUMERIC])[:, 1] >= cut
    print(f"{name:22} {tree.get_n_leaves():5,} leaves, depth {tree.get_depth():2}, "
          f"test R$ {net_value(test['churned'], send):8,.0f}")
```

```
ana@lab:~/ml$ python pruning.py
no limits              3,328 leaves, depth 30, test R$  -23,856
min_samples_leaf=200     139 leaves, depth 17, test R$   15,960
ccp_alpha=0.0003          10 leaves, depth  4, test R$   11,800
```

**Both brakes turn a loss into a profit.** With no limits, 3,328 leaves lose R$ 23,856. Requiring 200
rows a leaf grows a tree of 139 leaves, 17 levels deep in places, and makes **R$ 15,960**: deep where
the data is plentiful, shallow where it is not. Pruning with `ccp_alpha=0.0003` keeps only 10 leaves,
four levels deep, and makes R$ 11,800 with a tree small enough to read.

Neither brake was tuned; the values were picked to show what each does, and lesson 9 tunes them
properly. The lesson here is the shape of the trade. **A single tree is either small and readable or
large and accurate, and never as accurate as the alternatives**: lesson 5's logistic regression made
R$ 16,424 with 22 weights, and the boosted model of lesson 2 made R$ 21,672. Lesson 8 is about
growing many trees instead of one, which is how trees became the models that usually win on tables.
