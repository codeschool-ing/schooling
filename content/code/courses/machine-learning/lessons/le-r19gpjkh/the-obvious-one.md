---
title: The column that is the answer
version: 1
---

`churn.csv` has a column called `cancel_reason`. It is the kind of column a data scientist is glad
to find: the reason a subscriber gave for leaving, *price*, *quality*, *delivery*, *moving* or
*other*. It is surely useful. Save this as `obvious.py`:

```python
# obvious.py
import pandas as pd

churn = pd.read_csv("data/churn.csv")
reason = churn["cancel_reason"].fillna("(empty)")
print(pd.crosstab(reason, churn["churned"]))
```

```
ana@lab:~/ml$ python obvious.py
churned            0     1
cancel_reason             
(empty)        59200     0
delivery           0   725
moving             0   546
other              0   559
price              0  1092
quality            0   763
```

**Every row with a reason is a leaver, and every leaver has a reason.** The column is not a
predictor of the target; it is the target, spelt in words. It is filled in when the subscriber
cancels, which is after the snapshot, and on the first of the month, when the credit is sent, it is
empty for everybody. A model given it would score perfectly and would, in use, see an empty column
for every row and predict nothing.

Nobody would ship this one, and that is the point of starting with it: it shows the shape of every
leak at full size. **A column written because of the outcome carries the outcome.** The same shape,
smaller, is behind most of the ones that do get shipped:

- a *refund issued* flag, in a model of who will complain;
- a *collections agency assigned* date, in a model of who will default;
- an *ICU admission*, in a model of which patients are seriously ill;
- the *number of follow-up calls*, in a model of which sales leads will close.

Each one is recorded by somebody reacting to the outcome, and each is known, at the moment of
prediction, to be empty or zero.

## What to do with it

Leave it out of the model, and keep it. `cancel_reason` is useless for predicting who will leave
and valuable for understanding why people left, which is a different project with a different
deliverable: a chart for the people who decide the price, rather than a list for the retention
team. A column that leaks is a column in the wrong question.
