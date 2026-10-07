---
title: A pattern, not a value
version: 1
---

**Some anomalies hide in plain sight because no single value is unusual.** An order of R$ 200 with
status `refunded` is ordinary; refunds happen when a basket arrives damaged. Twenty-three of them
from one account in three days are not. The test for this kind is not a distance on a column but a
summary per entity — here, per customer:

```schooling-example
{
  "language": "python",
  "file": "refunds.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom orders import orders\n\n"
    },
    {
      "code": "orders[\"placed\"] = pd.to_datetime(orders[\"ordered_at\"].str[:19].str.replace(\"T\", \" \"))\n",
      "note": "A timestamp to measure spans with. The website's UTC and the app's local time differ by three hours, which does not matter for spans of days."
    },
    {
      "code": "per = orders.groupby(\"customer_id\").agg(\n    orders=(\"order_id\", \"count\"),\n    refunded=(\"status\", lambda s: (s == \"refunded\").sum()),\n    first=(\"placed\", \"min\"),\n    last=(\"placed\", \"max\"),\n)\n",
      "note": "**One row per customer**: orders, refunds, first and last order."
    },
    {
      "code": "per[\"refund_rate\"] = (per[\"refunded\"] / per[\"orders\"]).round(2)\n",
      "note": "The share of a customer's orders that were refunded."
    },
    {
      "code": "print(f\"customers: {len(per)}, median refund rate: {per['refund_rate'].median():.2f}\")\nprint(per.sort_values(\"refunded\", ascending=False).head(4).to_string())\n",
      "note": "The typical customer, and the four with the most refunds."
    }
  ]
}
```

```
ana@lab:~/clean$ python refunds.py
customers: 2273, median refund rate: 0.00
             orders  refunded               first                last  refund_rate
customer_id                                                                       
C01857           23        23 2025-08-12 10:33:15 2025-08-14 21:21:11         1.00
C01009           42         6 2025-01-05 21:06:05 2025-12-29 23:59:09         0.14
C00249           45         4 2025-01-04 18:19:53 2025-12-23 14:30:34         0.09
C00784           46         4 2025-02-03 19:03:14 2025-12-30 12:46:44         0.09
```

The median customer has a refund rate of zero. The next three customers with the most refunds have
a handful over a year of ordinary buying. **Customer C01857 placed 23 orders in under three days and
every one was refunded.** The account:

```
ana@lab:~/clean$ psql -c "SELECT DISTINCT customer_id, signed_up, signup_channel, normalize(city, NFC) AS city FROM raw.customers WHERE customer_id = (SELECT customer_id FROM raw.orders WHERE status = 'refunded' GROUP BY 1 ORDER BY count(*) DESC LIMIT 1)"
 customer_id | signed_up  | signup_channel |   city    
-------------+------------+----------------+-----------
 C01857      | 08/11/2025 | app            | São Paulo
(1 row)
```

Signed up through the app on 11 August, the day before the first order. A new account, an intense
burst, a refund on everything, and then silence: that is the shape of refund abuse, where somebody
claims that deliveries failed or arrived spoiled in order to keep the food and get the money back.

**This is a finding for the people who handle fraud, not a value to clean.** The analyst's job is to
detect and report it, with the evidence that makes it checkable: the account, the dates, the counts,
the comparison with every other customer. The other half of the job is keeping it out of analyses it
would distort, such as a refund rate by city. Deciding whether it is fraud is not the analyst's
call: there could be an explanation the data cannot show, such as a delivery route that failed every
day that week.

What makes the pattern visible is choosing the right unit. **Per order, nothing stands out; per
customer, one account stands alone.** The same move finds other patterns of abuse — many accounts
sharing one delivery address, coupons used on many new accounts in a single day — and lesson 15's
exploratory analysis is where the habit of summarising by entity becomes routine.
