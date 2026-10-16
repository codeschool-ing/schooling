---
title: Finding the cause
version: 1
---

An audit says that a group is treated differently. It does not say why, and **the why decides the
fix**. A difference that comes from the North's customers really behaving differently would call for
one answer; a difference that comes from the model misreading them calls for another. The place to
start is the model's inputs, and what each one looks like for the group.

```schooling-example
{"language": "python", "file": "rhythm.py", "parts": [{"code": "import pandas as pd\n\ncustomers = pd.read_csv(\"customers.csv\").set_index(\"customer\")\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"]).sort_values(\"date\")\norders[\"gap\"] = orders.groupby(\"customer\")[\"date\"].diff().dt.days\norders = orders.join(customers, on=\"customer\")\nprint(\"median days between a customer's orders\")\nprint(orders.pivot_table(index=\"region\", columns=\"plan\", values=\"gap\", aggfunc=\"median\"))", "note": "The days between each order and the same customer's previous one, then the median by region and plan: the rhythm at which each kind of customer orders."}, {"code": "scored = pd.read_csv(\"scored.csv\", index_col=\"customer\")\nstayed = scored[scored[\"churned\"] == 0]\nprint(\"\\ncustomers who stayed, on 30 Jun 2025\")\nprint(stayed.groupby(\"region\")[[\"recency\", \"orders_90\", \"risk\"]].mean().round(2))", "note": "Only the customers who stayed: what the model saw of them, and the risk it gave them."}], "output": "median days between a customer's orders\nplan       fortnightly  weekly\nregion                        \nNorth             21.0    14.0\nNortheast         14.0     7.0\nSouth             14.0     7.0\nSoutheast         14.0     7.0\n\ncustomers who stayed, on 30 Jun 2025\n           recency  orders_90  risk\nregion                             \nNorth        11.84       3.80  0.14\nNortheast     7.67       6.96  0.09\nSouth         7.10       6.75  0.09\nSoutheast     7.35       6.68  0.09"}
```

The first table is the cause. **A customer in the North orders every 14 days on the weekly plan and
every 21 on the fortnightly one**, a week slower than the same plan anywhere else, because deliveries
reach the North a week later. The second table is how the model sees it: the North's loyal customers
have a recency of 11.84 days against 7.10 to 7.67 elsewhere, and 3.80 orders in 90 days against 6.68
to 6.96.
Both inputs say "fading", and the model, which learnt from a population that is 74 per cent Southeast,
reads them the way they read in the Southeast. **Its average risk for a loyal customer in the North is
0.14, against 0.09 everywhere else.**

This is **measurement bias**. Recency and the order count were chosen as measures of engagement, and
for most customers they are. For a customer whose box arrives a week late, they measure geography.
Nothing is wrong with the data: every date in it is correct. What is wrong is the assumption that
eleven days of silence means the same thing for everybody.

It is also a case of **aggregation bias**, since one model was fitted to all four regions. And it is
representation bias, since the North is too small a share of the training data for the model to learn
its rhythm on its own.

## A cause is a claim

That deliveries take a week longer is something Panela's logistics team can confirm or deny, and an
analyst should ask them before building a fix on it. The data shows a slower rhythm; the reason for the
rhythm comes from outside the data. A fix for the wrong cause can leave the disparity in place and add
a story that makes everybody stop looking.
