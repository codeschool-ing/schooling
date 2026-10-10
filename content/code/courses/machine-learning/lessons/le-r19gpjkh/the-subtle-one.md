---
title: The column that knows the future
version: 1
---

The second column has an innocent name, `days_since_last_order`, and it is exactly the kind of
column a model of cancellations should have: somebody who has not ordered for weeks is drifting
away. It passes every check a person would think of, except one, **when was it computed?**

The answer is in how the file was made: on 1 January 2026, when `churn.csv` was exported, the
system computed every subscriber's days since their last order **on that day**, and wrote the same
kind of number into every row, old or new. For a row from July 2024 whose subscriber later left,
it counts the days from their last order to January 2026. The very first row of the file, C00001,
which `head` printed in lesson 1, says 536. On 1 July 2024, nobody could have known that number:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 210\" role=\"img\" data-fig=\"l04-timeline\" aria-label=\"A timeline for C00001, the first row of churn.csv. The snapshot and the credit decision are on 1 July 2024; the cancellation comes on 14 July 2024; the export is on 1 January 2026. A bracket from the cancellation to the export is what days_since_last_order counted.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40.0 100.0 L620.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><circle cx=\"90.0\" cy=\"100.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"90.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1 Jul 2024</text><circle cx=\"190.0\" cy=\"100.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"190.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">14 Jul 2024</text><circle cx=\"590.0\" cy=\"100.0\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"590.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1 Jan 2026</text><text x=\"76.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">snapshot: the credit is decided</text><text x=\"220.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cancels: cancel_reason is written</text><path d=\"M190.0 90.0 L216.0 54.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"590.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the file is exported</text><path d=\"M190 152 L190 160 L590 160 L590 152\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"390.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">what days_since_last_order counted: 536 days</text></svg>", "caption": "Everything to the right of the snapshot was unknown on the day the credit was decided, and both leaking columns live there."}
```

The pattern shows in the data as soon as the column is set against the date. Save this as
`subtle.py`:

```python
# subtle.py
import pandas as pd

churn = pd.read_csv("data/churn.csv", parse_dates=["snapshot"])
churn["quarter"] = churn["snapshot"].dt.to_period("Q")
table = churn.pivot_table(index="quarter", columns="churned",
                          values="days_since_last_order", aggfunc="median")
print(table.rename(columns={0: "stayed", 1: "left"}))
```

```
ana@lab:~/ml$ python subtle.py
churned  stayed   left
quarter               
2024Q3     11.0  493.0
2024Q4      8.0  420.0
2025Q1      6.0  317.0
2025Q2      6.0  225.0
2025Q3      5.0  136.0
2025Q4      4.0   40.0
```

**A legitimate feature does not do this.** For subscribers who stayed, the median sits at a few
days in every quarter. For leavers it is 493 in the third quarter of 2024 and falls steadily to 40
by the end of 2025, because it measures the distance from each leaver's departure to the export
date. The column is a clock that started after the outcome. Now give it to the model, and score
the model the two ways lesson 3 compared. Save this as `leak_test.py`:

```python
# leak_test.py
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import train_test_split

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

churn = load_churn()
cut = CREDIT / (SAVED * KEPT)
splits = {"random": train_test_split(churn, test_size=0.3, random_state=0),
          "by time": by_time(churn)}
for extra in [[], ["days_since_last_order"]]:
    features = NUMERIC + CATEGORICAL + extra
    for name, (learn, check) in splits.items():
        model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
        model.fit(learn[features], learn["churned"])
        chance = model.predict_proba(check[features])[:, 1]
        value = net_value(check["churned"], chance >= cut) / len(check) * 1000
        label = "with the column" if extra else "without it"
        print(f"{label:16} {name:8} AUC {roc_auc_score(check['churned'], chance):.3f}"
              f"   R$ {value:5.0f} per 1,000 rows")
```

```
ana@lab:~/ml$ python leak_test.py
without it       random   AUC 0.797   R$   933 per 1,000 rows
without it       by time  AUC 0.804   R$   893 per 1,000 rows
with the column  random   AUC 0.958   R$  2422 per 1,000 rows
with the column  by time  AUC 0.500   R$     0 per 1,000 rows
```

The AUC column is a score lesson 10 explains properly; for now, read **1.0 as perfect and 0.5 as
a coin**. With the column, on a random split, the model scores **0.958** and is worth **R$ 2,422
per thousand rows**, two and a half times the honest model. That is the number that gets a model
approved. With the same column and a split by time, it scores 0.500 and is worth **R$ 0**: it
sends no credit at all, because in the test months the leavers' numbers are small and the model
learned that leavers' numbers are large.

The time split exposed this leak, which is lucky rather than guaranteed. It happened because the
column's distortion changes with the date. A column computed from the future in a way that does not
drift would pass the time split and fail only in production, where the value is computed on the
first of the month and nothing like what the model learned.

## The repair

Compute the column **as of the snapshot**: days from the last order before the snapshot to the
snapshot itself. That is a different number, it is legitimate, and it has to come from the order
history rather than from the export. In `churn_2026.csv`, which the system writes on the first of
each month as the model will see it, that is what the column holds, and lesson 22 uses it.
