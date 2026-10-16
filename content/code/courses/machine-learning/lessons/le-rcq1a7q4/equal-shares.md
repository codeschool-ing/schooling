---
title: What equal treatment costs
version: 1
---

Suppose somebody insists on demographic parity: every age band gets credits at the same rate. It can be
done without retraining anything, by giving each band its own cut, set so that the same share of each band
is above it. The cost of doing so is then a number, and putting numbers on the options is what turns an
argument about fairness into a decision. Save this as `parity.py`:

```python
# parity.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
model.fit(train[features], train["churned"])
chance = pd.Series(model.predict_proba(test[features])[:, 1], index=test.index)
band = pd.cut(test["age"], [17, 24, 34, 49, 64, 99], labels=["18-24", "25-34", "35-49", "50-64", "65+"])

one_cut = chance >= CREDIT / (SAVED * KEPT)
share = one_cut.mean()
equal = chance >= chance.groupby(band, observed=True).transform(lambda c: c.quantile(1 - share))

print(f"share credited overall: {share:.1%}")
print("policy                    net value   credited 18-24   credited 65+   leavers reached")
for name, send in [("one cut for everybody", one_cut), ("same share in every band", equal)]:
    reached = send[test["churned"] == 1].mean()
    print(f"{name:24} R$ {net_value(test['churned'], send):8,.0f} {send[band == '18-24'].mean():14.1%}"
          f" {send[band == '65+'].mean():14.1%} {reached:17.1%}")
```

`transform` gives every row the cut of its own band: the chance above which the top 2.9% of that band lie.

```
ana@lab:~/ml$ python parity.py
share credited overall: 2.9%
policy                    net value   credited 18-24   credited 65+   leavers reached
one cut for everybody    R$   21,672           3.9%           1.9%             23.5%
same share in every band R$   20,584           3.0%           3.0%             23.0%
```

**Equal shares cost R$ 1,088 over six months and reached slightly fewer leavers**, 23.0% against 23.5%. The
young lose credits, 3.9% down to 3.0%, although they leave most; the oldest gain them. That is
demographic parity doing what it says, and on this decision it moves credits away from the group that
needs them most.

The point is not that parity is wrong. It is that **every fairness policy has a price and a set of winners
and losers**, and both can be computed before anybody decides. Here the price is small in money and real
in who is reached. A per-band cut chosen for equal **recall** instead
would move credits towards the bands whose recall is lowest, 25-34 and 65+, and a little away from the
youngest, whose recall is already the highest; the same program, with the quantile replaced, prices it.

Two cautions about per-group cuts. Using a protected characteristic to set a different threshold is itself
treating people differently by that characteristic, which may be exactly what the law forbids in some
decisions even when the intent is to correct a bias. And on a band of 369 subscribers, a cut set by a
quantile moves with every month's handful of rows. Both are reasons to make this choice with the people
responsible for the decision, and the next section is that conversation.
