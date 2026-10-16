---
title: Random search
version: 1
---

**Random search** draws each candidate at random from a range for every hyperparameter, and fits as
many as the budget allows. It looks careless. It is usually better than a grid of the same size, for a
reason that is easiest to see in a picture:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 290\" role=\"img\" data-fig=\"l09-grid-random\" aria-label=\"Two squares, each with nine points. Horizontal: the hyperparameter that matters; vertical: one that does not. The grid's nine points sit on three columns, so they try three values of the dial that matters; the nine random points try nine different values. Tick marks under each square show the values tried.\"><rect x=\"60.0\" y=\"40.0\" width=\"200.0\" height=\"180.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"160.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">grid: 3 values tried</text><circle cx=\"100.0\" cy=\"184.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M100.0 228.0 L100.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"100.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M100.0 228.0 L100.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"100.0\" cy=\"76.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M100.0 228.0 L100.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"160.0\" cy=\"184.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M160.0 228.0 L160.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"160.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M160.0 228.0 L160.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"160.0\" cy=\"76.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M160.0 228.0 L160.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"220.0\" cy=\"184.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M220.0 228.0 L220.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"220.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M220.0 228.0 L220.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"220.0\" cy=\"76.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M220.0 228.0 L220.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"160.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the dial that matters</text><rect x=\"360.0\" y=\"40.0\" width=\"200.0\" height=\"180.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"460.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">random: 9 values tried</text><circle cx=\"377.1\" cy=\"199.5\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M377.1 228.0 L377.1 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"407.4\" cy=\"149.6\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M407.4 228.0 L407.4 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"520.3\" cy=\"127.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M520.3 228.0 L520.3 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"476.4\" cy=\"142.5\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M476.4 228.0 L476.4 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"378.8\" cy=\"114.4\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M378.8 228.0 L378.8 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"446.6\" cy=\"87.2\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M446.6 228.0 L446.6 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"455.8\" cy=\"47.9\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M455.8 228.0 L455.8 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"391.9\" cy=\"168.8\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M391.9 228.0 L391.9 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"506.9\" cy=\"103.3\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M506.9 228.0 L506.9 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"460.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the dial that matters</text></svg>", "caption": "Nine fits each. When only one dial matters, the random points have tried three times as many values of it."}
```

Suppose only one of two hyperparameters matters. Nine grid points try **three** values of it, each
three times over. Nine random points try **nine** different values of it, because two random points almost never share a coordinate. Whichever dial turns out to matter, random search has explored it more
finely, and nobody has to know in advance which one it is.

Ranges are drawn from distributions, and the choice of distribution is the one decision left.
`loguniform(0.01, 0.5)` draws a learning rate evenly on a log scale, so 0.01 to 0.05 gets as many
tries as 0.1 to 0.5, which is right for a dial whose effect is about proportions. `randint` draws whole
numbers evenly. Save this as `random_search.py`; it has the same budget as the grid, 18 candidates,
over **five** hyperparameters instead of three:

```python
# random_search.py
import time

from scipy.stats import loguniform, randint
from sklearn.model_selection import RandomizedSearchCV

from feira import by_time, load_churn
from tuning import FEATURES, booster, time_folds, value_per_thousand

train, _ = by_time(load_churn())
space = {"learning_rate": loguniform(0.01, 0.5),
         "max_leaf_nodes": randint(4, 64),
         "max_iter": randint(50, 400),
         "min_samples_leaf": randint(10, 400),
         "l2_regularization": loguniform(1e-3, 10)}
start = time.perf_counter()
search = RandomizedSearchCV(booster(), space, n_iter=18, cv=list(time_folds(train)),
                            scoring=value_per_thousand, n_jobs=-1, random_state=0)
search.fit(train[FEATURES], train["churned"])
print(f"18 candidates x 3 folds, {time.perf_counter() - start:.0f} s")
print(f"best {search.best_score_:.0f}:",
      {k: round(float(v), 3) if isinstance(v, float) else int(v) for k, v in search.best_params_.items()})
```

```
ana@lab:~/ml$ python random_search.py
18 candidates x 3 folds, 19 s
best 792: {'l2_regularization': 0.028, 'learning_rate': 0.093, 'max_iter': 134, 'max_leaf_nodes': 15, 'min_samples_leaf': 334}
```

**R$ 792 per thousand rows**, better than the grid's best with the same number of fits, and while
varying two hyperparameters the grid held fixed. It found small trees too, 15 leaves, and a large
`min_samples_leaf` of 334, which is another way of keeping trees simple.

The randomness is the price: another `random_state` finds a different best, and possibly a worse one.
With a budget of 18, a search samples a five-dimensional space very thinly. Its strength is that
every extra fit adds information on every dial at once, so it keeps improving as the budget grows,
where a grid improves only in steps of a whole new row of values.
