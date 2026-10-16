---
title: RFM scores
version: 1
---

RFM describes each customer with three numbers that, together, predict a surprising share of what
they will do next:

- **Recency**: how many days since the last order. The single best predictor of whether a customer
  will order again.
- **Frequency**: how many orders in a period, here the last year.
- **Monetary**: how much they spent in the same period.

```schooling-example
{"language": "python", "file": "rfm.py", "parts": [{"code": "import pandas as pd\n\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])\ntoday = pd.Timestamp(\"2025-12-31\")\nyear = orders[orders[\"date\"] > today - pd.Timedelta(days=365)]", "note": "Everything is measured as of the last day of the data, over the last 365 days."}, {"code": "rfm = pd.DataFrame({\n    \"recency\": (today - orders.groupby(\"customer\")[\"date\"].max()).dt.days,\n    \"frequency\": year.groupby(\"customer\").size(),\n    \"monetary\": year.groupby(\"customer\")[\"value\"].sum(),\n}).dropna()\nprint(f\"{len(rfm):,} customers with an order in the last 365 days\")\nprint(rfm.describe().loc[[\"min\", \"25%\", \"50%\", \"75%\", \"max\"]].round(0).to_string())", "note": "Recency is days since the last order; frequency and monetary are the orders and reais of the last year. `dropna` keeps only customers who ordered in that year."}, {"code": "rfm[\"R\"] = pd.qcut(rfm[\"recency\"].rank(method=\"first\"), 5, labels=[5, 4, 3, 2, 1]).astype(int)\nrfm[\"F\"] = pd.qcut(rfm[\"frequency\"].rank(method=\"first\"), 5, labels=[1, 2, 3, 4, 5]).astype(int)\nrfm[\"M\"] = pd.qcut(rfm[\"monetary\"].rank(method=\"first\"), 5, labels=[1, 2, 3, 4, 5]).astype(int)\nprint(\"\\nthe first three customers and their scores\")\nprint(rfm.head(3).to_string())\nrfm.to_csv(\"rfm.csv\")", "note": "Each number is cut into five equal-sized groups, quintiles, scored 1 to 5. Recency is reversed: a recent order is a high score. The table is saved for the next two programs."}], "output": "4,679 customers with an order in the last 365 days\n     recency  frequency  monetary\nmin      0.0        1.0     160.0\n25%      6.0        5.0     983.0\n50%     33.0       11.0    2239.0\n75%    196.0       21.0    4237.0\nmax    364.0       52.0   15059.0\n\nthe first three customers and their scores\n          recency  frequency  monetary  R  F  M\ncustomer                                       \nc00005         79       27.0   7725.24  3  5  5\nc00006          2       29.0   4828.98  5  5  4\nc00010          8       37.0  10636.20  4  5  5"}
```

The distribution shows why scores are used rather than the raw numbers. Recency runs from 0 to
364 days, frequency from 1 to 52 orders, spend from 160 to 15,059 reais: three scales nobody can
compare by eye. **Quintile scores put all three on the same 1-to-5 scale**, each score holding a fifth
of the customers, so "R5 F5" means "in the most recent fifth and the most frequent fifth", whatever
the units.

Two details of the program are worth knowing.

- **Recency is reversed.** Few days since the last order is good, so the smallest recencies get a 5.
- **`rank(method="first")` breaks ties.** A quarter of these customers ordered within the last 6
  days, so many share the same recency; cutting tied values into five equal groups is impossible
  without first giving every customer a distinct rank. The cost is that two customers with the same
  recency can land in neighbouring scores. With few distinct values, scores in fewer groups, such
  as three, are the honest alternative.
