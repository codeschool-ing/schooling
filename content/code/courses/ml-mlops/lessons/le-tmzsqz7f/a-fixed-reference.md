---
title: A reference that does not move
version: 1
---

**The fixed reference is the data the champion learned from**, `data/train.csv`, the members as of
31 August 2025. Comparing a night with it answers the question drift asks: how far is tonight's
population from the one the model knows? This program measures it for every input, on any nights
given. Save it as `drift.py`:

```python
"""drift.py: how far each input has moved from the data the champion learned from.

    python drift.py 2026-03-01 2026-04-26 2026-06-28
"""
import sqlite3
import sys

import numpy as np
import pandas as pd
from scipy.stats import ks_2samp

import features
from featurestore import STORE
from project import DATA

learned = pd.read_csv(DATA / "train.csv")
nights = sys.argv[1:]
with sqlite3.connect(STORE) as db:
    seen = {night: pd.read_sql_query("SELECT * FROM offline WHERE as_of = ?", db, params=(night,))
            for night in nights}


def shares(values, bins):
    counts = values.value_counts() if bins is None else pd.Series(np.histogram(values, bins)[0])
    return (counts / len(values)).clip(lower=0.0001)       # an empty bin would divide by zero


def psi(before, after, numeric):
    """Population stability index: 0 is unchanged, above 0.25 is a different population."""
    bins = None
    if numeric:
        bins = np.unique(np.quantile(before, np.linspace(0, 1, 11)))   # ten slices of the past
        bins[0], bins[-1] = -np.inf, np.inf
    b, a = shares(before, bins), shares(after, bins)
    b, a = b.align(a, fill_value=0.0001)
    return float(((a - b) * np.log(a / b)).sum())


print(f"{'':16}" + "".join(f"{night:>22}" for night in nights))
print(f"{'':16}" + "".join(f"{'PSI':>14}{'KS':>8}" for _ in nights))
for column in features.NUMERIC + features.CATEGORICAL:
    numeric = column in features.NUMERIC
    cells = []
    for night in nights:
        after = seen[night][column]
        ks = f"{ks_2samp(learned[column], after).statistic:.3f}" if numeric else "-"
        cells.append(f"{psi(learned[column], after, numeric):>14.3f}{ks:>8}")
    print(f"{column:16}" + "".join(cells))
```

It uses two measures, because each is easy to misread alone:

- **the population stability index, PSI**, cuts the training values into ten slices of equal size,
  counts the share of tonight's members in each slice, and adds up how far each share moved,
  weighted by the logarithm of the ratio. 0 is unchanged; the rule of thumb used in credit scoring,
  where the index comes from, reads below 0.1 as stable, 0.1 to 0.25 as worth a look, and above
  0.25 as a different population. It works for categories as well, slice by category;
- **the Kolmogorov-Smirnov statistic, KS**, from SciPy, is the widest gap between the two
  cumulative distributions, between 0 and 1. Its p-value is deliberately left out: with three
  thousand members on each side, any difference at all is "significant", and a test that is always
  significant says nothing.

On a night a week after the course began, one two months later, and the last:

```
ana@dev:~/ml$ python drift.py 2026-03-01 2026-04-26 2026-06-28
                            2026-03-01            2026-04-26            2026-06-28
                           PSI      KS           PSI      KS           PSI      KS
tenure_days              0.142   0.146         0.197   0.176         0.259   0.212
recency_days             0.004   0.029         0.010   0.040         0.040   0.087
visits_180d              0.002   0.012         0.010   0.025         0.006   0.023
spend_180d               0.011   0.014         0.007   0.019         0.009   0.027
basket_avg               0.004   0.018         0.008   0.016         0.008   0.021
online_share             0.014   0.042         0.168   0.193         0.602   0.324
shops_180d               0.004   0.018         0.007   0.032         0.062   0.062
channel                  0.420       -         0.602       -         0.756       -
age_band                 0.000       -         0.001       -         0.002       -
home_shop                0.013       -         0.022       -         0.032       -
```

Three inputs moved, and they are three different stories:

- **`online_share` went from 0.014 to 0.602**, past any threshold, and most of it after March. That
  is the free postage: members who used to walk into a shop now order online. The model has never
  seen this population.
- **`channel` was already at 0.420 on the first night.** The app arrived in September 2025, after
  the training cutoff, so the model learned from members with no `app` channel at all, and its
  encoder turns `app` into zeros. The nightly watch never flagged it, because `app` had been in
  every one of its four-week windows.
- **`tenure_days` drifted steadily to 0.259**, because the membership grows older every day. That is
  drift and it is harmless: nothing about the members changed except the calendar.

**Drift is a reason to look, not a verdict.** PSI says the population moved; whether the model got
worse in it is a question only outcomes can answer, which is the next section.
