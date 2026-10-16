---
title: Reading a linear model's weights
version: 1
---

Three groups of people ask a model to explain itself, and they ask different questions. The retention
team asks **why this subscriber** got a credit. The managers ask **what drives churn** in general. And
whoever is accountable for the model asks **whether it is doing something it should not**, which lesson 20
takes up. This lesson builds the tools for the first two, starting with the model that explains itself
most directly.

A logistic regression's prediction is a sum, so its weights are its explanation. Lesson 15's pipeline
keeps the names of the 36 columns, and the weights come out in the same order. Save this as `weights.py`:

```python
# weights.py
import pandas as pd

from churn_model import build
from feira import by_time, load_churn

train, _ = by_time(load_churn())
model = build().fit(train, train["churned"])
names = model.named_steps["prepare"].get_feature_names_out()
weights = pd.Series(model.named_steps["logistic"].coef_[0], index=names)

numbers = weights[weights.index.str.startswith("numbers__")]
print("numbers, per standard deviation:")
print(numbers.reindex(numbers.abs().sort_values(ascending=False).index[:8]).round(2).to_string())
print("one word column, payment:")
print(weights[weights.index.str.startswith("words__payment")].round(2).to_string())
```

```
ana@lab:~/ml$ python weights.py
numbers, per standard deviation:
numbers__rating_90d       -0.46
numbers__unhappy           0.31
numbers__late_and_new      0.27
numbers__complaints_90d    0.27
numbers__skips_90d         0.23
numbers__gone_quiet        0.18
numbers__tenure_capped    -0.14
numbers__skip_streak       0.14
one word column, payment:
words__payment_boleto   -0.08
words__payment_card     -0.56
words__payment_pix      -0.59
```

**The numbers read as lesson 5 taught**: per standard deviation, in log-odds. A higher rating lowers the
chance most, and five of lesson 14's seven columns are in the top eight, `unhappy` second. The model is
using the shapes it was handed.

**The words need more care.** All three payment weights are negative, which looks as if every way of
paying lowers the chance of leaving. It does not. With one column per value and no value dropped, the
three weights share a constant with the intercept, and only their **differences** mean anything:
boleto's −0.08 against card's −0.56 says that paying by boleto adds about 0.48 to the log-odds, compared
with paying by card. Read a category's weights against each other, never one at a time.

Two more cautions about weights, both from lesson 5 and both still true. A weight is only comparable to
another when the columns are on the same scale, which the pipeline's scaler guarantees for the numbers.
And **correlated columns share their weight**: `rating_90d` and `unhappy` describe the same thing in two
ways, so neither weight alone says how much ratings matter. Together they do.

A boosted model has no weights to read. The rest of the lesson is about explaining models that do not
explain themselves.
