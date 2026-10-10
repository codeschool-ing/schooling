---
title: Why the score on the training rows means nothing
version: 1
---

**A model can memorise.** Given enough freedom, it stores the answer for every row it was shown and
repeats it, and on those rows it is perfect. That perfection says nothing about the next row, which
is the only row anybody will ever ask it about. So a model is judged on rows it never saw while it
was learning, and the gap between the two scores is the first thing to look at.

A decision tree with no limits shows the gap at its widest. It keeps splitting the training rows
until every leaf holds rows of one class, which is memorising by construction. Lesson 7 is about
trees; here it is just a model with no brakes. Save this as `overfit.py`:

```python
# overfit.py
from sklearn.metrics import accuracy_score
from sklearn.tree import DecisionTreeClassifier

from feira import NUMERIC, by_time, load_churn, net_value

train, test = by_time(load_churn())
X_train, X_test = train[NUMERIC].fillna(-1), test[NUMERIC].fillna(-1)

tree = DecisionTreeClassifier(random_state=0).fit(X_train, train["churned"])
print(f"leaves: {tree.get_n_leaves():,} for {len(train):,} training rows")
for name, X, y in [("training", X_train, train["churned"]), ("test", X_test, test["churned"])]:
    said = tree.predict(X)
    print(f"{name:9} accuracy {accuracy_score(y, said):.3f}   net value R$ {net_value(y, said):>9,.0f}")
```

```
ana@lab:~/ml$ python overfit.py
leaves: 3,421 for 38,628 training rows
training  accuracy 1.000   net value R$   228,592
test      accuracy 0.892   net value R$   -25,816
```

**Perfect on the rows it learned from, and worse than the constant on the rows it did not.** 3,421
leaves for 38,628 rows is about eleven rows a leaf: the tree has carved out a little region for
nearly every combination of values it saw, each labelled with whatever happened there. On the
training rows that is worth R$ 228,592. On the test months it sends credits to the wrong people so
often that it loses R$ 25,816, and its accuracy, 0.892, is below the 0.939 of the model that
always says *stays*.

That is **overfitting**: the model has learned the noise of its training rows along with the
signal, and the noise does not repeat. The cure is partly a model with brakes, which lessons 5 to
9 supply, and entirely a test that cannot be memorised. `fillna(-1)` only gives the tree a number
where a rating or a login is missing; lesson 14 does that properly.

## The rule that follows

**Every number used to choose anything must come from rows the choice did not see.** That covers
the model's parameters, which `fit` sets, and everything a person sets around them: which model,
which columns, which threshold, which rule. The rest of this lesson is the machinery for keeping to
that rule without running out of data.
