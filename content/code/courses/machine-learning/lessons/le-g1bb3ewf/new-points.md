---
title: Placing a customer who joined tomorrow
version: 1
---

A map of today's customers is a picture. A map that tomorrow's customers can be placed on is a tool: the
marketing team can see where a new subscriber lands, and a model downstream can use the map's two
coordinates as columns. That needs the method to have a `transform`, the half of lesson 15's contract
that applies what was learned to new rows. Save this as `new_points.py`; it learns each map from the
first 1,000 customers and tries to place the last 200:

```python
# new_points.py
import pandas as pd
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE
from sklearn.preprocessing import StandardScaler
from umap import UMAP

baskets = pd.read_csv("data/baskets.csv")
scaled = StandardScaler().fit_transform(baskets.drop(columns="customer_id"))
known, new = scaled[:1000], scaled[1000:]

for name, method in [("PCA", PCA(n_components=2)), ("UMAP", UMAP(random_state=0, n_jobs=1)),
                     ("t-SNE", TSNE(random_state=0))]:
    method.fit(known)
    if hasattr(method, "transform"):
        print(f"{name:6} placed {len(method.transform(new))} new customers on the map it learned")
    else:
        print(f"{name:6} has no transform: a new customer means drawing the whole map again")
```

The scaler here is fitted on all 1,200 rows. That shortcut is harmless for a picture and would be the
preparation leak of lesson 4 if the map fed a model. Inside a pipeline, as lesson 15 built, it would be
fitted on the first 1,000 only.

```
ana@lab:~/ml$ python new_points.py
PCA    placed 200 new customers on the map it learned
UMAP   placed 200 new customers on the map it learned
t-SNE  has no transform: a new customer means drawing the whole map again
```

**t-SNE cannot place a new point.** It does not learn a function from eight columns to two; it arranges
the particular rows it was given, and the arrangement has no meaning for a row that was not there. Add
one customer and the only option is to draw the whole map again, and the new map may come out rotated,
flipped or rearranged.

**PCA places new points exactly**, by the same weighted sums, and **UMAP approximately**, by finding the
new customer's neighbours among the ones it learned from. So the division of labour is clear:

| method | the picture | new rows | axes that mean something | speed |
|---|---|---|---|---|
| PCA | adequate | exact | yes | instant |
| t-SNE | good | no | no | slow on large data |
| UMAP | good | approximate | no | slow to start, scales better than t-SNE |
