---
title: A model, scored against the same bar
version: 1
---

This section fits a model, and it does not explain it. The algorithm is gradient boosting, which is
lesson 8's subject. It is used here because it accepts the data as `load_churn` leaves it, gaps and
text columns included, so the program stays short. **Treat it as a box** for now: rows go in, a
chance of leaving comes out.

The one decision this program makes is where to cut that chance. A credit pays for itself when the
chance of leaving is above 40 ÷ (0.3 × 480), so that is where it sends. Lesson 11 is about that
line; here it is simply the break-even point of lesson 1's table. Save this as `first_model.py`:

```python
# first_model.py
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL

model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
model.fit(train[features], train["churned"])
chance = model.predict_proba(test[features])[:, 1]

cut = CREDIT / (SAVED * KEPT)      # where a credit starts to pay for itself
send = chance >= cut
print(f"send when the chance of leaving is at least {cut:.3f}")
print(f"on the test months: {send.sum():,} credits, "
      f"{(send & (test['churned'] == 1)).sum()} to leavers, "
      f"net value R$ {net_value(test['churned'], send):,.0f}")
test.assign(chance=chance).to_csv("first_model_scores.csv", index=False)
```

```
ana@lab:~/ml$ python first_model.py
send when the chance of leaving is at least 0.278
on the test months: 711 credits, 348 to leavers, net value R$ 21,672
```

**R$ 21,672 over six months**, where the best rule lost R$ 576 and sending nobody made nothing. 348
of its 711 credits went to people who were leaving, nearly half, against about a quarter for the
rule. The last line saves each test row with its chance, so the next section can ask about the
difference without fitting the model again.

## How far from the ceiling

Lesson 1 priced a perfect model: a credit to every leaver and to nobody else. On these six months
that is 1,484 leavers at R$ 104 each, **R$ 154,336**. The model gets about 14% of it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 200\" role=\"img\" data-fig=\"l02-ceiling\" aria-label=\"Horizontal bars of net value over the six test months: sending nobody R$ 0, the best rule −R$ 576, the first model R$ 21,672, and a perfect model R$ 154,336.\"><path d=\"M230.0 22.0 L230.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"218.0\" y=\"41.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">send nobody</text><text x=\"238.0\" y=\"41.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R$ 0</text><text x=\"218.0\" y=\"81.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the best rule</text><rect x=\"228.8\" y=\"70.0\" width=\"1.2\" height=\"22.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"238.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">−R$ 576</text><text x=\"218.0\" y=\"121.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the first model</text><rect x=\"230.0\" y=\"110.0\" width=\"46.3\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"284.3\" y=\"121.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R$ 21,672</text><text x=\"218.0\" y=\"161.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">perfect: all 1,484 leavers</text><rect x=\"230.0\" y=\"150.0\" width=\"330.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"568.0\" y=\"161.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R$ 154,336</text></svg>", "caption": "The model is worth about 14% of what a perfect one would be, and far more than anything simpler."}
```

Both halves of that picture matter. The model is far better than anything simpler, which is the
reason to build it. And it is far from perfect, because most people who leave give no sign of it in
these columns three months before. **A baseline tells you whether a model is worth having; the
ceiling tells you how much better one could possibly be.** Between them, they stop a project from
either giving up too early or polishing forever.
