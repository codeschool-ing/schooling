---
title: Defining churn
version: 1
---

**A customer has churned when they will not come back.** Nobody can observe that: a customer who has
not ordered for a month may be on holiday, may order next week, or may have gone for good. A
subscription that is cancelled gives a clear event; most businesses, Panela included for customers
who simply stop ordering, have to define churn from silence.

```schooling-example
{"language": "python", "file": "churn.py", "parts": [{"code": "import pandas as pd\n\ncustomers = pd.read_csv(\"customers.csv\", parse_dates=[\"signup\"])\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])\ncohort = customers[customers[\"signup\"].dt.to_period(\"M\") == \"2024-01\"]\nmine = orders[orders[\"customer\"].isin(cohort[\"customer\"])].merge(cohort, on=\"customer\")\nmine[\"month\"] = (mine[\"date\"].dt.to_period(\"M\") - mine[\"signup\"].dt.to_period(\"M\")).apply(lambda d: d.n)", "note": "The January 2024 cohort and its orders."}, {"code": "last = mine.groupby(\"customer\")[\"month\"].max()\nprint(\"January 2024 cohort,\", len(cohort), \"customers\")\nprint(f\"{'month':>5} {'ordered that month':>19} {'still to order again':>21}\")\nfor m in (1, 3, 6, 12):\n    active = mine[mine[\"month\"] == m][\"customer\"].nunique() / len(cohort)\n    alive = (last >= m).sum() / len(cohort)\n    print(f\"{m:>5} {active:>19.0%} {alive:>21.0%}\")", "note": "Two ways to count a customer at an age: ordered in that month, or still had an order to come at that age or later."}, {"code": "gaps = orders.sort_values(\"date\").groupby(\"customer\")[\"date\"].diff().dt.days.dropna()\nprint(f\"\\ngaps between one order and the next, {len(gaps):,} of them\")\nfor q in (0.5, 0.9, 0.95, 0.99):\n    print(f\"  {q:.0%} of gaps are at most {gaps.quantile(q):.0f} days\")", "note": "Every gap between a customer's order and their next one, in days, and how long the longest of them are."}], "output": "January 2024 cohort, 272 customers\nmonth  ordered that month  still to order again\n    1                 88%                   91%\n    3                 70%                   73%\n    6                 49%                   49%\n   12                 25%                   26%\n\ngaps between one order and the next, 97,772 of them\n  50% of gaps are at most 7 days\n  90% of gaps are at most 21 days\n  95% of gaps are at most 28 days\n  99% of gaps are at most 42 days"}
```

The first table compares two counts for the January 2024 cohort. **"Ordered that month"** is the
activity retention of lesson 12. **"Still to order again"** counts a customer as alive at an age if
they place any order at that age or later. At Panela the two are within a few points, 88% against
91% in month 1, because customers who stop rarely come back. In a business where people skip months,
a gym or a streaming service, the two can be far apart, and the first underestimates how many
customers are still customers.

## Choosing the silence that counts

The second table is the basis of a defensible definition. Half of Panela's gaps between orders are a
week, the time between weekly boxes; **95 per cent are at most 28 days, and 99 per cent at most
42.** A customer silent for longer than nearly every gap that ended in another order is very likely
gone.

So a definition such as **"churned: no order for 42 days"** comes from the data rather than from a
round number, and the choice of percentile is a trade:

- **too short a silence**, 14 days, counts as churned many customers who were only between boxes,
  and a retention campaign spends its discounts on people who were coming back anyway;
- **too long a silence**, 120 days, notices churn months after it happened, too late to do anything.

Two cautions. **The threshold differs between groups whose ordering rhythm differs**: fortnightly
customers have longer normal gaps than weekly ones, and lesson 18 shows Panela's North receiving its
boxes a week later than everybody else, so one threshold for everybody treats the North as more
"churned" than it is. And **churn can only be judged where the silence has had time to happen**: a
customer whose last order was ten days before the data ends is undecided, not active.
