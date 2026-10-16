---
title: What a component means
version: 1
---

A component is a weighted sum of the scaled columns, and its weights, the **loadings**, say what it
measures. `pca.py` printed them for the first two:

| column | first | second |
|---|---|---|
| orders_month | 0.15 | **−0.45** |
| avg_basket | **0.42** | −0.16 |
| fruit | −0.30 | **0.54** |
| vegetables | −0.35 | **−0.44** |
| greens | −0.20 | **−0.52** |
| eggs_dairy | **0.45** | −0.01 |
| bakery | **0.47** | −0.02 |
| extras | 0.36 | 0.14 |

Read each column of weights for its largest numbers, and their signs.

**The first component is "bakery, dairy and big baskets" against "fresh produce".** Bakery, eggs and
dairy, extras and the basket size weigh positive; fruit, vegetables and greens weigh negative. A customer
far along it buys bread, cheese and extras in large orders; far the other way, mostly produce.

**The second is "fruit" against "vegetables, greens and frequent orders".** It separates the two kinds of
produce buyer that the first component lumped together: lesson 16's fruit cluster and its greens
cluster.

So the two components are close to two of the questions the marketing team would ask anyway, which is
luck rather than a property of PCA. A component is whatever direction has the most spread, and on other
data it can be a mixture nobody can name. **The sign is arbitrary too**: another run, or another library,
may flip a component so that every weight changes sign, and it means exactly the same.

That is PCA's real advantage over the two methods that follow: **its axes can be read.** Every point on a
PCA picture has a position that can be explained in terms of the original columns, and a new customer can
be placed by the same arithmetic. Neither is true of t-SNE.
