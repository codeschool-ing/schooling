---
title: Cohorts that have not finished
version: 1
---

**A cohort can only be observed for as long as it has existed.** The January 2024 cohort has two
years of data; the June 2025 cohort has six months; the December 2025 cohort has one. That is why the
heatmap of two sections back is a triangle: the cells below the diagonal have not happened yet.
Statisticians call this **right-censoring**, because what is missing is on the right, in the future.

Censoring causes two kinds of mistake.

## The month still in progress

The newest cell of each cohort is often a month that has not ended. This runs the same month-1
calculation twice, once with the orders known on 15 December 2025 and once at the end of the month:

```schooling-example
{"language": "python", "file": "censor.py", "parts": [{"code": "import pandas as pd\n\ncustomers = pd.read_csv(\"customers.csv\", parse_dates=[\"signup\"])\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])\norders = orders.merge(customers[[\"customer\", \"signup\"]], on=\"customer\")\norders[\"cohort\"] = orders[\"signup\"].dt.to_period(\"M\")\nsize = customers.groupby(customers[\"signup\"].dt.to_period(\"M\")).size()"}, {"code": "def month_one(data):\n    later = data[data[\"date\"].dt.to_period(\"M\") == data[\"cohort\"] + 1]\n    return (later.groupby(\"cohort\")[\"customer\"].nunique() / size * 100).round(1)", "note": "Month-1 retention per cohort: the share who ordered in the calendar month after signing up."}, {"code": "final = month_one(orders)\nmid_december = month_one(orders[orders[\"date\"] <= \"2025-12-15\"])\ntable = pd.DataFrame({\"run on 15 Dec\": mid_december, \"run on 31 Dec\": final})\nprint(table.loc[\"2025-08\":\"2025-11\"].rename_axis(\"cohort\").to_string())", "note": "The same calculation run with the orders known on 15 December and on 31 December."}], "output": "         run on 15 Dec  run on 31 Dec\ncohort                               \n2025-08           91.0           91.0\n2025-09           92.5           92.5\n2025-10           87.8           87.8\n2025-11           81.0           92.0"}
```

On 15 December, **the November cohort's month-1 retention reads 81.0 per cent**, a collapse from the
cohorts before it. At the end of the month it reads 92.0. Nothing happened to the November customers:
half of their month 1 had not happened yet. It is lesson 6's incomplete data again, now inside a
cohort table, and the fix is the same: **leave out cells whose period has not ended**, or grey them out
and say why.

## Averaging columns of different lengths

The second mistake is averaging. "Average month-6 retention" across all cohorts can only use the
cohorts that are at least six months old, so it describes older cohorts only. "Average retention
curve" built by averaging each column uses a different set of cohorts in every column: month 1
averages all eighteen cohorts of the heatmap, month 12 only the twelve of 2024, and if the newer cohorts behave differently, the
curve bends where the set of cohorts changes rather than where behaviour does.

The safe practices:

- **compare cohorts at the ages all of them have reached**, and say which ages those are;
- **when averaging a curve, use the same cohorts in every column**, accepting a shorter curve;
- **weight by cohort size** when the cohorts differ much in size, or a small cohort moves the average
  as much as a large one.
