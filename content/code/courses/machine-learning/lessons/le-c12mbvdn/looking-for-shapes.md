---
title: Looking for shapes
version: 1
---

A model only sees the columns it is given. Lesson 5's logistic regression was given the columns of
`churn.csv` as they came, and it made R$ 16,424 on the test months where lesson 2's gradient boosting, reading the categories directly, made R$ 21,672. Part of that gap is the kind of model. A sum of weighted columns can only say *more of
this, more risk*, in a straight line, while a tree can say *above this point, suddenly much more*.
But the trees did not know anything the line could not have been told. **Feature engineering is the
telling**: making columns that hand a simpler model the shapes it cannot find on its own.

The shapes come from looking. Group the training rows by a column, in bands, and see how the share
who cancel changes across them. Save this as `shapes.py`:

```python
# shapes.py
import pandas as pd

from feira import by_time, load_churn

train, _ = by_time(load_churn())
for column, edges in [("rating_90d", [1, 3, 3.4, 3.6, 3.8, 4, 4.5, 5.01]),
                      ("skips_90d", [0, 1, 2, 3, 4, 8]),
                      ("days_since_login", [0, 7, 14, 21, 28, 40, 103])]:
    groups = train.groupby(pd.cut(train[column], edges, right=False), observed=True)
    rates = groups["churned"].agg(cancelled="mean", rows="size")
    print(rates.round(3).to_string(), end="\n\n")
```

`pd.cut` puts each value in a band; `right=False` makes each band include its left edge, so `[3, 4)`
is three skips and not four. Only the training months are read: a shape found by looking at the test
months is a choice made with the answers, which lesson 3 ruled out.

```
ana@lab:~/ml$ python shapes.py
             cancelled   rows
rating_90d                   
[1.0, 3.0)       0.412    284
[3.0, 3.4)       0.294   1175
[3.4, 3.6)       0.233   1713
[3.6, 3.8)       0.076   3278
[3.8, 4.0)       0.059   4955
[4.0, 4.5)       0.034  15016
[4.5, 5.01)      0.018   9102

           cancelled   rows
skips_90d                  
[0, 1)         0.037  17892
[1, 2)         0.054  12791
[2, 3)         0.075   5590
[3, 4)         0.167   1707
[4, 8)         0.224    648

                  cancelled   rows
days_since_login                  
[0, 7)                0.044  11543
[7, 14)               0.053  10531
[14, 21)              0.052   4400
[21, 28)              0.126   1465
[28, 40)              0.130    648
[40, 103)             0.212    208
```

None of the three is a straight line.

**The rating has a cliff.** From 3.6 up, the share who cancel falls gently, from 7.6% to 1.8%. Below
3.6 it jumps to 23% and more. A logistic regression gives `rating_90d` one weight, the same for the
step from 4.5 to 4.0 as for the step from 3.7 to 3.5, and the second matters about ten times as much.

**Skips have a threshold.** Each skip adds a little, until three, where the share more than doubles:
7.5% at two skips, 16.7% at three. Three skips in ninety days is a person who has stopped wanting
the box.

**So does the app.** Logging in every week or every fortnight makes no difference, 4 to 5%. After
three weeks without opening the app, the share is two and a half times higher.

Each of these is a **flag** waiting to be made: a column that is 1 below the cliff and 0 above it.
A tree finds such a split by itself, which is what it does for a living. A line has to be handed it,
and the next section hands it over.

Two cautions belong here. A shape found in a table of bands can be noise: these bands hold hundreds
or thousands of rows each, so they are not, but a band with thirty rows deserves suspicion. And a
shape is only a feature if it would be visible **at the moment of prediction**. Lesson 4's
`days_since_last_order` had a beautiful shape and was the future in disguise.
