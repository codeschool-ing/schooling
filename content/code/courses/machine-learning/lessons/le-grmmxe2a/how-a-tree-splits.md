---
title: Twenty questions, asked by the data
version: 1
---

A decision tree predicts by asking questions, one at a time, each about one column: *is the rating
at most 3.6?* If yes, go left; if no, go right; and ask the next question there. At the end of the
path is a **leaf**, a group of training rows that answered every question the same way, and the
prediction is whatever those rows did: the share of leavers among them, for a classifier.

The questions are not written by anyone. Fitting chooses them, from the top down: at each step, try
every column and every place to cut it, and keep the one cut that separates the classes best. Then
do the same again inside each of the two halves. The choice is **greedy**: each cut is the best one
available at that moment, with no looking ahead to whether a worse cut now would allow better ones
later.

A tree two questions deep is small enough to print whole. `DecisionTreeClassifier` in scikit-learn
1.9 accepts gaps in the numeric columns and decides, at each cut, which side the empty values go to,
so the columns go in as they are. Save this as `first_tree.py`:

```python
# first_tree.py
from sklearn.tree import DecisionTreeClassifier, export_text

from feira import NUMERIC, by_time, load_churn

train, test = by_time(load_churn())
tree = DecisionTreeClassifier(max_depth=2, random_state=0)
tree.fit(train[NUMERIC], train["churned"])
print(export_text(tree, feature_names=NUMERIC, show_weights=True))
```

```
ana@lab:~/ml$ python first_tree.py
|--- rating_90d <= 3.60
|   |--- complaints_90d <= 0.50
|   |   |--- weights: [1861.00, 525.00] class: 0
|   |--- complaints_90d >  0.50
|   |   |--- weights: [543.00, 353.00] class: 0
|--- rating_90d >  3.60
|   |--- skips_90d <= 2.50
|   |   |--- weights: [32333.00, 1091.00] class: 0
|   |--- skips_90d >  2.50
|   |   |--- weights: [1690.00, 232.00] class: 0
```

The first question is the **rating**, and it is the same split the best single rule found in lesson
2: at or below 3.6, on one side. The second question differs by side. Among people with low ratings
the tree asks about **complaints**; among people with good ratings, about **skips**. That is
something no single rule could do: a different follow-up question for each kind of subscriber.

The `weights` are the training rows in each leaf, stayers first and leavers second. The leaf of low
ratings and at least one complaint holds 543 stayers and 353 leavers, so the tree's chance of leaving
there is 353 ÷ 896, about **39%**. Every leaf says `class: 0`, *stays*, because in every leaf the
stayers are the majority. **A tree's predicted class hides almost everything; its probabilities are
the useful part**, and at the 28% break-even from lesson 2, the 39% leaf is worth sending a credit
to.
