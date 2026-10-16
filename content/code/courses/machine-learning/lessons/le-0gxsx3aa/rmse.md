---
title: RMSE, and the deliveries nobody can predict
version: 1
---

The **root mean squared error** squares each error before averaging, then takes the square root to
bring the unit back to minutes:

`RMSE = √ mean((truth − prediction)²)`

Squaring changes who counts. An error of 10 minutes contributes 100, an error of 60 contributes
3,600: **one delivery an hour off weighs as much as thirty-six that are ten minutes off.** RMSE is
the metric for problems where a large error is far worse than several small ones, and it is the
one most libraries fit by default.

On the deliveries that is a problem, because the large errors here are not the model's fault.
Lesson 2 noticed that a few deliveries take an hour or two longer than usual: a flat tyre, a wrong
address. No column in the file says which, so no model can see them coming. Count them, and price
the two metrics with and without them. Save this as `outliers.py`:

```python
# outliers.py
import pandas as pd

predictions = pd.read_csv("predictions.csv")

def mae(error):
    return error.abs().mean()

def rmse(error):
    return (error ** 2).mean() ** 0.5

print("                  all deliveries         without the stuck ones")
print("model              MAE    RMSE   stuck      MAE    RMSE")
for model in ["line", "boost_absolute"]:
    error = predictions["minutes"] - predictions[model]
    usual = error.abs() <= 30
    print(f"{model:15} {mae(error):6.2f}  {rmse(error):6.2f}  {(~usual).sum():6}    "
          f"{mae(error[usual]):6.2f}  {rmse(error[usual]):6.2f}")
```

```
ana@lab:~/ml$ python outliers.py
                  all deliveries         without the stuck ones
model              MAE    RMSE   stuck      MAE    RMSE
line              5.87   14.25      46      3.76    4.58
boost_absolute    5.02   14.43      49      2.76    3.71
```

**About 3% of deliveries are more than half an hour off, and they are the RMSE.** With them, both
models score about 14 minutes and the line edges ahead. Without them, RMSE drops to under 5 for both,
and `boost_absolute` is ahead on both by about a minute, the same verdict the MAE gave all along. The 46
or 49 stuck deliveries out of 1,540 decide the RMSE ranking, and they are the deliveries least worth
ranking a model on, because no model could have known.

The picture is the shape of the errors. Most sit in a narrow hump around zero; a thin tail runs out
to the right, where the van broke down:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 340\" role=\"img\" data-fig=\"l12-errors\" aria-label=\"A histogram of the errors of boost_absolute on the 1,540 test deliveries, truth minus prediction, in five-minute bins from −25 to 130 minutes, on a square-root scale so the rare bars show. Nearly all errors sit in a hump between −10 and +15 minutes. A thin tail of small amber bars runs out to 130 minutes late: the 49 deliveries more than half an hour off.\"><path d=\"M70.0 280.0 L580.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M86.5 280.0 L86.5 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"86.5\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">-20</text><path d=\"M152.3 280.0 L152.3 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"152.3\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M218.1 280.0 L218.1 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"218.1\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M283.9 280.0 L283.9 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"283.9\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M349.7 280.0 L349.7 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"349.7\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M415.5 280.0 L415.5 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"415.5\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80</text><path d=\"M481.3 280.0 L481.3 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"481.3\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M547.1 280.0 L547.1 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"547.1\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">120</text><text x=\"325.0\" y=\"311.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">minutes late (truth − prediction)</text><path d=\"M70.0 30.0 L70.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 280.0 L70.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 252.1 L580.0 252.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 252.1 L70.0 252.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"252.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M70.0 217.7 L580.0 217.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 217.7 L70.0 217.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"217.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M70.0 191.9 L580.0 191.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 191.9 L70.0 191.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"191.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M70.0 155.4 L580.0 155.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 155.4 L70.0 155.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"155.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M70.0 103.8 L580.0 103.8\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 103.8 L70.0 103.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"103.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><path d=\"M70.0 64.1 L580.0 64.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 64.1 L70.0 64.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"64.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600</text><text x=\"70.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">deliveries (square-root scale)</text><path d=\"M102.9 280.0 L102.9 267.5 L119.4 267.5 L119.4 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M119.4 280.0 L119.4 231.7 L135.8 231.7 L135.8 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M135.8 280.0 L135.8 41.9 L152.3 41.9 L152.3 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M152.3 280.0 L152.3 70.7 L168.7 70.7 L168.7 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M168.7 280.0 L168.7 176.9 L185.2 176.9 L185.2 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M185.2 280.0 L185.2 235.9 L201.6 235.9 L201.6 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M201.6 280.0 L201.6 267.5 L218.1 267.5 L218.1 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M234.5 280.0 L234.5 271.2 L251.0 271.2 L251.0 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M251.0 280.0 L251.0 262.4 L267.4 262.4 L267.4 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M267.4 280.0 L267.4 262.4 L283.9 262.4 L283.9 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M283.9 280.0 L283.9 271.2 L300.3 271.2 L300.3 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M316.8 280.0 L316.8 264.7 L333.2 264.7 L333.2 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M333.2 280.0 L333.2 255.1 L349.7 255.1 L349.7 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M349.7 280.0 L349.7 271.2 L366.1 271.2 L366.1 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M366.1 280.0 L366.1 264.7 L382.6 264.7 L382.6 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M382.6 280.0 L382.6 271.2 L399.0 271.2 L399.0 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M399.0 280.0 L399.0 264.7 L415.5 264.7 L415.5 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M415.5 280.0 L415.5 267.5 L431.9 267.5 L431.9 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M431.9 280.0 L431.9 264.7 L448.4 264.7 L448.4 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M448.4 280.0 L448.4 260.3 L464.8 260.3 L464.8 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M464.8 280.0 L464.8 271.2 L481.3 271.2 L481.3 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M481.3 280.0 L481.3 267.5 L497.7 267.5 L497.7 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M497.7 280.0 L497.7 264.7 L514.2 264.7 L514.2 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M514.2 280.0 L514.2 271.2 L530.6 271.2 L530.6 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M530.6 280.0 L530.6 262.4 L547.1 262.4 L547.1 280.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M152.3 280.0 L152.3 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"415.5\" y=\"211.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">49 stuck deliveries, more than</text><text x=\"415.5\" y=\"226.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">half an hour off: most of the RMSE</text></svg>", "caption": "A hump that the MAE describes, and a tail that the RMSE is mostly made of."}
```

So RMSE answers a different question from MAE, and the choice between them is a question about the
business:

- **If a big miss is much worse than several small ones**, square the errors. A forecast of how much
  stock to order, where running out costs a day's sales, is like that.
- **If every minute late is about as bad as every other**, use the MAE. Most promises to a person are
  like that, up to a point.
- **If the big misses are random and nobody's fault**, RMSE will spend its attention on them. Report
  it if somebody asks for it, but do not choose a model by it.

One more property follows from the squaring: **RMSE is never smaller than MAE**, and the gap between
them says how heavy the tail is. Here RMSE is two and a half to three times the MAE. On errors that were all
about the same size, the two would be nearly equal.
