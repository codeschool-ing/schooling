---
title: Accuracy, and why it hides the rare class
version: 1
---

**Accuracy** is the share of rows the model got right: the true positives and true negatives over
everything. It is the first metric anybody reaches for, and on this data it is almost useless. Save
this as `metrics.py`; it computes the metrics of this lesson at five cuts, beside the net value:

```python
# metrics.py
import pandas as pd
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score

from feira import CREDIT, KEPT, SAVED, net_value

scores = pd.read_csv("scores.csv")
y = scores["churned"]
print("cut    accuracy  precision  recall    F1     net value")
for cut in [0.5, 0.4, CREDIT / (SAVED * KEPT), 0.2, 0.1]:
    said = scores["chance"] >= cut
    print(f"{cut:<6.3f} {accuracy_score(y, said):8.3f} {precision_score(y, said):10.3f} "
          f"{recall_score(y, said):7.3f} {f1_score(y, said):6.3f}  R$ {net_value(y, said):8,.0f}")
```

```
ana@lab:~/ml$ python metrics.py
cut    accuracy  precision  recall    F1     net value
0.500     0.940      0.603   0.079  0.139  R$    9,088
0.400     0.941      0.589   0.131  0.215  R$   14,840
0.278     0.938      0.489   0.235  0.317  R$   21,672
0.200     0.931      0.417   0.328  0.367  R$   23,448
0.100     0.892      0.283   0.493  0.359  R$    1,848
```

Read the accuracy column. **Between 0.892 and 0.941, at every cut**, and highest at 0.4, where the
model makes R$ 14,840. The cut that makes the most money of these five, 0.2, has a *lower* accuracy
than the one that sends almost nobody a credit. Accuracy and the business are pulling in different
directions.

The reason is the 94% of rows that are stayers. Accuracy counts every row the same, so it is dominated
by the true negatives, and the model can score well on it by saying *stays* to almost everybody, which
is lesson 2's constant again at 0.939. Sending more credits finds more leavers and also makes more
false positives among the stayers, and on a rare class the second effect wins the accuracy count every
time.

**Accuracy is a sensible metric when the classes are roughly balanced and the two errors cost about
the same.** Neither is true here, and neither is true for most of the problems where machine learning
is worth the trouble: fraud, disease, churn, defects. When the thing being looked for is rare, the
metrics worth reading are the ones that leave the true negatives out, which is what the next two are.
