---
title: Choosing a threshold from what things cost
version: 1
---

The threshold of 0.5 is scikit-learn's, chosen for nobody. **A threshold worth using comes from two
numbers the business already has**: what an action costs, and what it is worth when it works.

For this section, marketing supplies them. A voucher costs **R$ 10.00** to send. A lapsing member
who gets one and stays is worth **R$ 60.00**, roughly what a member spends in a month and a bit.
Those two figures are the example's, written into the program so they are easy to change; your
marketing team's will differ, and the method will not. Save this as `thresholds.py`:

```python
"""thresholds.py: the same probabilities, cut at different places."""
import features
from model import COLUMNS, trained

VOUCHER = 10.00          # reais: what marketing pays for each voucher sent
SAVED = 60.00            # reais: what a lapsing member who is won back is worth

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
p = lapse.predict_proba(test[COLUMNS])[:, 1]
lapsed = test["lapsed"].to_numpy() == 1

print("threshold  flagged  precision  recall  net value")
for threshold in (0.1, 0.15, 0.2, 0.3, 0.4, 0.5, 0.6):
    flagged = p >= threshold
    caught = (flagged & lapsed).sum()
    value = caught * SAVED - flagged.sum() * VOUCHER
    print(f"{threshold:9.2f}  {flagged.sum():7}  {caught / flagged.sum():9.3f}  "
          f"{caught / lapsed.sum():6.3f}  R$ {value:8.2f}")
```

For each threshold the program counts the members flagged, the ones among them who lapsed, and the
**net value**: every lapse caught is worth R$ 60.00, every voucher sent costs R$ 10.00. It assumes,
generously, that every voucher sent to a lapsing member keeps them; the shape of the answer survives
a smaller rate, and its numbers shrink.

```
ana@dev:~/ml$ python thresholds.py
threshold  flagged  precision  recall  net value
     0.10     1688      0.262   0.834  R$  9640.00
     0.15     1049      0.355   0.702  R$ 11830.00
     0.20      742      0.434   0.608  R$ 11900.00
     0.30      488      0.514   0.474  R$ 10180.00
     0.40      352      0.614   0.408  R$  9440.00
     0.50      248      0.685   0.321  R$  7720.00
     0.60      180      0.750   0.255  R$  6300.00
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l04-thresholds\" aria-label=\"Net value of acting on the model at each threshold, at R$ 10.00 a voucher and R$ 60.00 a member kept: R$ 9,640 at 0.1, R$ 11,830 at 0.15, R$ 11,900 at 0.2, R$ 10,180 at 0.3, R$ 9,440 at 0.4, R$ 7,720 at 0.5 and R$ 6,300 at 0.6.\"><path d=\"M90.0 40.0 L90.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M86.0 220.0 L90.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M90.0 168.6 L690.0 168.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 168.6 L90.0 168.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"168.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4,000</text><path d=\"M90.0 117.1 L690.0 117.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 117.1 L90.0 117.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"117.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8,000</text><path d=\"M90.0 65.7 L690.0 65.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 65.7 L90.0 65.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"65.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12,000</text><text x=\"90.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">net value, reais</text><path d=\"M90.0 220.0 L690.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M114.0 220.0 L114.0 96.1 L166.0 96.1 L166.0 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"140.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.10</text><path d=\"M197.3 220.0 L197.3 67.9 L249.3 67.9 L249.3 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"223.3\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.15</text><path d=\"M280.7 220.0 L280.7 67.0 L332.7 67.0 L332.7 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"306.7\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.20</text><path d=\"M364.0 220.0 L364.0 89.1 L416.0 89.1 L416.0 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"390.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.30</text><path d=\"M447.3 220.0 L447.3 98.6 L499.3 98.6 L499.3 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"473.3\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.40</text><path d=\"M530.7 220.0 L530.7 120.7 L582.7 120.7 L582.7 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"556.7\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.50</text><path d=\"M614.0 220.0 L614.0 139.0 L666.0 139.0 L666.0 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"640.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.60</text><text x=\"390.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">threshold</text><text x=\"306.7\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">best: 0.2</text><text x=\"556.7\" y=\"108.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">scikit-learn: 0.5</text></svg>", "caption": "The value peaks near 0.2, close to the cost of a voucher over the value of a member kept, and the default of 0.5 leaves about a third of it behind."}
```

**The best threshold here is about 0.2, not 0.5.** At 0.5 the model sends 248 vouchers and is worth
R$ 7,720.00; at 0.2 it sends 742, catches 322 lapsing members instead of 170, and is worth
R$ 11,900.00. Lower still and the vouchers to members who were staying start to cost more than the
extra catches bring in.

There is a rule of thumb behind where the peak falls. A voucher pays for itself when the chance
that its member lapses is above the cost over the value: 10 / 60, about 0.17. **For a model whose
probabilities can be believed, the best threshold sits close to that ratio**, which is why the next
two sections check whether these can.

## A budget instead of a price

Sometimes the business has no price, only a limit: *marketing can send three hundred vouchers this
month.* Then there is no threshold to choose at all; there is a list to sort. Send the three hundred
members with the highest probabilities, and the score that matters is how many of those three
hundred lapse. That is a score of the ranking, which is the next section.
