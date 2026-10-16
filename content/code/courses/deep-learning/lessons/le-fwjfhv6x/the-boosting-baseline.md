---
title: The boosting baseline, run first
version: 1
---

`machine-learning` lesson 2 made the case for a baseline: the trivial rule a model has to beat
before its score means anything. **On a table, the baseline worth beating is not the trivial rule.
It is gradient boosting with its defaults**, because it is cheap, it rarely loses by much, and the
two sections before this one showed it winning outright. A network on a table has to earn its place
against that number, and the number has to exist first.

So the recipe, in the order to run it:

1. **The majority class.** The floor. A model that cannot beat it has learnt nothing.
2. **A linear model on standardised columns.** Cheap, readable, and on a table like the cancer
   one, hard to beat.
3. **`HistGradientBoostingClassifier` with its defaults, on the table as it came.** No scaling, no
   filling of missing values, no encoding of categories beyond telling it which columns they are.
4. **The same folds for all of them**, and the metric that matches the cost of each kind of error,
   which is `machine-learning` lesson 10's subject. Accuracy is used here because the classes are
   not far from even and both errors cost the same.

Only after that does a network get its run, and it has to beat step 3 by more than the spread
between folds, or between seeds, the measurement lesson 18 taught.

The third step's "as it came" deserves a demonstration, because real tables have holes. The program
below runs the recipe on `table.py`'s customers after blanking a fifth of the monthly charges. Save
it as `~/dl/baseline.py`:

```schooling-example
{
  "language": "python",
  "file": "baseline.py",
  "parts": [
    {
      "code": "\"\"\"baseline: the runs to make on any table before a network is considered.\"\"\"\nimport textwrap\nimport time\n\nimport numpy as np\nfrom sklearn.dummy import DummyClassifier\nfrom sklearn.ensemble import HistGradientBoostingClassifier\nfrom sklearn.impute import SimpleImputer\nfrom sklearn.linear_model import LogisticRegression\nfrom sklearn.model_selection import StratifiedKFold, cross_val_score\nfrom sklearn.pipeline import make_pipeline\nfrom sklearn.preprocessing import StandardScaler\nfrom threadpoolctl import threadpool_limits\n\nimport table\n\nthreadpool_limits(1)"
    },
    {
      "code": "X, y = table.make()\ngone = np.random.default_rng(1).random(len(y)) < 0.2\nX[gone, 1] = np.nan",
      "note": "A fifth of the monthly charges are blanked out, the way a column arrives from a real system: `NaN` where somebody never filled it in."
    },
    {
      "code": "folds = StratifiedKFold(n_splits=5, shuffle=True, random_state=0)\ncandidates = {\n    \"majority class\": DummyClassifier(),\n    \"logistic regression\": make_pipeline(StandardScaler(), LogisticRegression()),\n    \"logistic, imputed\": make_pipeline(SimpleImputer(), StandardScaler(), LogisticRegression()),\n    \"gradient boosting\": HistGradientBoostingClassifier(random_state=0),\n}",
      "note": "The recipe in four lines: the trivial answer, a linear model, the same linear model with the blanks filled by the column's mean, and boosting on the table as it came."
    },
    {
      "code": "for name, model in candidates.items():\n    start = time.perf_counter()\n    try:\n        scores = cross_val_score(model, X, y, cv=folds, error_score=\"raise\")\n    except ValueError as error:\n        reason = str(error).splitlines()[1].split(\". \")[:2]\n        print(f\"{name:20s} refused:\")\n        print(textwrap.fill(\". \".join(reason) + \".\", 72, initial_indent=\"    \", subsequent_indent=\"    \"))\n        continue\n    print(f\"{name:20s} accuracy {scores.mean():.3f}  worst fold {scores.min():.3f}  \"\n          f\"{time.perf_counter() - start:5.2f} s\")",
      "note": "`error_score=\"raise\"` makes a model that cannot fit say why, instead of scoring `nan` and carrying on. The first two sentences of its reason are printed."
    }
  ]
}
```

```
PENDING baseline
```

**Logistic regression refuses the table outright**, and scikit-learn's own message names the model
that would not have: the gradient boosting in this very program. Filling each blank with the
column's mean lets it run, at 0.797. Boosting took the holes as they were and reached 0.867, against
0.883 on the complete table in the section before. It learns, at each split, which side the missing
values go to, so a blank becomes information instead of an error.

`HistGradientBoostingClassifier` has the same idea as two libraries you will meet in other people's
code: **XGBoost and LightGBM**, the usual names for gradient boosting in production. Both build
trees over binned columns in the same way, scikit-learn's version was inspired by LightGBM, and
either can replace it in step 3. Neither is installed in this course's environment, so neither is
run here; `machine-learning` lesson 8 covers them.

The run took under a second for the whole recipe. **A baseline that cheap has no excuse to be
skipped**, and a network that cannot beat it has told you something worth knowing before the first
epoch was spent.
