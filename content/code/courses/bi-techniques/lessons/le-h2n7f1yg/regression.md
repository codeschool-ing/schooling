---
title: Regression: predicting a number
version: 1
---

**Regression predicts a number for each case**: here, how much each customer will spend in the next
90 days. The machinery is the same as classification's, with an amount in place of a category, and it
is judged with the measures of lesson 5.

```schooling-example
{"language": "python", "file": "spend_model.py", "parts": [{"code": "import pandas as pd\nfrom sklearn.linear_model import LinearRegression\n\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])"}, {"code": "def snapshot(day):\n    day = pd.Timestamp(day)\n    past = orders[orders[\"date\"] <= day]\n    last_90 = past[past[\"date\"] > day - pd.Timedelta(days=90)]\n    next_90 = orders[(orders[\"date\"] > day) & (orders[\"date\"] <= day + pd.Timedelta(days=90))]\n    t = pd.DataFrame({\"spent_90\": last_90.groupby(\"customer\")[\"value\"].sum(),\n                      \"recency\": (day - past.groupby(\"customer\")[\"date\"].max()).dt.days})\n    t = t.dropna()\n    t[\"next_90\"] = next_90.groupby(\"customer\")[\"value\"].sum().reindex(t.index).fillna(0)\n    return t", "note": "For each customer who ordered in the last 90 days: what they spent in those 90 days, how many days since their last order, and the answer, what they spent in the next 90 days, zero if nothing."}, {"code": "train, test = snapshot(\"2024-12-31\"), snapshot(\"2025-06-30\")\nmodel = LinearRegression().fit(train[[\"spent_90\", \"recency\"]], train[\"next_90\"])\npredicted = model.predict(test[[\"spent_90\", \"recency\"]])", "note": "The same split in time as the churn model, with linear regression, the model of `statistics` lesson 19."}, {"code": "print(f\"{len(test):,} customers who ordered in the 90 days before 30 Jun 2025\")\nprint(f\"coefficients: spent_90 {model.coef_[0]:.2f}, recency {model.coef_[1]:.2f}, \"\n      f\"intercept {model.intercept_:.0f}\")\nprint(f\"MAE of the model:              {abs(predicted - test['next_90']).mean():5.0f} reais\")\nprint(f\"MAE of repeating the last 90:  {abs(test['spent_90'] - test['next_90']).mean():5.0f} reais\")\nprint(f\"total predicted {predicted.sum():,.0f}, total actual {test['next_90'].sum():,.0f}\")", "note": "The model's error against the simplest guess, that the next 90 days will repeat the last 90, as lesson 5 compared forecasts with the naive one."}], "output": "2,775 customers who ordered in the 90 days before 30 Jun 2025\ncoefficients: spent_90 0.49, recency -15.24, intercept 711\nMAE of the model:                549 reais\nMAE of repeating the last 90:    591 reais\ntotal predicted 2,927,218, total actual 3,083,457"}
```

The coefficients read as plain arithmetic: each real spent in the last 90 days predicts about 0.49
reais in the next 90, and each day of silence takes about 15 reais off. That the first is below 1 says
that customers, on average, spend less in the next quarter than in the last, because some of them
leave.

**The model's MAE is 549 reais against 591 for the naive guess** that the next quarter repeats the
last. A modest improvement, and an honest one: most of what can be known about a customer's next
quarter is already in their last one. A model that beat the naive guess by a wide margin on data like
this should be checked for a leak, an input that secretly contains the answer, before it is believed.

**The total is closer than the individuals.** Predicted spend over all customers is R$ 2,927,218 against
R$ 3,083,457 actual, about 5 per cent short, while individual customers are off by hundreds of reais. Errors
in different directions cancel in a sum, which is why a model too noisy to say what one customer will
do can still be useful for a budget. It is the same reason lesson 4 aggregated to the grain of the
decision.
