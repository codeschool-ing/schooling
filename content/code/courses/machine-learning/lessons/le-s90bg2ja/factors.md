---
title: Hidden tastes: matrix factorisation
version: 1
---

The similarity table compared products two at a time. **Matrix factorisation** looks for a few hidden
tastes that explain the whole table at once. Each customer gets a few numbers saying how much of each
taste they have, and each product a few numbers saying how much it appeals to each taste. Multiplied
together, the two rebuild the table and fill the empty cells with a guess. Those guesses are the recommendations.

It is lesson 17's idea applied to a different table. `TruncatedSVD` is a close relative of PCA that works
on a table of zeros and ones without centring it, and `NMF`, non-negative matrix factorisation, does the
same with every number kept at zero or above, which makes the tastes easier to read. Save this as
`factors.py`; it rebuilds the table with several numbers of tastes and reads the NMF version with three:

```python
# factors.py
import pandas as pd
from sklearn.decomposition import NMF, TruncatedSVD

from holdout import hit_rate, split

known, hidden = split()
for k in [2, 3, 4, 6]:
    svd = TruncatedSVD(n_components=k, random_state=0).fit(known)
    rebuilt = pd.DataFrame(svd.transform(known) @ svd.components_, index=known.index,
                           columns=known.columns)
    print(f"{k} factors: finds the hidden add-on {hit_rate(rebuilt, known, hidden):.1%}")

nmf = NMF(n_components=3, random_state=0, max_iter=500).fit(known)
for i, weights in enumerate(nmf.components_):
    top = pd.Series(weights, index=known.columns).nlargest(6)
    print(f"factor {i}: " + ", ".join(top.index))
```

```
ana@lab:~/ml$ python factors.py
2 factors: finds the hidden add-on 55.8%
3 factors: finds the hidden add-on 69.3%
4 factors: finds the hidden add-on 67.6%
6 factors: finds the hidden add-on 60.7%
factor 0: chilli, garlic, coriander, olive oil, lime, ginger
factor 1: papaya, coffee, honey, jam, yoghurt, granola
factor 2: flour, vanilla, cocoa, butter, oats, yeast
```

**Three factors find the hidden add-on 69.3% of the time**, the best result in the lesson. Two are too few
to describe the customers, and with four or six the extra factors start fitting the particular gaps of
these customers rather than their tastes, and the hit rate falls again: lesson 3's overfitting, in a
recommender.

The NMF factors are the reason three works. **Factor 0 is cooking, factor 1 breakfast, factor 2 baking**,
the same three cuisines `similar.py` found, now as dimensions every customer has a position on. And they
are what `make_data.py` put there: lesson 1's generator gave each buyer a liking for baking, breakfast
and cooking, plus four products everybody buys. As with lesson 16's clusters, a real shop would have no
such page to check against; the hit rate and the readable factors are what stand in for it.

Factorisation has a cost item-based filtering does not: **a customer's factors come from their row**, so a
new customer must be fitted before they can be recommended to, and the factors stop explaining themselves
in a sentence. Many production systems use both, factors to rank and similarities to say why.
