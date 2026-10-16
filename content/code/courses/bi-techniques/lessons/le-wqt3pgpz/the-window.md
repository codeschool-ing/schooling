---
title: The observation window
version: 1
---

The table of the last section counted age in **calendar months**: an order placed in February by a
customer who joined in January is month 1, whether they joined on 1 January or on 31 January. That is
the simplest way to build the table, and it quietly gives different customers different amounts of
time.

```schooling-example
{"language": "python", "file": "windows.py", "parts": [{"code": "import pandas as pd\n\ncustomers = pd.read_csv(\"customers.csv\", parse_dates=[\"signup\"])\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])\norders = orders.merge(customers[[\"customer\", \"signup\"]], on=\"customer\")\njoined = customers[customers[\"signup\"] < \"2025-06-01\"].copy()\njoined[\"part\"] = pd.cut(joined[\"signup\"].dt.day, [0, 10, 20, 31],\n                        labels=[\"days 1-10\", \"days 11-20\", \"days 21-31\"])", "note": "Customers who signed up before June 2025, so that everybody has had at least thirty days, grouped by the part of the month they joined in."}, {"code": "calendar = orders[(orders[\"date\"].dt.to_period(\"M\") - orders[\"signup\"].dt.to_period(\"M\"))\n                  .apply(lambda d: d.n) == 0]\ndays = orders[(orders[\"date\"] - orders[\"signup\"]).dt.days < 30]", "note": "Two ways of saying \"the first month\": the rest of the calendar month they joined in, and the thirty days from the signup date."}, {"code": "joined[\"orders, rest of signup month\"] = joined[\"customer\"].map(calendar.groupby(\"customer\").size())\njoined[\"orders, first 30 days\"] = joined[\"customer\"].map(days.groupby(\"customer\").size())\nprint(joined.groupby(\"part\", observed=True)[[\"orders, rest of signup month\",\n                                             \"orders, first 30 days\"]].mean().round(2).to_string())", "note": "The average number of orders in each version of the first month."}], "output": "            orders, rest of signup month  orders, first 30 days\npart                                                           \ndays 1-10                           2.69                   3.24\ndays 11-20                          1.87                   3.22\ndays 21-31                          1.14                   3.21"}
```

**Customers who joined in the first ten days placed 2.69 orders in the rest of their signup month;
customers who joined in the last ten days placed 1.14.** They are not less keen. They had less of the
month left. Counted over thirty days from each customer's own signup, the three groups are almost
identical: 3.24, 3.22 and 3.21.

The same distortion runs through the whole table. Month 0 is a full month for some customers and a
day for others, and month 1 starts one day after signup for some and thirty days after for others.
Averaged over a cohort of a few hundred, joining dates are spread across the month and the errors
mostly cancel, which is why calendar months are still common. They stop cancelling the moment the
spread is uneven: a cohort dominated by a campaign on the 28th, or a month with a holiday at one
end.

## Choosing the window

| window | how age is counted | good for | watch out for |
|---|---|---|---|
| **calendar months** | month of the event minus month of the start | reports that line up with the calendar | uneven exposure inside month 0 and month 1 |
| **days since the start**, in blocks of 30 or 7 | days between the event and the start | comparing behaviour fairly | a "month" that is no longer a calendar month |

**Whichever is used, it is written beside the table.** A retention figure without its window cannot be
compared with another one, and two teams quoting "month-1 retention" from the two definitions can
differ by several points while both are right.
