---
title: When the business's numbers move
version: 1
---

The break-even cut is 40 / (0.3 × 480), and of those three numbers only one is a price. R$ 40 is
what the credit costs, which finance knows to the cent. R$ 480 is an average over past
subscribers, which is an estimate but a steady one. **The 30% is a guess**: the share of leavers a
credit keeps was measured once, in a small trial, and nobody would be surprised if the truth were
20% or 40%.

So before defending a cut, find out how much the answer depends on the guess. Save this as
`sensitivity.py`; it prices every cut under five values of the share kept:

```python
# sensitivity.py
import numpy as np
import pandas as pd

from feira import CREDIT, KEPT

scores = pd.read_csv("scores.csv")
left = scores["churned"] == 1
cuts = np.round(np.arange(0.05, 0.51, 0.01), 2)

def value(saved, cut):
    send = scores["chance"] >= cut
    return saved * KEPT * (left & send).sum() - CREDIT * send.sum()

print("kept by a credit   break-even   best cut   net there   net at 0.278")
for saved in [0.2, 0.25, 0.3, 0.35, 0.4]:
    values = [value(saved, cut) for cut in cuts]
    print(f"{saved:16.0%}   {CREDIT / (saved * KEPT):10.3f}   {cuts[np.argmax(values)]:8.2f}"
          f"   R$ {max(values):6,.0f}   R$ {value(saved, CREDIT / (0.3 * KEPT)):7,.0f}")
```

`feira.py`'s `net_value` uses the 30% it was given, so this program writes the same arithmetic out
with the share as an argument.

```
ana@lab:~/ml$ python sensitivity.py
kept by a credit   break-even   best cut   net there   net at 0.278
             20%        0.417       0.39   R$  5,968   R$   4,968
             25%        0.333       0.24   R$ 13,680   R$  13,320
             30%        0.278       0.23   R$ 23,832   R$  21,672
             35%        0.238       0.19   R$ 35,272   R$  30,024
             40%        0.208       0.19   R$ 47,488   R$  38,376
```

Read it in two directions.

**Down the money columns, the guess matters enormously.** At 20% the whole programme makes about
R$ 6,000 in six months; at 40%, about eight times that. Whether the retention credit is worth
running at all depends far more on that one number than on any choice in this course. That is worth
saying to the people who own it, plainly, before anybody spends a month tuning the model: **a
better trial of the credit is worth more than a better model.**

**Across the cut columns, the guess matters much less.** The best cut moves from 0.39 to 0.19 as the
share rises. Keeping 0.278 whatever the truth costs little if the credit works worse than hoped:
about R$ 1,000 at 20% and R$ 360 at 25%. It costs more if the credit works better, R$ 5,248 at 35%
and R$ 9,112 at 40%, because there a cut that is too high and the September problem push the same
way. A cut is only as good as the numbers it was computed from, and the cheapest way to protect it
is to recompute it whenever one of them changes.

**That is why the cut belongs to the business.** The data scientist owns the curve: the chances,
their calibration, and the table above. The people who own the credit, the margin and the trial
own the three numbers the cut is computed from, and they should be able to read off what happens
when they change one. Ana puts the table in front of them rather than a single number, with the
break-even line computed from whatever they last agreed.
