---
title: Holt-Winters: level, trend and season
version: 1
---

Holt added a trend to simple smoothing in 1957 and Winters added a season in 1960, and the method
that carries both names is still the default forecast in much of retail and logistics. The idea is
the one from the last section, three times over. **Each week updates three numbers, each with its own
memory:**

- the **level**, smoothed with `alpha`, as before;
- the **trend**, the level's change per week, smoothed with `beta`;
- the **season**, one index per week of the year, smoothed with `gamma`.

A forecast `h` weeks ahead is the level, plus `h` times the trend, times the seasonal index of that
week. The choices from lesson 2 carry straight over: the season multiplies, because Panela's
swings grow with the business.

```schooling-example
{"language": "python", "file": "hw.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.tsa.holtwinters import ExponentialSmoothing\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-12-28\"]\ntrain, test = weekly[:\"2024-12-29\"], weekly[\"2025-01-05\":]", "note": "Train on 2023 and 2024 and keep 2025 aside, so the forecast can be checked against weeks it never saw. The same split is used in lessons 4 and 5."}, {"code": "model = ExponentialSmoothing(train, trend=\"add\", seasonal=\"mul\", seasonal_periods=52)\nfit = model.fit()\np = fit.params\nprint(f\"alpha {p['smoothing_level']:.3f}  beta {p['smoothing_trend']:.3f}  gamma {p['smoothing_seasonal']:.3f}\")", "note": "A trend that adds a fixed amount per week, and a season that multiplies, as lesson 2 found. `fit` chooses the three smoothing weights."}, {"code": "forecast = fit.forecast(8)\ntable = pd.DataFrame({\"forecast\": forecast.round(0), \"actual\": test.iloc[:8]})\nprint(table.rename_axis(None).to_string())", "note": "The first eight weeks of 2025, forecast and actual side by side."}], "output": "alpha 0.110  beta 0.000  gamma 0.000\n            forecast  actual\n2025-01-05    8171.0    7571\n2025-01-12    8659.0    8796\n2025-01-19    8844.0    8753\n2025-01-26    8587.0    8812\n2025-02-02    8653.0    8422\n2025-02-09    8181.0    8458\n2025-02-16    7669.0    8767\n2025-02-23    8354.0    8582"}
```

**Read the three weights before the forecasts.** `alpha` is 0.110, a long memory for the level.
`beta` and `gamma` are 0.000: the method decided that the trend's slope and the seasonal indices
should not change at all over the two years, which is the same thing as saying they were stable
enough to be estimated once. On another series, with a season that drifts, `gamma` would come out
larger.

The forecasts follow the actual weeks closely, within a few hundred orders, with two exceptions
worth naming. The week ending 5 January is over-forecast: the New Year week of 2025 fell more
steeply than the one the method learnt from. And **the week ending 16 February is forecast at
7,669 against an actual 8,767**: in 2024 that week of the year held Carnival, the seasonal index
remembers it, and in 2025 Carnival came in March. Lesson 2's residuals predicted exactly this
mistake. Lesson 6 removes it.

How good is "close"? Lesson 5 answers that with numbers, against the baselines of the last section.
