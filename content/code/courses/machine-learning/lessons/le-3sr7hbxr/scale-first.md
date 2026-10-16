---
title: Scale first, or one column decides
version: 1
---

k-means measures distance, and a distance adds up differences across columns. A difference of R$ 68.8
in the basket and a difference of 5.5 points in eggs are both "one typical difference", but unscaled, the
first counts more than twelve times as much as the second. The program below clusters the same rows
twice, scaled and unscaled, and compares the two. Save this as `unscaled.py`:

```python
# unscaled.py
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.metrics import adjusted_rand_score
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
X = baskets.drop(columns="customer_id")
scaled = KMeans(n_clusters=4, n_init=10, random_state=0).fit(StandardScaler().fit_transform(X))
raw = KMeans(n_clusters=4, n_init=10, random_state=0).fit(X)

print("spread of each column:", ", ".join(f"{c} {s:.1f}" for c, s in X.std().items()))
print(f"agreement between the two clusterings (adjusted Rand): "
      f"{adjusted_rand_score(scaled.labels_, raw.labels_):.3f}")
print(baskets.assign(cluster=raw.labels_).groupby("cluster")[["avg_basket", "orders_month", "fruit",
                                                             "bakery"]].mean().round(1).to_string())
```

The **adjusted Rand index** compares two ways of grouping the same rows. It is 1 when they agree exactly,
whatever numbers each one gave its groups, and about 0 when they agree no more than chance would.

```
ana@lab:~/ml$ python unscaled.py
spread of each column: orders_month 1.1, avg_basket 68.8, fruit 13.7, vegetables 9.2, greens 7.4, eggs_dairy 5.5, bakery 9.1, extras 5.9
agreement between the two clusterings (adjusted Rand): 0.723
         avg_basket  orders_month  fruit  bakery
cluster                                         
0             327.5           1.6   19.5    12.1
1             207.2           3.5   16.2     6.5
2             138.7           2.0   43.5     5.1
3             260.5           3.9   15.4    22.1
```

Agreement 0.723: related, but not the same grouping. Read the unscaled clusters' baskets: R$ 139, 207,
261 and 328, neatly spaced, because **the basket is nearly all the unscaled distance can see**. Orders a
month, with a spread of 1.1, count for almost nothing. The bakery cluster survives only because bakery
customers also happen to spend about R$ 260.

Two lessons follow, and both outlast k-means:

- **Scale before any method that measures distance**: k-means, DBSCAN, hierarchical clustering, nearest
  neighbours, support vector machines. Trees do not need it, because a split compares a column only with
  itself.
- **Scaling is a choice about what matters.** Standardising says every column counts equally. If the
  marketing team cares about *what* people buy far more than *how much*, the shares could be weighted up,
  or the two money columns left out. There is no neutral choice, only a stated one.
