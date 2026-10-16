---
title: The test, once, and what it says
version: 1
---

Three searches, each reporting its best on the validation months. **Those best scores are
optimistic**, all of them, for the reason lesson 2 gave about the best of five rules: the winner of a
search is partly the setting that was best and partly the one that was luckiest on those three
months. The more settings a search tries, the more its best score owes to luck. The only honest number
for the chosen setting comes from rows that played no part in choosing it.

So the setting chosen, the Bayesian search's, is fitted once on all twelve training months and scored
once on the six test months, beside the defaults, with lesson 2's bootstrap on the difference. Save
this as `test_once.py`:

```python
# test_once.py
import numpy as np

from feira import CREDIT, KEPT, SAVED, by_time, load_churn, net_value
from tuning import FEATURES, booster

train, test = by_time(load_churn())
models = {"defaults": booster(),
          "tuned": booster(learning_rate=0.124, max_leaf_nodes=4, max_iter=150)}
send = {}
for name, model in models.items():
    model.fit(train[FEATURES], train["churned"])
    send[name] = model.predict_proba(test[FEATURES])[:, 1] >= CREDIT / (SAVED * KEPT)
    print(f"{name:8} R$ {net_value(test['churned'], send[name]):,.0f} on the test months")

rng = np.random.default_rng(0)
rows = test.groupby("customer_id").indices
people = list(rows)
y = test["churned"].to_numpy()
gaps = []
for _ in range(1000):
    idx = np.concatenate([rows[people[i]] for i in rng.choice(len(people), len(people))])
    gaps.append(net_value(y[idx], send["tuned"][idx]) - net_value(y[idx], send["defaults"][idx]))
low, high = np.percentile(gaps, [2.5, 97.5])
print(f"tuned minus defaults: 95% of resamples between R$ {low:,.0f} and R$ {high:,.0f}")
```

```
ana@lab:~/ml$ python test_once.py
defaults R$ 21,248 on the test months
tuned    R$ 22,464 on the test months
tuned minus defaults: 95% of resamples between R$ -1,001 and R$ 3,457
```

**The tuned model makes R$ 22,464 against R$ 21,248 for the defaults: R$ 1,216 more over six months.** The
defaults here are `booster()`'s, with early stopping off, which is why they make R$ 21,248 and not lesson
2's R$ 21,672.
On the validation months the gap looked larger, R$ 846 against R$ 610 per thousand rows, which would be
over R$ 5,000 on the test months' 24,257 rows. Some of that was the luck of the search, and it stayed
behind.

And the interval for the difference runs **from −R$ 1,001 to R$ 3,457**. It crosses zero. On this
data, tuning probably helps a little, and the test cannot rule out that it does not help at all. That
is the situation lesson 2 described: a model that beats another by less than the noise of the
measurement.

That is not a reason to skip tuning. It is a reason to **report it honestly**: the tuned model is the
better bet, by roughly a thousand reais a semester, with wide uncertainty. And it is a reason to stop
tuning here. Another search, on the same three validation months, would chase smaller gains through
even more luck.

## Nested cross-validation

The question *how good is a model whose settings were tuned?* can also be answered without a separate
test, by **nesting**: an outer cross-validation, and inside each outer training fold a complete search
with its own inner folds. The outer score then measures the whole procedure, search included, on rows
the search never saw. It costs the number of outer folds times the cost of a search, and it is the
right tool when there is too little data to keep a test set aside. With six months held back, Ana does
not need it.
