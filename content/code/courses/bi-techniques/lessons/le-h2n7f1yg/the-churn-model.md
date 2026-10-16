---
title: A churn model
version: 1
---

**A classification model estimates, for each case, the probability that it belongs to a category.**
Here the case is a customer who is still ordering, and the category is "will not order in the next
90 days". The model is **logistic regression**, the model of `statistics` lesson 21: it weighs the
inputs, adds them up, and turns the sum into a probability between 0 and 1.

The split matters more than the model. The customers it learns from are those of 31 December 2024,
whose next 90 days are already known; the customers it is tested on are those of 30 June 2025. **A
model used to predict the future is tested on a future**, exactly as the forecasts of lessons 3 to 5
were. Splitting the customers at random instead would let the model learn from customers whose
behaviour overlaps in time with the ones it is tested on, and report an accuracy it will not have in
use.

```schooling-example
{"language": "python", "file": "churn_model.py", "parts": [{"code": "import pandas as pd\nfrom sklearn.linear_model import LogisticRegression\nfrom sklearn.metrics import confusion_matrix\n\ncustomers = pd.read_csv(\"customers.csv\", parse_dates=[\"signup\"]).set_index(\"customer\")\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])"}, {"code": "def snapshot(day):\n    day = pd.Timestamp(day)\n    past = orders[orders[\"date\"] <= day]\n    recent = past[past[\"date\"] > day - pd.Timedelta(days=90)]\n    after = orders[(orders[\"date\"] > day) & (orders[\"date\"] <= day + pd.Timedelta(days=90))]\n    t = pd.DataFrame({\"recency\": (day - past.groupby(\"customer\")[\"date\"].max()).dt.days,\n                      \"orders_90\": recent.groupby(\"customer\").size()}).fillna({\"orders_90\": 0})\n    t = t.join(customers)\n    t[\"tenure\"] = (day - t[\"signup\"]).dt.days\n    t[\"social\"] = (t[\"channel\"] == \"social\").astype(int)\n    t[\"referral\"] = (t[\"channel\"] == \"referral\").astype(int)\n    t[\"weekly\"] = (t[\"plan\"] == \"weekly\").astype(int)\n    t = t[t[\"recency\"] <= 60]\n    t[\"churned\"] = (~t.index.isin(after[\"customer\"])).astype(int)\n    return t", "note": "Everything known about each customer on a given day, and the answer: churned means no order in the 90 days after it. Only customers who ordered in the last 60 days are kept, because the question is about customers who are still here. Channel and plan become 0-or-1 columns, the form a model can use."}, {"code": "inputs = [\"recency\", \"orders_90\", \"tenure\", \"social\", \"referral\", \"weekly\"]\ntrain, test = snapshot(\"2024-12-31\"), snapshot(\"2025-06-30\")\nmodel = LogisticRegression(max_iter=1000).fit(train[inputs], train[\"churned\"])\ntest[\"risk\"] = model.predict_proba(test[inputs])[:, 1]\ntest.to_csv(\"scored.csv\")", "note": "Learn on the customers of 31 December 2024, whose next 90 days are known, and score the customers of 30 June 2025: a split by time, as in the forecasting lessons. `predict_proba` gives each customer a probability of churning. The scores are saved for the next section."}, {"code": "print(f\"train: {len(train):,} customers on 31 Dec 2024, {train['churned'].mean():.1%} churned\")\nprint(f\"test:  {len(test):,} customers on 30 Jun 2025, {test['churned'].mean():.1%} churned\")\nflag = (test[\"risk\"] >= 0.5).astype(int)\ntn, fp, fn, tp = confusion_matrix(test[\"churned\"], flag).ravel()\nprint(f\"\\nat a threshold of 0.5: {tp} churners caught, {fn} missed, {fp} false alarms, {tn} left alone\")\nprint(f\"accuracy {(tp + tn) / len(test):.1%}, precision {tp / (tp + fp):.1%}, recall {tp / (tp + fn):.1%}\")\nprint(f\"predicting 'stays' for everyone: accuracy {1 - test['churned'].mean():.1%}, recall 0.0%\")", "note": "Flag every customer with a probability of at least 0.5, and count the four possible outcomes."}], "output": "train: 2,130 customers on 31 Dec 2024, 18.2% churned\ntest:  2,558 customers on 30 Jun 2025, 16.5% churned\n\nat a threshold of 0.5: 204 churners caught, 217 missed, 55 false alarms, 2082 left alone\naccuracy 89.4%, precision 78.8%, recall 48.5%\npredicting 'stays' for everyone: accuracy 83.5%, recall 0.0%"}
```

The model learnt from 2,130 customers and was tested on 2,558, of whom 16.5 per cent churned. The four counts are
the **confusion matrix**, the table every classifier is read from:

| | predicted to churn | predicted to stay |
|---|---|---|
| **churned** | 204 caught, true positives | 217 missed, false negatives |
| **stayed** | 55 false alarms, false positives | 2,082 left alone, true negatives |

The next section reads it.
