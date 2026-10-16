---
title: The cold start
version: 1
---

Every recommender in this lesson learns from history, and history is exactly what a new customer or a new
product lacks. That is the **cold start**, and it comes in two forms.

**A new customer** has bought little or nothing, so there is nothing to be similar to and no row to
factorise. How much history is enough can be measured: split the customers by how many add-ons they are
known to buy, and compare the two recommenders within each group. Save this as `cold_start.py`:

```python
# cold_start.py
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity

from holdout import hit_rate, split

known, hidden = split()
similarity = cosine_similarity(known.T)
np.fill_diagonal(similarity, 0)
similar = pd.DataFrame(known.values @ similarity, index=known.index, columns=known.columns)
popular = pd.DataFrame([known.sum()] * len(known), index=known.index)

count = known.sum(axis=1)
print("add-ons known   customers   popular   similar")
for low, high in [(1, 3), (3, 6), (6, 23)]:
    group = {c: p for c, p in hidden.items() if low <= count[c] < high}
    print(f"{low:>4} to {high - 1:<6} {len(group):11,} {hit_rate(popular, known, group):9.1%}"
          f" {hit_rate(similar, known, group):9.1%}")
```

```
ana@lab:~/ml$ python cold_start.py
add-ons known   customers   popular   similar
   1 to 2               74     16.2%     24.3%
   3 to 5              181     23.2%     35.4%
   6 to 22           1,214     45.4%     73.1%
```

**With one or two known add-ons, every recommender struggles**: 16.2% for popularity, 24.3% for
similarity. With six or more, similarity finds the hidden product 73.1% of the time. Similarity still
beats popularity at every level, even with one product known: a single purchase of flour says a lot.
But the gap and the level both grow with history, and for a customer with nothing at all, similarity has
no input and popularity is all there is.

**A new product** is the harder form. Nobody has bought it, so its column is all zeros: no similarity to
anything, no factor loadings, never recommended, so never bought, so never recommended. Collaborative
filtering cannot break that loop by itself.

What breaks it is information that does not come from purchases:

- **Ask.** A new customer who picks *"I bake"* at sign-up starts with a taste instead of a blank.
- **Describe the product.** A new spice can borrow the neighbours of the products it most resembles, by
  category, by ingredients, by price. That is **content-based** recommendation, and combined with
  collaborative filtering it is called a hybrid.
- **Explore on purpose.** Show the new product to a small, random share of customers for a while, so
  that it collects the history it needs. Some revenue is spent on learning, and it is a decision to make
  deliberately rather than leave to chance.

For Feira em Casa the plan follows from the table: popularity for customers with fewer than three add-ons,
item similarity from three on, a sign-up question to shorten the first stage, and every new product shown
to one customer in twenty for its first month.
