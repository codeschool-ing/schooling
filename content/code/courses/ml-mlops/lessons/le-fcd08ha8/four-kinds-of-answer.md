---
title: Four kinds of answer
version: 1
---

A yes-or-no model can be right in two ways and wrong in two ways, and they cost different amounts.
Laid out as a table, they are called a **confusion matrix**. Save this as `confusion.py`:

```python
"""confusion.py: the four kinds of answer, at the default threshold of 0.5."""
from sklearn.metrics import confusion_matrix, precision_score, recall_score

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
predicted = lapse.predict(test[COLUMNS])

(tn, fp), (fn, tp) = confusion_matrix(test["lapsed"], predicted)
print(f"                 predicted stays  predicted lapses")
print(f"actually stayed  {tn:15}  {fp:16}")
print(f"actually lapsed  {fn:15}  {tp:16}")
print(f"precision {precision_score(test['lapsed'], predicted):.3f}  "
      f"recall {recall_score(test['lapsed'], predicted):.3f}")
```

```
ana@dev:~/ml$ python confusion.py
                 predicted stays  predicted lapses
actually stayed             2522                78
actually lapsed              360               170
precision 0.685  recall 0.321
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l04-confusion\" aria-label=\"A two-by-two grid. Rows: actually stayed, actually lapsed. Columns: predicted stays, predicted lapses. Stayed and predicted stays: 2,522 true negatives. Stayed but predicted lapses: 78 false alarms. Lapsed but predicted stays: 360 misses. Lapsed and predicted lapses: 170 catches.\"><text x=\"350.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">predicted stays</text><text x=\"550.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">predicted lapses</text><text x=\"236.0\" y=\"95.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">actually stayed</text><rect x=\"250.0\" y=\"50.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"700\" fill=\"var(--paper)\">2,522</text><text x=\"350.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">true negative</text><rect x=\"450.0\" y=\"50.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"700\" fill=\"var(--paper)\">78</text><text x=\"550.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">false alarm</text><text x=\"236.0\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">actually lapsed</text><rect x=\"250.0\" y=\"140.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"700\" fill=\"var(--paper)\">360</text><text x=\"350.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">miss</text><rect x=\"450.0\" y=\"140.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"700\" fill=\"var(--paper)\">170</text><text x=\"550.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">catch</text></svg>", "caption": "The two right cells are where accuracy looks. The two wrong ones are where the business is, and they cost different amounts."}
```

Each cell has a name worth knowing, because every other score in this lesson is built from them:

| | the model said stays | the model said lapses |
| --- | --- | --- |
| **stayed** | **true negative**: 2,522 | **false positive**, a false alarm: 78 |
| **lapsed** | **false negative**, a miss: 360 | **true positive**, a catch: 170 |

Accuracy is the two right cells over everything: (2,522 + 170) / 3,130. It cannot tell a model that
catches 170 lapses from one that catches none, as long as the misses are few compared with the
crowd that stayed.

**The cells are where the business is.** A false alarm costs a voucher sent to somebody who was
coming back anyway. A miss costs a member who left without anybody trying. At the default threshold
of 0.5 this model raises 78 false alarms and misses 360 members, and **whether that is a good
trade is a question about money, not about models**, which section 05 answers with numbers.
