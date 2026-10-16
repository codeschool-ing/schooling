---
title: Recommending from what a customer already buys
version: 1
---

With a similarity between every pair of products, a customer's recommendations are a sum: **for each
product they do not buy, add up its similarity to every product they do.** A customer who buys flour,
butter and cocoa gives yeast three large similarities and coffee three small ones, so yeast comes first.
That is **item-based collaborative filtering**, and in matrix form it is one multiplication: the
customer's row of ones times the similarity table. Save this as `item_based.py`:

```python
# item_based.py
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity

from holdout import hit_rate, split

known, hidden = split()
similarity = cosine_similarity(known.T)
np.fill_diagonal(similarity, 0)
scores = pd.DataFrame(known.values @ similarity, index=known.index, columns=known.columns)
popular = pd.DataFrame([known.sum()] * len(known), index=known.index)

print(f"most popular not yet bought:  {hit_rate(popular, known, hidden):.1%}")
print(f"most similar to what they buy: {hit_rate(scores, known, hidden):.1%}")
```

The similarities are computed from `known`, with every customer's hidden product already removed, so the
recommender never sees the answer it is being tested on. Computing them from the full table would be lesson
4's leak in a new costume.

```
ana@lab:~/ml$ python item_based.py
most popular not yet bought:  41.2%
most similar to what they buy: 66.0%
```

**66.0% against 41.2%.** Recommending what goes with what a customer already buys finds the hidden add-on
in two cases out of three, against two in five for popularity. The gain comes from the cuisines: once the
recommender knows someone bakes, the next baking product is a far better guess than the best-seller.

Item-based filtering has properties that explain why it has lasted. **It explains itself**: *"because you
buy flour"* is a sentence the app can show. **It is cheap**: the similarity table has one row per product,
not per customer, and changes slowly. And **it needs a history**, which is the subject of the last section.
