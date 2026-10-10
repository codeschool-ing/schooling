---
title: Holidays that move
version: 1
---

**A season assumes the same thing happens at the same point of every year.** Holidays break that
in two ways. Some move between months or weeks: Carnival, Easter, Corpus Christi, and abroad Chinese
New Year or Ramadan. Others stay on their date and move across the week: Christmas on a Saturday is
a different event for a business busy on Mondays than Christmas on a Monday. Lesson 2's residuals
showed both kinds smeared over the weeks they had occupied.

## The year-on-year trap

The first place a moving holiday does damage is not a model. It is the most common comparison in
business reporting, this month against the same month last year:

```schooling-example
{"language": "python", "file": "monthly.py", "parts": [{"code": "import pandas as pd\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nmonthly = orders.resample(\"MS\").sum()", "note": "Monthly totals, each labelled with the first day of its month."}, {"code": "for months in ([\"02\"], [\"03\"], [\"02\", \"03\"]):\n    now = sum(monthly[f\"2025-{m}\"].iloc[0] for m in months)\n    before = sum(monthly[f\"2024-{m}\"].iloc[0] for m in months)\n    label = \" and \".join({\"02\": \"February\", \"03\": \"March\"}[m] for m in months)\n    print(f\"{label:21} 2024 {before:7,}  2025 {now:7,}  change {now / before - 1:+6.1%}\")", "note": "Year-on-year change for February, for March, and for the two together."}], "output": "February              2024  27,933  2025  34,770  change +24.5%\nMarch                 2024  33,306  2025  37,972  change +14.0%\nFebruary and March    2024  61,239  2025  72,742  change +18.8%"}
```

A director reading the first line sees February up 24.5% and March up 14.0%, and asks what went
so much better in February. Nothing did. **Carnival fell in February in 2024 and in March in 2025**,
so February 2025 was compared with a February that had Carnival in it, and March 2025 carried a
Carnival that March 2024 did not. Taken together the two months grew 18.8%, which is the honest
figure, and it sits between the two misleading ones.

The fix in a report is to compare periods that contain the holiday in both years, as the third line
does, or to say beside the number that the holiday moved. The fix in a model is the next part.

## Telling the model the dates

Carnival's dates are known decades ahead, so they can be handed to the model as data: a column that
says how many Carnival days each week holds. statsmodels calls such a column `exog`, an
**exogenous** series, which means one that comes from outside the series being forecast.

```schooling-example
{"language": "python", "file": "holiday.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.tsa.statespace.sarimax import SARIMAX\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nweekly = orders.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-12-28\"]"}, {"code": "carnival = [\"2023-02-21\", \"2024-02-13\", \"2025-03-04\"]\ndays = pd.Series(0, index=orders.index)\nfor tuesday in pd.to_datetime(carnival):\n    days[tuesday - pd.Timedelta(days=3):tuesday] = 1\nshare = days.resample(\"W-SUN\").sum()[\"2023-01-08\":\"2025-12-28\"].to_frame(\"carnival_days\")", "note": "The holiday as data: a 1 on each day from Saturday to Carnival Tuesday, added up per week. A week can hold four Carnival days, or two if the holiday straddles a Sunday."}, {"code": "train, test = weekly[:\"2024-12-29\"], weekly[\"2025-01-05\":\"2025-06-29\"]\nfit = SARIMAX(train, exog=share[:\"2024-12-29\"], order=(1, 0, 1),\n              seasonal_order=(0, 1, 0, 52), trend=\"c\").fit(disp=False)\nprint(f\"each Carnival day in a week: {fit.params['carnival_days']:+.0f} orders\")", "note": "The seasonal ARIMA of lesson 3, now with `exog`: an outside series the model may use. It estimates how many orders a Carnival day is worth."}, {"code": "forecast = fit.forecast(len(test), exog=share[\"2025-01-05\":\"2025-06-29\"])\nplain = SARIMAX(train, order=(1, 0, 1), seasonal_order=(0, 1, 0, 52),\n                trend=\"c\").fit(disp=False).forecast(len(test))\ntable = pd.DataFrame({\"without\": plain, \"with Carnival\": forecast, \"actual\": test}).round(0)\nprint(table[\"2025-02-09\":\"2025-03-16\"].rename_axis(None).to_string())\nfor name, f in ((\"without\", plain), (\"with Carnival\", forecast)):\n    print(f\"MAE {name:14} {(f - test).abs().mean():6.1f}\")", "note": "The forecast has to be told 2025's Carnival days too. That is the point: the dates are known in advance, so they can be given to the model."}], "output": "each Carnival day in a week: -322 orders\n            without  with Carnival  actual\n2025-02-09   8314.0         8957.0    8458\n2025-02-16   8092.0         8735.0    8767\n2025-02-23   9011.0         9011.0    8582\n2025-03-02   9186.0         8543.0    8189\n2025-03-09   9338.0         8695.0    7794\n2025-03-16   9449.0         9449.0    8723\nMAE without         362.0\nMAE with Carnival   301.3"}
```

**The model estimates a Carnival day at about −322 orders**, and with that it corrects both of the
weeks lesson 3 got wrong. The week ending 16 February, which held Carnival in 2024 and not in 2025,
is now forecast at 8,735 against an actual 8,767. The weeks where Carnival really fell in 2025 are
lowered, though not far enough: the week ending 9 March is still forecast 8,695 against 7,794, so
the per-day effect is underestimated from only two Carnivals in the training years. Over the 26
weeks the MAE falls from 362.0 to 301.3.

That is the same idea as Prophet's holiday list from lesson 3, built from parts you already have.
Two cautions come with it. A regressor needs **its future values at forecast time**: a holiday
calendar is fine, next month's weather is not. And every holiday added is one more number to
estimate from a handful of occurrences, so add the ones big enough to see in the residuals and no
more.
