---
title: One test is one draw
version: 1
---

The comparison of two sections ago forecast 26 weeks from one starting point, the end of 2024, and
declared the two best models nearly tied. **That is one draw.** Start from a different week and
different holidays, different noise and a different stretch of trend fall inside the test, and the
result moves.

The standard remedy is a **rolling-origin evaluation**, also called time-series cross-validation:
make the forecast from many starting points, each using only the data before it, and average the
errors over all of them. It is how lesson 4 measured revisions, turned into a scoring method.

```schooling-example
{"language": "python", "file": "backtest.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.tsa.holtwinters import ExponentialSmoothing\nfrom statsmodels.tsa.statespace.sarimax import SARIMAX\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-08-31\"]"}, {"code": "print(\"origin       Holt-Winters  seasonal ARIMA   (MAE over the next 4 weeks)\")\nfor origin in weekly[\"2024-12-29\":\"2025-06-01\"].index[::4]:\n    history, future = weekly[:origin], weekly[origin:].iloc[1:5]", "note": "Six forecast origins, four weeks apart. Each one sees everything up to its origin and is tested on the four weeks after it."}, {"code": "    hw = ExponentialSmoothing(history, trend=\"add\", seasonal=\"mul\",\n                              seasonal_periods=52).fit().forecast(4)\n    ar = SARIMAX(history, order=(1, 0, 1), seasonal_order=(0, 1, 0, 52),\n                 trend=\"c\").fit(disp=False).forecast(4)", "note": "Both models refitted at every origin, as they would be in use."}, {"code": "    hw_mae = abs(hw.values - future.values).mean()\n    ar_mae = abs(ar.values - future.values).mean()\n    print(f\"{origin.date()}   {hw_mae:12.0f}  {ar_mae:14.0f}\")"}], "output": "origin       Holt-Winters  seasonal ARIMA   (MAE over the next 4 weeks)\n2024-12-29            263             289\n2025-01-26            473             427\n2025-02-23            732             834\n2025-03-23            191             282\n2025-04-20            229             164\n2025-05-18            266             178"}
```

**Holt-Winters wins three of the six origins and ARIMA the other three.** The worst origin for both
is the end of February, whose next four weeks contain the Carnival that moved to March. Averaged
over all six, the two are close again, which is the honest conclusion: on this series, at this
horizon, the data does not separate them.

Two rules make a rolling evaluation trustworthy.

- **Never let a model see the future.** Each origin is fitted only on data before it. Fitting once
  on everything and then "testing" on slices of the same data is the commonest way a forecast's
  accuracy is overstated.
- **Measure at the horizon the decision needs.** Four weeks ahead suits operations; the kitchen's
  question is one week ahead and finance's is a year. A model can win at one horizon and lose at
  another, as lesson 4's damped trend did.

When two models are this close, the tie-breakers are not accuracy at all: which one the team can
maintain, which one fails more gracefully when something odd happens, and whether an average of the
two, which is often better than either, is worth the second model.
