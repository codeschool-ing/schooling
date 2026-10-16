---
title: Learning without a label
version: 1
---

Every model so far had an answer to learn from: `churned`, `minutes`, `complaint`. The marketing team
now asks a question with no answer column at all: *"what kinds of customers do we have?"*. They want
to write a different newsletter for each kind, and nobody has ever labelled a customer as a kind.

That is **unsupervised learning**: finding structure in rows with no label to check it against. Its
most common form is **clustering**, putting rows into groups so that rows in a group are alike and rows
in different groups are not. What *alike* means is a choice, and most of this lesson is about making it
on purpose.

The data is `baskets.csv`, one row per customer: how many orders a month, the average basket in reais,
and what share of their spending goes on each kind of food. Save this as `baskets.py`:

```python
# baskets.py
import pandas as pd

baskets = pd.read_csv("data/baskets.csv")
print(f"{len(baskets):,} customers, {baskets.shape[1] - 1} columns, no label")
print(baskets.drop(columns="customer_id").describe().loc[["mean", "std", "min", "max"]].round(1)
      .to_string())
```

```
ana@lab:~/ml$ python baskets.py
1,200 customers, 8 columns, no label
      orders_month  avg_basket  fruit  vegetables  greens  eggs_dairy  bakery  extras
mean           2.8       221.8   24.5        27.1    14.9        13.6    11.3     8.7
std            1.1        68.8   13.7         9.2     7.4         5.5     9.1     5.9
min            0.5        67.7    5.0         7.9     3.0         3.4     0.9     0.6
max            5.0       395.8   60.2        58.0    38.8        31.3    37.2    31.5
```

Two kinds of column. `orders_month` and `avg_basket` say how much a customer buys; the six shares say
what, and add up to 100 for every customer. Their units differ wildly: a basket varies by R$ 68.8 from
one customer to the next, a share of eggs by 5.5 points, orders by 1.1 a month. That difference will
matter in two sections' time.

**Without a label there is no test set**, and that changes what can be claimed. A churn model is right
or wrong on the test months. A clustering is neither: it is a proposal about how to see the customers,
and it is judged by whether it is stable, whether it can be described, and whether anybody can act on
it. This lesson measures the first and practises the other two.

There is one luxury here that real data never offers. Lesson 1's `make_data.py` drew these customers
from four kinds of household, and lesson 1's section *Your data, from a program you can read* shows how. A real marketing team would have
no such page to check against, and the lesson does not lean on it until the end.
