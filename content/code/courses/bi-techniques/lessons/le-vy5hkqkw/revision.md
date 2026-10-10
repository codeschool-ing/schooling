---
title: Revision: the forecast changes, and that is the point
version: 1
---

**A forecast is made again whenever new data arrives**, and each time it may say something
different. People who see a forecast change often conclude that the first one was wrong and the
method is unreliable. Usually the opposite is true: a method whose forecast never moved when new
weeks came in would be ignoring them.

This makes a forecast of one week, the last week of June 2025, seven times: first at the end of
2024, then every four weeks as 2025 unfolds.

```schooling-example
{"language": "python", "file": "revision.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.tsa.holtwinters import ExponentialSmoothing\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-08-31\"]\ntarget = pd.Timestamp(\"2025-06-29\")", "note": "One target week, the last of June 2025."}, {"code": "print(f\"forecasts of the week ending {target.date()}, actual {weekly[target]}\")\nfor origin in weekly[\"2024-12-29\":\"2025-06-22\"].index[::4]:\n    fit = ExponentialSmoothing(weekly[:origin], trend=\"add\", seasonal=\"mul\",\n                               seasonal_periods=52).fit()\n    h = (target - origin).days // 7\n    print(f\"  made {origin.date()}, {h:2} weeks ahead: {fit.forecast(h).iloc[-1]:7.0f}\")", "note": "Every four weeks, refit on everything known so far and forecast the same target week again."}], "output": "forecasts of the week ending 2025-06-29, actual 11166\n  made 2024-12-29, 26 weeks ahead:   11399\n  made 2025-01-26, 22 weeks ahead:   11362\n  made 2025-02-23, 18 weeks ahead:   11561\n  made 2025-03-23, 14 weeks ahead:   11352\n  made 2025-04-20, 10 weeks ahead:   11331\n  made 2025-05-18,  6 weeks ahead:   11307\n  made 2025-06-15,  2 weeks ahead:   11157"}
```

Most revisions moved the forecast by a few dozen orders. The one exception has a name: the
February vintage jumped by about 200, because the week ending 16 February came in high, with no
Carnival in it, and the level rose; four weeks later Carnival arrived in March and the next vintage
took the jump back. The last vintage, two weeks ahead, said 11,157 against 11,166 that happened.
That is the normal shape: **revisions settle as the target approaches**, and when one jumps, the
jump should be explainable by something in the new weeks. A series of revisions that jump around
for no nameable reason is a sign the method is reacting to noise.

## Keep every vintage

A forecast made on a date is called a **vintage**. The dangerous habit is to overwrite the old
vintage with the new one, so the report only ever shows the latest number. Three things are lost
when that happens:

- **accountability**: the budget was set on the January vintage, and nobody can now say what it
  said;
- **measurement**: lesson 5 measures error at each horizon, which needs the forecast as it was
  made at that horizon, not as it was revised later;
- **learning**: a method that is always too optimistic three months out shows that only if the
  three-month-old vintages are kept.

The practice is cheap: store every forecast with the date it was made, the horizon and the model
version, and never update a row. It is the same append-only discipline that keeps any history
honest.
