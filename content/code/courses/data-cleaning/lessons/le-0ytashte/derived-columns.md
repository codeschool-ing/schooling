---
title: Derived columns
version: 1
---

A **derived variable** is a column computed from others: the hour of an order from its timestamp,
the number of items from the order lines, a customer's age from a birth year. None of them adds
information that was not there. What they add is a question that can now be asked in one line:
are Saturday baskets bigger, do companies order more items, when does the app get busy.

The first step is a starting point everyone agrees on. Lesson 9 made three decisions about order
totals, and they are applied once, in one file, so no later column is built on a value that a
previous lesson already corrected:

```schooling-example
{
  "language": "python",
  "file": "ready.py",
  "parts": [
    {
      "code": "from orders import orders  # lesson 9: totals as numbers, each customer's name from the CRM\nfrom typos import wrong\nfrom when import orders as timed\n\n",
      "note": "Lesson 9's orders and its seven typed totals, and lesson 7's times in São Paulo."
    },
    {
      "code": "fix = orders[\"order_id\"].isin(wrong[\"order_id\"])\norders.loc[fix, \"total\"] = orders.loc[fix, \"order_id\"].map(wrong.set_index(\"order_id\")[\"expected\"])\n",
      "note": "**The seven typed totals** replaced by what their own lines add up to."
    },
    {
      "code": "orders[\"total\"] = orders[\"total\"].clip(lower=0)  # lesson 9: a coupon above the basket is charged 0\n",
      "note": "**A negative total becomes 0**: the coupon was bigger than the basket."
    },
    {
      "code": "orders[\"placed\"] = orders[\"order_id\"].map(timed.set_index(\"order_id\")[\"placed\"])\n",
      "note": "Each order's time in São Paulo, joined by its key."
    }
  ]
}
```

Then the derived columns, each a line:

```schooling-example
{
  "language": "python",
  "file": "derive.py",
  "parts": [
    {
      "code": "from lines import lines\nfrom ready import orders\n\n",
      "note": "The order lines and the orders as `ready.py` left them."
    },
    {
      "code": "CORPORATE = \"Ltda|Escritório|Clínica|Colégio|Agência|Studio\"  # lesson 9's December buyers\n\n",
      "note": "The pattern lesson 9 used to recognise a company's name."
    },
    {
      "code": "orders[\"hour\"] = orders[\"placed\"].dt.hour\norders[\"weekday\"] = orders[\"placed\"].dt.day_name()\n",
      "note": "**Hour and weekday**, from the cleaned time."
    },
    {
      "code": "orders[\"items\"] = orders[\"order_id\"].map(lines.groupby(\"order_id\").size())\n",
      "note": "**Items per order**, counted on the lines and mapped by key."
    },
    {
      "code": "orders[\"corporate\"] = orders[\"name\"].str.contains(CORPORATE, na=False)\n",
      "note": "**A flag, not a deletion**: true for the sixteen corporate orders."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from derive import orders; print(orders[['order_id', 'placed', 'hour', 'weekday', 'items', 'total', 'corporate']].head(4).to_string(index=False))"
order_id              placed  hour   weekday  items  total  corporate
  100001 2025-01-01 07:00:30     7 Wednesday      1  66.60      False
  100002 2025-01-01 08:07:08     8 Wednesday      2  46.70      False
  100003 2025-01-01 08:24:01     8 Wednesday      4 108.30      False
  100004 2025-01-01 09:53:12     9 Wednesday      2 132.75      False
ana@lab:~/clean$ python -c "from derive import orders; print(orders['items'].isna().sum(), orders['corporate'].sum()); print(orders.groupby('weekday')['total'].agg(['size', 'median']).round(2).to_string())"
0 16
           size  median
weekday                
Friday     5400   58.15
Monday     3836   56.88
Saturday   5093   57.85
Sunday     2599   55.25
Thursday   3816   58.58
Tuesday    3857   58.45
Wednesday  3925   57.45
```

Every order has at least one line, so `items` has no blanks; that check is worth its one line,
because an order with no lines would be a join problem from lesson 11 surfacing here as a zero.
Sixteen orders are flagged corporate, the December buyers lesson 9 found. **They are flagged, not
removed**: a column says what they are, and each analysis decides whether to include them.

The weekday table shows what a derived column is for. Fridays and Saturdays bring the most
orders, Sundays the fewest, and the median basket barely moves across the week, between R$ 55.25
and R$ 58.58. That is a finding about volume, not about basket size, and it took one derived
column to see it.

Three habits keep derived columns honest:

- **Derive from the cleaned column, never the raw one.** `placed` is lesson 7's time in São Paulo;
  deriving the hour from the raw `ordered_at` would put every site order three hours off.
- **Name the column for what it holds**, with its unit where there is one: `items`, not `n`;
  `days_since`, not `recency`.
- **Write the formula in code, once.** A derived column computed by hand in a spreadsheet cell is
  a value nobody can recompute when the data changes.
