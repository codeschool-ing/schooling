---
title: The seasonally adjusted series
version: 1
---

A trend answers "where is the business heading" and has no value for the latest weeks. **The
seasonally adjusted series answers "how did this week do, season aside"**, and it exists for every
week. It is the observed series with only the season taken out: trend and noise stay in.

It is what official statistics publish when they say *seasonally adjusted*, and it is what you
should show when somebody compares one month with the month before.

```schooling-example
{"language": "python", "file": "adjusted.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.tsa.seasonal import seasonal_decompose\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-12-28\"]\nparts = seasonal_decompose(weekly, model=\"multiplicative\", period=52)", "note": "The same decomposition as before."}, {"code": "table = pd.DataFrame({\n    \"observed\": weekly,\n    \"seasonal\": parts.seasonal.round(3),\n    \"adjusted\": (weekly / parts.seasonal).round(0),\n})\nprint(table[\"2024-12-08\":\"2025-01-26\"].to_string())", "note": "Dividing by the seasonal index gives the seasonally adjusted series. Unlike the trend, it exists for every week, ends included."}], "output": "            observed  seasonal  adjusted\ndate                                    \n2024-12-08      8986     0.960    9357.0\n2024-12-15      9175     0.981    9353.0\n2024-12-22     10804     1.104    9789.0\n2024-12-29      7743     0.797    9712.0\n2025-01-05      7571     0.812    9325.0\n2025-01-12      8796     0.913    9639.0\n2025-01-19      8753     0.913    9585.0\n2025-01-26      8812     0.898    9810.0"}
```

Read the observed column alone and the turn of the year is a collapse: from 10,804 orders in the
week before Christmas to 7,571 in the first week of 2025, a fall of 30 per cent. Somebody looking at
that would ask what went wrong.

**Nothing did.** Divided by its seasonal index, every week in the table sits between 9,325 and 9,810.
The collapse was the season: the week before Christmas is the busiest of the year and the first week
of January the quietest. Season aside, January was an ordinary month.

Two cautions come with it.

- **It still carries the noise**, so one adjusted week moving up or down is not news. Compare
  averages of several weeks, or use the trend when the question is direction.
- **It is only as good as the seasonal index.** The Carnival weeks of the last section are
  mis-adjusted in exactly the way their residuals showed, and an adjusted series quietly passes the
  mistake on to whoever reads it.
