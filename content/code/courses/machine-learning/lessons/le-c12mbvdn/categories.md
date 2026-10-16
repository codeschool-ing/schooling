---
title: Categories as numbers
version: 1
---

A model does arithmetic, so a column of words has to become numbers, and there are three ways to do it
that a data scientist meets every week.

**One-hot encoding** makes one 0-or-1 column per value: `box_small`, `box_medium`, `box_large`. It
assumes nothing about the values, which is right for `city` or `payment`, where no order exists. It is
what `get_dummies` did in lesson 5. scikit-learn's version, `OneHotEncoder`, does one thing more: **it remembers the columns it made**, so a value it never saw while fitting
gets zeros everywhere instead of a new column that the model has never heard of.

**Ordinal encoding** replaces each value by its position in an order you give it: small 0, medium 1,
large 2. One column instead of three, and a linear model can then say *each size up adds this much
risk*. It is only right when the order is real and roughly even. Encoding `city` this way would
invent an order of cities.

**Target encoding** replaces each value by the share of positives among the training rows that have
it: in the training months São Paulo becomes 0.049, Rio de Janeiro 0.079, and so on. It turns a column with thousands of values, such as
a postcode, into one number. It is also the encoder most likely to leak, because each row's own label is
inside the average it is given. scikit-learn's `TargetEncoder` avoids that by computing each row's value
from the other folds only, the folds of lesson 3, and it is worth using rather than writing the
`groupby` by hand.

The difference between the first two is easiest to see on two new rows, one of them with a plan that
did not exist when the encoder was fitted. In 2026 Feira em Casa launches a **monthly** plan, and
`churn_2026.csv` has it. Save this as `encoders.py`:

```python
# encoders.py
import pandas as pd
from sklearn.preprocessing import OneHotEncoder, OrdinalEncoder

train = pd.DataFrame({"box": ["small", "large", "medium", "small"],
                      "plan": ["weekly", "fortnightly", "weekly", "weekly"]})
new = pd.DataFrame({"box": ["medium", "large"], "plan": ["fortnightly", "monthly"]})

one_hot = OneHotEncoder(handle_unknown="ignore", sparse_output=False).fit(train)
print(pd.DataFrame(one_hot.transform(new), columns=one_hot.get_feature_names_out()), end="\n\n")

order = OrdinalEncoder(categories=[["small", "medium", "large"]]).fit(train[["box"]])
print(new.assign(box_order=order.transform(new[["box"]])[:, 0]))
```

```
ana@lab:~/ml$ python encoders.py
   box_large  box_medium  box_small  plan_fortnightly  plan_weekly
0        0.0         1.0        0.0               1.0          0.0
1        1.0         0.0        0.0               0.0          0.0

      box         plan  box_order
0  medium  fortnightly        1.0
1   large      monthly        2.0
```

The second new row has `plan_fortnightly` and `plan_weekly` both 0. **The model will read the monthly
plan as "neither of the plans I know"**, which is the honest thing to say about it, rather than
crashing or quietly growing a column. `handle_unknown="ignore"` is what allows that; the default is
to raise an error, which is the right default while developing and the wrong one at three in the
morning when a new plan appears. Lesson 15 runs the whole churn model on `churn_2026.csv` and meets
exactly this.

And `box_order` puts small, medium and large at 0, 1 and 2 because the list said so. Without the
`categories` argument the encoder would have sorted them alphabetically, large 0, medium 1, small 2,
an order that happens to be backwards here and could be anything on another column.

For trees, encoding matters less. `HistGradientBoostingClassifier` takes categories directly, as every
lesson since lesson 2 has done with `categorical_features="from_dtype"`, and finds its own grouping of
the values at each split.
