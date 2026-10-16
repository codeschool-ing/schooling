---
title: DBSCAN, and the customers who belong nowhere
version: 1
---

k-means makes three assumptions without saying so: every row belongs to some cluster, clusters are round,
and you know how many there are. **DBSCAN** drops all three. It grows clusters out of dense regions. A row with at least `min_samples` neighbours within a distance
`eps` is a core. Cores near each other join one cluster, and rows near a core join it too. Rows near no
core are **noise**, given the label −1.

So it finds the number of clusters itself, follows any shape, and leaves the odd customer out instead of
forcing them into the nearest group. In exchange it needs `eps`, a distance in the scaled units, and that
is a harder number to choose than *k*. Save this as `dbscan.py`:

```python
# dbscan.py
import numpy as np
import pandas as pd
from sklearn.cluster import DBSCAN
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
scaled = StandardScaler().fit_transform(baskets.drop(columns="customer_id"))
print(" eps   clusters   noise   sizes")
for eps in [0.8, 1.0, 1.2, 1.5, 2.0]:
    labels = DBSCAN(eps=eps, min_samples=10).fit(scaled).labels_
    sizes = np.bincount(labels[labels >= 0])
    print(f"{eps:4.1f} {labels.max() + 1:8} {(labels == -1).sum():7}   {sizes.tolist()}")
```

```
ana@lab:~/ml$ python dbscan.py
 eps   clusters   noise   sizes
 0.8        4     355   [270, 304, 197, 74]
 1.0        4      54   [309, 336, 341, 160]
 1.2        4       9   [344, 328, 340, 179]
 1.5        3       0   [687, 329, 184]
 2.0        1       0   [1200]
```

**At 1.2 it finds four groups of nearly the sizes k-means found**, with nine customers left out as noise, and nobody
had to tell it four. At 0.8 the density bar is too high: 355 customers count as noise, and the rare big
spenders, the smallest group, shrink to 74. At 1.5 two groups touch and merge into one of 687, and at 2.0
everything is one cluster.

The table is the honest way to use DBSCAN: run a few values of `eps` and look for a range where the
answer holds still. Here it holds from 1.0 to 1.2, which is evidence that the four groups are real
features of the data rather than of the method.

The noise is worth a look of its own. Nine customers who are like nobody else are either data errors or
the most interesting rows in the file, and k-means would have quietly put them in the nearest cluster
and moved its average.
