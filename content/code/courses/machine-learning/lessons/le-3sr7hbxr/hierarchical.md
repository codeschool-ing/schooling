---
title: Hierarchical clustering
version: 1
---

**Agglomerative clustering** starts with every customer in a cluster of their own and merges the two
closest clusters, again and again, until one is left. The result is a tree of merges, and cutting it at
any height gives a clustering: near the top, a few large groups; near the bottom, many small ones. It
answers *"how many?"* with *"pick a height"*, and it shows the whole family of answers at once.

What *closest clusters* means is the **linkage**, and it changes the result more than anything else:

- **ward** merges the pair that raises the total within-cluster spread least. It makes compact groups of
  similar size, the same goal k-means has.
- **average** uses the average distance between every row of one cluster and every row of the other.
- **single** uses the distance between the two closest rows. One customer midway between two groups is
  enough to join them.

Save this as `hierarchy.py`; it cuts each tree at four clusters and compares it with k-means:

```python
# hierarchy.py
import numpy as np
import pandas as pd
from sklearn.cluster import AgglomerativeClustering, KMeans
from sklearn.metrics import adjusted_rand_score
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
scaled = StandardScaler().fit_transform(baskets.drop(columns="customer_id"))
kmeans = KMeans(n_clusters=4, n_init=10, random_state=0).fit(scaled)
for linkage in ["ward", "average", "single"]:
    tree = AgglomerativeClustering(n_clusters=4, linkage=linkage).fit(scaled)
    print(f"{linkage:8} sizes {sorted(np.bincount(tree.labels_).tolist(), reverse=True)}   "
          f"agreement with k-means {adjusted_rand_score(kmeans.labels_, tree.labels_):.3f}")
```

```
ana@lab:~/ml$ python hierarchy.py
ward     sizes [345, 342, 329, 184]   agreement with k-means 1.000
average  sizes [346, 341, 329, 184]   agreement with k-means 0.998
single   sizes [687, 329, 183, 1]   agreement with k-means 0.646
```

**Ward and average linkage agree with k-means almost exactly.** Three different methods, built on
different ideas, found the same four groups, which is the strongest evidence this lesson can offer that
the groups are in the data.

**Single linkage did something else**: one cluster of 687, which is two groups chained together, and
one cluster of a single customer. That is its known weakness, called **chaining**, and it is also its
use: single linkage is the one that can follow long, thin, winding shapes, and the one that finds the
outlier first.

Hierarchical clustering compares every pair of rows, so its cost grows with the square of the number of
rows. On 1,200 customers that is nothing; on a million it is out of reach, and k-means or a sample is
the answer.
