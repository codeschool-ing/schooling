---
title: The credit, by age
version: 1
---

The churn model decides who gets R$ 40 off a box. That is a small benefit, handed out by a machine, and
some people get it and others do not. **Fairness** asks whether the line between them falls along a
characteristic that should not decide such things: age, sex, race, religion, disability, the
characteristics that law and ordinary decency treat as **protected**. `churn.csv` has one of them, `age`,
and every model since lesson 2 has read it.

The first step is to look, before arguing about anything. Split the test months into age bands and ask
four things of each: how many left, what share got a credit, what share of the leavers got one (lesson
10's **recall**), and what share of the credits reached a leaver (its **precision**). And do it twice:
once with `age` among the columns, as every lesson has done, and once without it, which is what most
people's first instinct says to do. Save this as `by_age.py`:

```python
# by_age.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
band = pd.cut(test["age"], [17, 24, 34, 49, 64, 99], labels=["18-24", "25-34", "35-49", "50-64", "65+"])
without_age = [c for c in NUMERIC if c != "age"] + CATEGORICAL

for name, features in [("with age", NUMERIC + CATEGORICAL), ("without age", without_age)]:
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(train[features], train["churned"])
    send = model.predict_proba(test[features])[:, 1] >= CREDIT / (SAVED * KEPT)
    rows = test.assign(send=send, band=band)
    groups = rows.groupby("band", observed=True)
    table = pd.DataFrame({
        "subscribers": groups.size(),
        "left": groups["churned"].mean(),
        "credited": groups["send"].mean(),
        "recall": groups.apply(lambda g: g.loc[g["churned"] == 1, "send"].mean()),
        "precision": groups.apply(lambda g: g.loc[g["send"], "churned"].mean()),
    })
    print(f"{name}: net value R$ {net_value(test['churned'], send):,.0f}")
    print(table.round(3).to_string(), end="\n\n")
```

```
ana@lab:~/ml$ python by_age.py
with age: net value R$ 21,672
       subscribers   left  credited  recall  precision
band                                                  
18-24         2572  0.074     0.039   0.267      0.505
25-34         6109  0.052     0.026   0.216      0.439
35-49        11220  0.059     0.028   0.234      0.492
50-64         3987  0.071     0.033   0.240      0.519
65+            369  0.073     0.019   0.185      0.714

without age: net value R$ 21,336
       subscribers   left  credited  recall  precision
band                                                  
18-24         2572  0.074     0.027   0.194      0.536
25-34         6109  0.052     0.025   0.219      0.458
35-49        11220  0.059     0.028   0.241      0.502
50-64         3987  0.071     0.034   0.230      0.485
65+            369  0.073     0.033   0.259      0.583
```

Start with the first table, the model as it has been all along. **The youngest band leaves most**, 7.4%,
and the model knows it: they get the most credits, 3.9%, and the highest recall among the large bands. The
oldest band leaves almost as often, 7.3%, and gets the fewest credits, 1.9%.

Read that last row with care. **The 65+ band has 369 subscribers and about 27 leavers in six months**, so
its recall of 0.185 is five people, and its precision of 0.714 is five of seven. A difference measured on
a handful of people is not yet evidence of anything, in either direction. That is a fairness problem of
its own: the groups most likely to be treated unusually are often the smallest, where nothing can be
measured with confidence.

Now the second table. Taking `age` out cost R$ 336 in net value, which is noise, and changed who gets the
credit: the youngest band drops from 3.9% to 2.7%, and its recall from 0.267 to 0.194; the oldest band rises.
The next section is about why removing the column did that, and why it did not remove age.
