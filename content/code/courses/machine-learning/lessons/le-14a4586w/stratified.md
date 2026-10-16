---
title: Stratified folds for a rare class
version: 1
---

Cut 38,628 rows into five at random and each fold gets roughly a fifth of the leavers, but only
roughly. With leavers at under 6%, one fold can end up with noticeably more than another, and a fold
with fewer positives scores differently for that reason alone. **Stratified** folds fix the share of
each class in every fold, so that the folds differ only in which rows they hold. Save this as
`leavers_per_fold.py`:

```python
# leavers_per_fold.py
from sklearn.model_selection import KFold, StratifiedKFold

from feira import by_time, load_churn

train, _ = by_time(load_churn())
y = train["churned"]
for name, splitter in [("KFold", KFold(5, shuffle=True, random_state=3)),
                       ("StratifiedKFold", StratifiedKFold(5, shuffle=True, random_state=3))]:
    shares = [y.iloc[rows].mean() for _, rows in splitter.split(train, y)]
    print(f"{name:16} leavers in each fold: " + "  ".join(f"{s:.2%}" for s in shares))
```

```
ana@lab:~/ml$ python leavers_per_fold.py
KFold            leavers in each fold: 5.55%  5.84%  5.41%  5.84%  5.85%
StratifiedKFold  leavers in each fold: 5.71%  5.70%  5.70%  5.70%  5.70%
```

Plain `KFold` gives folds from 5.41% to 5.85% leavers; `StratifiedKFold` gives 5.70% or 5.71% in
every one. Here the difference is small, because there are over two thousand leavers to share out.
It grows as the rare class shrinks: with fifty positives, a random fold can easily get five and
another fifteen, and the scores of those two folds then measure the draw more than the model.

So **for classification, stratify by default**. scikit-learn already does when it can:
`cross_val_score` and `GridSearchCV` given a classifier and a whole number of folds use
`StratifiedKFold` without being asked. It is when you write the loop yourself, as `folds.py` does,
that you have to choose it.

Stratifying does nothing about the problem of the next section, and the two can be combined:
`StratifiedGroupKFold` keeps each subscriber whole and the class shares close to even.
