---
title: PCA, the directions of greatest spread
version: 1
---

**Principal component analysis** looks for the direction through the cloud of rows along which they are
most spread out, and calls it the first component. Then it looks for the direction of greatest spread
that is at right angles to the first, the second component, and so on, until there are as many
components as columns. Each component is a weighted sum of the original columns, and together they
describe the data exactly; the point is that the first few usually describe most of it.

Save this as `pca.py`; it fits every component and prints how much of the total variation each one
carries:

```python
# pca.py
import pandas as pd
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
X = baskets.drop(columns="customer_id")
pca = PCA().fit(StandardScaler().fit_transform(X))

print("component   share of the variation   running total")
for i, (share, total) in enumerate(zip(pca.explained_variance_ratio_,
                                       pca.explained_variance_ratio_.cumsum()), start=1):
    print(f"{i:9}   {share:22.1%}   {total:13.1%}")
weights = pd.DataFrame(pca.components_[:2].T, index=X.columns, columns=["first", "second"])
print(weights.round(2).to_string())
```

```
ana@lab:~/ml$ python pca.py
component   share of the variation   running total
        1                    42.7%           42.7%
        2                    27.8%           70.4%
        3                    18.3%           88.7%
        4                     4.1%           92.8%
        5                     3.5%           96.3%
        6                     2.1%           98.4%
        7                     1.6%          100.0%
        8                     0.0%          100.0%
              first  second
orders_month   0.15   -0.45
avg_basket     0.42   -0.16
fruit         -0.30    0.54
vegetables    -0.35   -0.44
greens        -0.20   -0.52
eggs_dairy     0.45   -0.01
bakery         0.47   -0.02
extras         0.36    0.14
```

**Three components carry 88.7% of the variation in eight columns.** Two carry 70.4%, enough for a
picture that leaves out less than a third of what is there. After the third, each component adds a few
per cent, which is detail, and some of it noise.

**The eighth component carries nothing at all, 0.0%.** That is not chance. The six shares add up to 100
for every customer, so once five of them are known the sixth is too: the data has only seven dimensions
dressed as eight. PCA found that without being told. Any time a component carries exactly nothing, two or
more columns are repeating each other, and that is worth knowing before any model is fitted.

The bottom table is the next section's subject: what the first two components are made of.
