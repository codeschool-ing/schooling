---
title: Customers, products, and a hidden answer
version: 1
---

Feira em Casa sells **add-ons**: flour, coffee, olive oil, sourdough, twenty-two products a customer can
put in the box beside the fruit and vegetables. The app has room for three suggestions, and the question
is which three to show each customer. That is a **recommendation** problem, and its data has a shape of
its own: a table with a row per customer, a column per product, and a 1 where the customer has bought it.

`addons.csv` holds one row per customer and product, with how many times it was added. Recommendation has
no label column to predict, but it can still be tested honestly with a trick: **hide one product each
customer bought, and see whether the recommender suggests it.** If three suggestions often include the
hidden product, the recommender knows something about what people want.

Every program in this lesson uses the same hiding, so it lives in a module. Save this as `holdout.py`:

```python
# holdout.py
"""Hide one add-on from each customer, and count how often a recommender finds it again."""
import numpy as np
import pandas as pd

def split(seed=0):
    addons = pd.read_csv("data/addons.csv")
    bought = pd.crosstab(addons["customer_id"], addons["product"]).clip(upper=1)
    rng = np.random.default_rng(seed)
    known, hidden = bought.copy(), {}
    for customer, row in bought.iterrows():
        owned = row.index[row == 1]
        if len(owned) >= 2:
            hidden[customer] = rng.choice(owned)
            known.loc[customer, hidden[customer]] = 0
    return known, hidden

def hit_rate(scores, known, hidden, k=3):
    hits = 0
    for customer, product in hidden.items():
        candidates = scores.loc[customer].astype(float).where(known.loc[customer] == 0)
        hits += product in candidates.nlargest(k).index
    return hits / len(hidden)
```

`crosstab` builds the customer-by-product table, and `clip(upper=1)` turns counts into bought or not.
`split` hides one product from every customer with at least two, and `hit_rate` gives a recommender a
table of scores, rules out what each customer is already known to buy, and counts how often the hidden
product is among the top three. That number is the **hit rate at 3**.

Now look at the table. Save this as `matrix.py`:

```python
# matrix.py
from holdout import split

known, hidden = split()
per_customer = known.sum(axis=1)
print(f"{known.shape[0]:,} customers x {known.shape[1]} add-ons; {known.values.mean():.1%} of the cells are 1")
print(f"add-ons a customer is known to buy: median {per_customer.median():.0f}, "
      f"from {per_customer.min()} to {per_customer.max()}")
print(f"one add-on hidden from each of {len(hidden):,} customers")
print(known.iloc[:4, :8].to_string())
```

```
ana@lab:~/ml$ python matrix.py
1,491 customers x 22 add-ons; 42.4% of the cells are 1
add-ons a customer is known to buy: median 9, from 1 to 21
one add-on hidden from each of 1,469 customers
product      avocado  butter  cheese  chilli  cocoa  coffee  coriander  eggs
customer_id                                                                 
C00001             1       1       1       0      1       1          0     1
C00002             1       0       0       1      0       1          0     1
C00003             1       1       0       0      0       0          0     0
C00004             1       0       1       1      1       0          1     1
```

**42.4% of the cells are filled**, which is dense for this kind of data: a customer buys nine of
twenty-two add-ons, after one is hidden. A shop with a hundred thousand products and customers who each
buy forty would fill a cell in two and a half thousand, and most of what is hard about recommendation at
scale comes from that emptiness. The ideas in this lesson are the same at either density; the arithmetic
here is small enough to watch.
