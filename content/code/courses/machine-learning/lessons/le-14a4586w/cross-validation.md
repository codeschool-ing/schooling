---
title: Cross-validation, and how much a score moves
version: 1
---

**k-fold cross-validation** cuts the training rows into k parts, called folds. It fits the model k
times, each time on k − 1 folds, and scores it on the fold left out. Every row is used for scoring
exactly once and for training k − 1 times, and the result is not one score but k of them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 230\" role=\"img\" data-fig=\"l03-folds\" aria-label=\"Five rows, one per fit. Each row is the training data cut into five folds; in each row a different fold is scored and the other four are fitted on.\"><text x=\"320.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the training rows, in five folds</text><text x=\"106.0\" y=\"55.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fit 1</text><rect x=\"122.0\" y=\"40.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">scored</text><rect x=\"202.0\" y=\"40.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"282.0\" y=\"40.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"362.0\" y=\"40.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"442.0\" y=\"40.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">score 1</text><text x=\"106.0\" y=\"93.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fit 2</text><rect x=\"122.0\" y=\"78.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"78.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">scored</text><rect x=\"282.0\" y=\"78.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"362.0\" y=\"78.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"442.0\" y=\"78.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">score 2</text><text x=\"106.0\" y=\"131.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fit 3</text><rect x=\"122.0\" y=\"116.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"116.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"282.0\" y=\"116.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">scored</text><rect x=\"362.0\" y=\"116.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"442.0\" y=\"116.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"131.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">score 3</text><text x=\"106.0\" y=\"169.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fit 4</text><rect x=\"122.0\" y=\"154.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"154.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"282.0\" y=\"154.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"362.0\" y=\"154.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">scored</text><rect x=\"442.0\" y=\"154.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">score 4</text><text x=\"106.0\" y=\"207.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fit 5</text><rect x=\"122.0\" y=\"192.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"192.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"282.0\" y=\"192.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"362.0\" y=\"192.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"442.0\" y=\"192.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">scored</text><text x=\"534.0\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">score 5</text></svg>", "caption": "Every row is scored once and fitted on four times. Five scores come out, and their spread is the luck of the cut."}
```

The k scores are the point. Their mean is a better estimate than any single held-out score, and
their **spread is a measurement of luck**: how much the score moves when only the choice of rows
changes. scikit-learn makes the folds; the loop that uses them is short enough to write out, which
shows exactly what is fitted on what. Save this as `folds.py`:

```python
# folds.py
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.model_selection import GroupKFold, KFold, StratifiedKFold

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, _ = by_time(load_churn())
X, y = train[NUMERIC + CATEGORICAL], train["churned"]
cut = CREDIT / (SAVED * KEPT)


def per_fold(splitter, groups=None):
    values = []
    for fit_rows, check_rows in splitter.split(X, y, groups):
        model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
        model.fit(X.iloc[fit_rows], y.iloc[fit_rows])
        send = model.predict_proba(X.iloc[check_rows])[:, 1] >= cut
        values.append(net_value(y.iloc[check_rows], send) / len(check_rows) * 1000)
    return np.array(values)


for name, splitter, groups in [
        ("KFold", KFold(5, shuffle=True, random_state=0), None),
        ("StratifiedKFold", StratifiedKFold(5, shuffle=True, random_state=0), None),
        ("GroupKFold", GroupKFold(5), train["customer_id"])]:
    v = per_fold(splitter, groups)
    print(f"{name:16} R$ per 1,000 rows: " + "  ".join(f"{x:6.0f}" for x in v)
          + f"   mean {v.mean():6.0f}  sd {v.std():5.0f}")
```

```
ana@lab:~/ml$ python folds.py
KFold            R$ per 1,000 rows:   1044     972     687     775     641   mean    824  sd   158
StratifiedKFold  R$ per 1,000 rows:    597     751     994     764     686   mean    758  sd   132
GroupKFold       R$ per 1,000 rows:    845    1116     684     700     589   mean    787  sd   184
```

The net value is divided by the size of each fold so that folds of different sizes compare, which
is why it reads in reais per thousand rows. Three things in it.

**The same model on five folds ranges from about R$ 640 to R$ 1,040 per thousand rows.** Nothing
changed between them except which subscribers fell where. Any comparison between two models that
differ by less than a spread like that is a comparison of luck, the point lesson 2 made with the
bootstrap, made here from the other direction.

**Every fold is fitted from scratch.** Inside the loop a new model is made each time. Reusing one
fitted model across folds would score it on rows it had learned from, which is the error of the
previous section hidden inside a loop.

**The three rows of output use three ways of cutting**, and the next two sections are about the
second and the third.

## How many folds

Five or ten is the custom, and the trade is easy to state. More folds means each model learns from
more rows, so the estimate is closer to what the final model will do, and it means more fits.
Five fits of a model that takes a second cost nothing; five fits of one that takes an hour are a
working day. With 38,628 rows and a model that fits in about a second, five is plenty.
