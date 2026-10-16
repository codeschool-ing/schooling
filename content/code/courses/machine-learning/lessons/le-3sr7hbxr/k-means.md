---
title: k-means
version: 1
---

**k-means** is the clustering algorithm everybody meets first, and it is simple enough to run by hand.

1. Choose *k*, the number of groups, and place *k* centres somewhere among the rows.
2. Give every row to its nearest centre.
3. Move each centre to the average of the rows it was given.
4. Repeat 2 and 3 until nothing moves.

Each round can only make the rows closer to their centres, so it always stops. Where it stops depends on
where the centres started, so scikit-learn starts it `n_init` times from different places and keeps the
best. The **inertia** is what *best* means: the total squared distance from each row to its centre.

Distance is the heart of it, so every column must count in comparable units, which is what lesson 5's
`StandardScaler` does. The next section shows what happens without it. Save this as `kmeans.py`; it asks
for four groups, a number the next section after that questions:

```python
# kmeans.py
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
X = baskets.drop(columns="customer_id")
scaled = StandardScaler().fit_transform(X)

kmeans = KMeans(n_clusters=4, n_init=10, random_state=0).fit(scaled)
baskets["cluster"] = kmeans.labels_
profile = baskets.groupby("cluster")[X.columns].mean().round(1)
profile.insert(0, "customers", baskets["cluster"].value_counts().sort_index())
print(profile.to_string())
```

The clustering happens on the scaled columns; the profile averages the **original** columns, in reais and
points, because that is what a person can read.

```
ana@lab:~/ml$ python kmeans.py
         customers  orders_month  avg_basket  fruit  vegetables  greens  eggs_dairy  bakery  extras
cluster                                                                                            
0              342           3.5       210.0   15.2        39.5    25.0        10.3     4.9     5.1
1              184           1.2       327.4   20.1        20.1    14.9        14.7    10.3    19.9
2              345           1.9       139.8   44.9        25.4     9.8         9.9     5.1     5.0
3              329           4.0       261.1   15.1        19.9     9.8        20.1    24.9    10.2
```

Four groups, and each can be described in a sentence, which is the first test a clustering must pass:

| cluster | customers | in a sentence |
|---|---|---|
| 0 | 342 | frequent, mid-sized baskets, heavy on **vegetables and greens** |
| 1 | 184 | **rare, large** orders, about R$ 327, with a fifth spent on extras |
| 2 | 345 | small baskets, nearly half of it **fruit** |
| 3 | 329 | the most frequent, with a quarter on **bakery** and a fifth on eggs and dairy |

The numbers 0 to 3 mean nothing. They are the order in which the algorithm happened to number its
centres, and a different `random_state` could swap them. Name the groups by what they hold, as the right
column does, and the marketing team has four newsletters to write.

Whether four is the right number, and whether these groups would come back from another sample of
customers, are the questions the following sections answer.
