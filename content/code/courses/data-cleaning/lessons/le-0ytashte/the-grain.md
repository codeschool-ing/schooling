---
title: The grain of a table
version: 1
---

The **grain** of a table is what one row stands for. In `order_items` a row is one line of one
order; in `orders`, one order; in the CRM, one customer. Every derived column belongs to a grain,
and most mistakes with derived columns are a column computed at one grain and used at another.

Customer-level columns are built by grouping the orders, so each customer becomes one row:

```schooling-example
{
  "language": "python",
  "file": "per_customer.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "from derive import orders\nfrom years import customers\n\n",
      "note": "The derived orders, and the customers with lesson 10's birth years."
    },
    {
      "code": "per = orders.groupby(\"customer_id\").agg(orders=(\"order_id\", \"size\"), revenue=(\"total\", \"sum\"),\n                                         first=(\"placed\", \"min\"), last=(\"placed\", \"max\"))\n",
      "note": "**One row per customer**: how many orders, how much, first and last."
    },
    {
      "code": "per[\"days_since\"] = (pd.Timestamp(\"2026-01-01\") - per[\"last\"]).dt.days\n",
      "note": "Whole days from the last order to 1 January 2026."
    },
    {
      "code": "per = per.join(customers.set_index(\"customer_id\")[\"birth\"])\n",
      "note": "The birth year, joined by customer code."
    },
    {
      "code": "per[\"age\"] = 2025 - per[\"birth\"]  # the age reached during 2025\n",
      "note": "**Age reached during 2025**: a birth year is all the CRM knows."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from per_customer import per; print(len(per)); print(per.head(3).to_string())"
2273
             orders  revenue               first                last  days_since  birth   age
customer_id                                                                                  
C00001           10   840.05 2025-01-23 19:50:14 2025-12-28 16:29:57           3   1986    39
C00002           23  1639.30 2025-01-16 11:47:40 2025-12-22 17:33:44           9   1982    43
C00003           12  1046.75 2025-01-24 15:20:48 2025-12-18 20:53:31          13   <NA>  <NA>
```

2,273 rows, one per customer code that placed an order in 2025: 2,241 of the CRM's 2,376
customers, and the 32 orphans of lesson 11, who have orders and no CRM row. `C00003` is one of the
orphans, so its `birth` and `age` are blank, like those of anyone whose birth year was a
placeholder. `days_since` counts from 1 January 2026, the day
after the data ends, so a customer whose last order was on 28 December is 3 days away.

Now the mistake. Suppose a report needs each order next to its customer's yearly revenue, which is
reasonable, and then somebody sums that column:

```
ana@lab:~/clean$ python -c "from derive import orders; from per_customer import per; wrong = orders.merge(per[['revenue']], left_on='customer_id', right_index=True); print(round(orders['total'].sum(), 2), round(wrong['revenue'].sum(), 2))"
2677679.5 52515704.25
```

Real revenue is R$ 2,677,679.50. The sum over the joined column is R$ 52,515,704.25, nearly
twenty times as much, because **a customer-level number was copied onto every one of that
customer's orders** and then added once per copy. A customer with 23 orders contributes their
revenue 23 times.

This is lesson 11's fan-out wearing different clothes, and the defence is the same idea: **know
the grain of every table and every column**. A customer-level column on an order-level table can
be shown, compared or used to filter, but never summed. When a column has to live at a coarser
grain, give it a name that says so, such as `customer_revenue`, so that the next person to reach
for `sum()` stops and reads it first.
