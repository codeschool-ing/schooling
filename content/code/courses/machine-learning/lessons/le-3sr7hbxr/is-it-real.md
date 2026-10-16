---
title: Is the grouping real?
version: 1
---

With no label, a clustering cannot be scored right or wrong. What can be measured is whether it would
**come back**: a grouping that changes when a few customers are added or removed describes the sample,
not the customers. The test is to refit on parts of the data and see whether the same groups return.
Save this as `stability.py`; it does that for four clusters and for six:

```python
# stability.py
import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.metrics import adjusted_rand_score
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
scaled = StandardScaler().fit_transform(baskets.drop(columns="customer_id"))
rng = np.random.default_rng(0)

for k in [4, 6]:
    full = KMeans(n_clusters=k, n_init=10, random_state=0).fit(scaled)
    agreement = []
    for _ in range(10):
        half = rng.choice(len(scaled), len(scaled) // 2, replace=False)
        part = KMeans(n_clusters=k, n_init=10, random_state=0).fit(scaled[half])
        agreement.append(adjusted_rand_score(full.labels_, part.predict(scaled)))
    print(f"k = {k}: refitted on ten random halves, agreement with the full fit "
          f"from {min(agreement):.3f} to {max(agreement):.3f}")
```

Each half-fit then labels **all** 1,200 customers with `predict`, so its grouping can be compared row by
row with the full fit's.

```
ana@lab:~/ml$ python stability.py
k = 4: refitted on ten random halves, agreement with the full fit from 1.000 to 1.000
k = 6: refitted on ten random halves, agreement with the full fit from 0.812 to 0.980
```

**Four clusters come back exactly** from every half of the data. Six do not: depending on which half is
used, the agreement falls as low as 0.812. The two extra clusters are splits of real groups, drawn
wherever that particular sample happened to be a little thinner, and a newsletter written for one of
them would be written for an accident.

Now the luxury mentioned at the start. `make_data.py` drew these customers from four kinds of household
in proportions 30, 30, 25 and 15 per cent, and the four clusters hold 345, 342, 329 and 184 of 1,200:
29, 29, 27 and 15 per cent. The methods found what was put there. On real data nobody can make that
check, and the stability test, the agreement between methods and a sentence that describes each group
are what stand in for it.

**A cluster is a hypothesis about customers**, and it becomes useful when it is tested the way any
hypothesis is: send the bakery newsletter to a random half of the bakery cluster and a plain one to the other half,
and see whether anything changes.
