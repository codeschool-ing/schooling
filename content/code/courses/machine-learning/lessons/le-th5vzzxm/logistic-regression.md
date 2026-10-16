---
title: Logistic regression, a line for a yes or no
version: 1
---

A line predicts a number, and the churn question wants a probability: a value between 0 and 1. A
straight line goes below zero and above one as soon as a column is large enough, so **logistic
regression** puts the line through a bend first. It computes the same weighted sum, then squeezes
it with the logistic function:

`chance = 1 / (1 + e^(−(intercept + w₁ × x₁ + w₂ × x₂ + …)))`

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 260\" role=\"img\" data-fig=\"l05-sigmoid\" aria-label=\"The logistic curve: chance on the vertical axis from 0 to 1, the weighted sum on the horizontal axis from minus 6 to 6. It is flat near 0 on the left, rises steeply through 0.5 at a sum of zero, and flattens near 1 on the right.\"><path d=\"M60.0 30.0 L60.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M56.0 210.0 L60.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.00</text><path d=\"M60.0 165.0 L560.0 165.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 165.0 L60.0 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"165.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.25</text><path d=\"M60.0 120.0 L560.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 120.0 L60.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.50</text><path d=\"M60.0 75.0 L560.0 75.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 75.0 L60.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"75.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.75</text><path d=\"M60.0 30.0 L560.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 30.0 L60.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.00</text><text x=\"60.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">chance of leaving</text><path d=\"M60.0 210.0 L560.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 210.0 L60.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">−6</text><path d=\"M143.3 210.0 L143.3 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"143.3\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">−4</text><path d=\"M226.7 210.0 L226.7 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"226.7\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">−2</text><path d=\"M310.0 210.0 L310.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"310.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M393.3 210.0 L393.3 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"393.3\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M476.7 210.0 L476.7 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"476.7\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M560.0 210.0 L560.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"560.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><text x=\"310.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">intercept + the weighted columns</text><path d=\"M60.0 209.6 L63.1 209.5 L66.3 209.5 L69.4 209.4 L72.5 209.4 L75.6 209.4 L78.8 209.3 L81.9 209.2 L85.0 209.2 L88.1 209.1 L91.2 209.1 L94.4 209.0 L97.5 208.9 L100.6 208.8 L103.8 208.7 L106.9 208.6 L110.0 208.5 L113.1 208.4 L116.2 208.3 L119.4 208.2 L122.5 208.0 L125.6 207.9 L128.8 207.7 L131.9 207.5 L135.0 207.3 L138.1 207.1 L141.2 206.9 L144.4 206.7 L147.5 206.4 L150.6 206.2 L153.8 205.9 L156.9 205.5 L160.0 205.2 L163.1 204.9 L166.2 204.5 L169.4 204.0 L172.5 203.6 L175.6 203.1 L178.8 202.6 L181.9 202.1 L185.0 201.5 L188.1 200.8 L191.2 200.2 L194.4 199.4 L197.5 198.7 L200.6 197.8 L203.8 197.0 L206.9 196.0 L210.0 195.0 L213.1 194.0 L216.2 192.8 L219.4 191.6 L222.5 190.4 L225.6 189.0 L228.7 187.6 L231.9 186.1 L235.0 184.5 L238.1 182.8 L241.2 181.0 L244.4 179.1 L247.5 177.2 L250.6 175.1 L253.8 172.9 L256.9 170.7 L260.0 168.3 L263.1 165.9 L266.2 163.3 L269.4 160.7 L272.5 158.0 L275.6 155.2 L278.8 152.3 L281.9 149.3 L285.0 146.2 L288.1 143.1 L291.2 139.9 L294.4 136.7 L297.5 133.4 L300.6 130.1 L303.8 126.7 L306.9 123.4 L310.0 120.0 L313.1 116.6 L316.3 113.3 L319.4 109.9 L322.5 106.6 L325.6 103.3 L328.8 100.1 L331.9 96.9 L335.0 93.8 L338.1 90.7 L341.2 87.7 L344.4 84.8 L347.5 82.0 L350.6 79.3 L353.8 76.7 L356.9 74.1 L360.0 71.7 L363.1 69.3 L366.2 67.1 L369.4 64.9 L372.5 62.8 L375.6 60.9 L378.8 59.0 L381.9 57.2 L385.0 55.5 L388.1 53.9 L391.2 52.4 L394.4 51.0 L397.5 49.6 L400.6 48.4 L403.8 47.2 L406.9 46.0 L410.0 45.0 L413.1 44.0 L416.2 43.0 L419.4 42.2 L422.5 41.3 L425.6 40.6 L428.7 39.8 L431.9 39.2 L435.0 38.5 L438.1 37.9 L441.3 37.4 L444.4 36.9 L447.5 36.4 L450.6 36.0 L453.8 35.5 L456.9 35.1 L460.0 34.8 L463.1 34.5 L466.2 34.1 L469.4 33.8 L472.5 33.6 L475.6 33.3 L478.8 33.1 L481.9 32.9 L485.0 32.7 L488.1 32.5 L491.2 32.3 L494.4 32.1 L497.5 32.0 L500.6 31.8 L503.8 31.7 L506.9 31.6 L510.0 31.5 L513.1 31.4 L516.2 31.3 L519.4 31.2 L522.5 31.1 L525.6 31.0 L528.8 30.9 L531.9 30.9 L535.0 30.8 L538.1 30.8 L541.2 30.7 L544.4 30.6 L547.5 30.6 L550.6 30.6 L553.8 30.5 L556.9 30.5 L560.0 30.4\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M310.0 210.0 L310.0 30.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"318.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sum 0: chance 0.5</text></svg>", "caption": "The same weighted sum as a line, bent so that it never leaves the range a probability lives in."}
```

A large positive sum gives a chance near 1, a large negative sum a chance near 0, and a sum of zero
exactly 0.5. Fitting chooses the weights that make the observed cancellations as likely as possible,
which has no formula and is done by a solver that improves the weights step by step; `max_iter`
says how many steps it may take.

Three things are needed that gradient boosting did without, and each is done by hand here because
lesson 15 builds the pipeline that does them properly:

- **the gaps filled**: `rating_90d` and `days_since_login` are empty for some rows, and a sum cannot
  include an empty value; each gap gets the median of the **training** rows;
- **the text columns turned into numbers**: `get_dummies` makes a 0-or-1 column per value,
  `payment_card`, `payment_pix`, and drops the first value of each, which becomes the baseline;
- **the columns put on one scale**, by `StandardScaler`, fitted on the training rows only.

Save this as `logistic.py`:

```python
# logistic.py
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())


def table(rows, medians):
    numbers = rows[NUMERIC].fillna(medians)                       # gaps get the training median
    words = pd.get_dummies(rows[CATEGORICAL], drop_first=True, dtype=float)
    return pd.concat([numbers, words], axis=1)


medians = train[NUMERIC].median()
X_train, X_test = table(train, medians), table(test, medians)
scale = StandardScaler().fit(X_train)                             # learned on training rows only
model = LogisticRegression(max_iter=1000).fit(scale.transform(X_train), train["churned"])

chance = model.predict_proba(scale.transform(X_test))[:, 1]
send = chance >= CREDIT / (SAVED * KEPT)
print(f"{X_train.shape[1]} columns; on the test months: {send.sum():,} credits, "
      f"net value R$ {net_value(test['churned'], send):,.0f}")

weights = pd.Series(model.coef_[0], index=X_train.columns)
order = weights.abs().sort_values(ascending=False).index[:8]
print("largest weights, per standard deviation of the column:")
for col in order:
    print(f"  {col:22} {weights[col]:+.3f}   odds x {np.exp(weights[col]):.2f}")
```

```
ana@lab:~/ml$ python logistic.py
22 columns; on the test months: 529 credits, net value R$ 16,424
largest weights, per standard deviation of the column:
  rating_90d             -0.806   odds x 0.45
  tenure_months          -0.475   odds x 0.62
  skips_90d              +0.345   odds x 1.41
  late_90d               +0.266   odds x 1.30
  complaints_90d         +0.251   odds x 1.29
  payment_card           -0.241   odds x 0.79
  payment_pix            -0.234   odds x 0.79
  days_since_login       +0.131   odds x 1.14
```

**R$ 16,424 on the test months**, against R$ 21,672 for lesson 2's gradient boosting and R$ 0 for
sending nobody. Logistic regression beats every baseline by far and loses to boosting by about a
quarter. Section 08 weighs that against what it gives in return, which is the list of weights below
the first line.
