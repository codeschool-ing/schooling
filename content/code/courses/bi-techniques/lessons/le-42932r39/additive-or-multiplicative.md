---
title: Added or multiplied
version: 1
---

Before taking a series apart you have to say how its parts were put together. There are two ways,
and choosing the wrong one gives a season that is wrong at both ends of the data.

- **Additive**: the series is trend + season + noise. A Monday is a fixed number of orders above
  the level, whatever the level is.
- **Multiplicative**: the series is trend × season × noise. A Monday is a fixed *proportion* above
  the level, so as the business grows, the gap in orders grows with it.

The test is whether the swing grows with the level. This compares Mondays with Saturdays in each
year:

```schooling-example
{"language": "python", "file": "swing.py", "parts": [{"code": "import pandas as pd\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]"}, {"code": "monday = orders[orders.index.dayofweek == 0]\nsaturday = orders[orders.index.dayofweek == 5]\nyears = pd.DataFrame({\n    \"monday\": monday.groupby(monday.index.year).mean(),\n    \"saturday\": saturday.groupby(saturday.index.year).mean(),\n})", "note": "Average every Monday and every Saturday, separately for each year."}, {"code": "years[\"difference\"] = years[\"monday\"] - years[\"saturday\"]\nyears[\"ratio\"] = years[\"monday\"] / years[\"saturday\"]\nprint(years.round(2).rename_axis(None).to_string())", "note": "The difference is the swing in orders; the ratio is the swing as a proportion of the level."}], "output": "       monday  saturday  difference  ratio\n2023  1121.00    825.12      295.88   1.36\n2024  1441.89   1063.73      378.16   1.36\n2025  1639.17   1194.27      444.90   1.37"}
```

**The difference grows by half while the ratio barely moves.** A Monday was 296 orders above a
Saturday in 2023 and 445 in 2025, but in both years it was about 36 per cent above. Panela's
season is multiplicative, which is what most business series are: a bigger company has a bigger
Monday.

An additive model fitted here would use one average gap for all three years, about 373 orders,
and so understate the weekly swing in 2025 and overstate it in 2023. The residuals would show it:
a weekly ripple, negative at one end of the data and positive at the other.

## The logarithm turns one into the other

The logarithm of a product is the sum of the logarithms, so **a multiplicative series becomes
additive once you take its log**. That is why so many time-series programs start with
`np.log(series)`: a method that only knows how to add can then handle a season that multiplies,
and the results are turned back with `np.exp`. The STL decomposition of two sections from now
does exactly this.

On a log scale, a constant ratio is a constant distance. A series whose swings look like they are
growing on an ordinary chart, and look steady on a log chart, is multiplicative.
