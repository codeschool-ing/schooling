---
title: STL, the decomposition that reaches the ends
version: 1
---

The classical decomposition has three weaknesses you have now seen: it loses half a period at each
end, it insists the season is identical every year, and one strange week pulls every average it
belongs to. **STL**, Seasonal and Trend decomposition using Loess, was designed in 1990 to fix all
three, and it is what most practitioners reach for today.

It replaces the moving averages with **loess**, a smoother that fits a small weighted regression
around each point. A regression can be fitted at the edge of the data, so the trend reaches both
ends. The season is smoothed across years rather than averaged, so it may change slowly. And with
`robust=True` it fits, looks at which weeks it explained worst, and fits again giving them less
weight.

```schooling-example
{"language": "python", "file": "stl.py", "parts": [{"code": "import numpy as np\nimport pandas as pd\nfrom statsmodels.tsa.seasonal import STL\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-08-31\"]", "note": "The weeks up to the end of August 2025, before the price rise. Lesson 6 runs the same thing on the whole series and shows what the rise does to it."}, {"code": "parts = STL(np.log(weekly), period=52, robust=True).fit()\ntrend = np.exp(parts.trend)", "note": "STL adds, so it is given the logarithm of a series that multiplies, and the trend is turned back with `exp`. `robust=True` lets it give little weight to weeks that look like outliers."}, {"code": "print(f\"trend runs from {trend.index[0].date()} to {trend.index[-1].date()}\")\nfor week in [\"2023-01-08\", \"2024-01-07\", \"2025-01-05\", \"2025-08-31\"]:\n    print(f\"  {week}  {trend[week]:8.0f}\")", "note": "The trend at the first week of each year and at the last week of the data."}], "output": "trend runs from 2023-01-08 to 2025-08-31\n  2023-01-08      5935\n  2024-01-07      7556\n  2025-01-05      9353\n  2025-08-31     10645"}
```

**The trend now covers every week**, from the first to the last week of August 2025, where the classical one stopped 26
weeks short of each end. It grew from 5,935 orders a week at the start of 2023 to 10,645 by the end of
August 2025.

That reach has a cost, and it is the cost of every estimate at the edge of data. **The last few
values of an STL trend are provisional**: they were fitted with neighbours on one side only, and
next month's data will move them. A trend's latest value is the least certain value it has, even
though it is the one everybody reads.

STL also brings a choice the classical method never offered: how quickly the season may change.
Let it change too easily and a change in the business is read as a change in the season. Lesson 6
shows exactly that happening to Panela's price rise.
