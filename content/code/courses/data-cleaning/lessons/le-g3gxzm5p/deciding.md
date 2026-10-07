---
title: Deciding, and what the decisions did
version: 1
---

**Each kind of outlier in this lesson got a different decision, and each decision is written into the
data as a flag.** Gathered in one script:

```schooling-example
{
  "language": "python",
  "file": "decide.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom orders import orders\nfrom typos import wrong\n\n"
    },
    {
      "code": "decided = orders.copy()\ndecided[\"flag\"] = \"none\"\n",
      "note": "A flag column, so every decision is visible in the data."
    },
    {
      "code": "fix = decided[\"order_id\"].isin(wrong[\"order_id\"])\ndecided.loc[fix, \"total\"] = decided.loc[fix, \"order_id\"].map(\n    wrong.set_index(\"order_id\")[\"expected\"])\ndecided.loc[fix, \"flag\"] = \"total recomputed from lines\"\n",
      "note": "**Typed totals** take the value of their own lines."
    },
    {
      "code": "negative = decided[\"total\"] < 0\ndecided.loc[negative, \"total\"] = 0.0\ndecided.loc[negative, \"flag\"] = \"coupon above basket: charged 0\"\n",
      "note": "**Negative totals** become what was charged, zero."
    },
    {
      "code": "corporate = decided[\"name\"].str.contains(\"Ltda|Escritório|Clínica|Colégio|Agência|Studio\", na=False)\ndecided.loc[corporate, \"flag\"] = \"corporate order\"\n",
      "note": "**Corporate orders** keep their totals and get a label. The names are the six companies the previous sections found."
    },
    {
      "code": "delivered = decided[\"status\"] == \"delivered\"\nfor label, frame in [(\"as exported\", orders[orders[\"status\"] == \"delivered\"]),\n                     (\"decided\", decided[delivered]),\n                     (\"decided, households only\", decided[delivered & ~corporate])]:\n    print(f\"{label:25} revenue {frame['total'].sum():12,.2f}  mean {frame['total'].mean():6.2f}  \"\n          f\"median {frame['total'].median():6.2f}\")\nprint(decided[\"flag\"].value_counts().to_string())\n",
      "note": "Revenue, mean and median of delivered orders, as exported and as decided, and the count of each flag."
    }
  ]
}
```

```
ana@lab:~/clean$ python decide.py
as exported               revenue 2,501,334.35  mean  94.35  median  57.60
decided                   revenue 2,493,548.15  mean  94.06  median  57.60
decided, households only  revenue 2,380,737.65  mean  89.86  median  57.50
flag
none                              28366
coupon above basket: charged 0      137
corporate order                      16
total recomputed from lines           7
```

The flags, from the bottom: 7 totals recomputed from their lines, 16 corporate orders kept and
labelled, 137 negative totals set to zero, and 28,366 orders untouched. The refund account and the
sugar price are not in the script, because neither is a cleaning decision: both went to the people
who own them, and the report says so.

The effect on the numbers a manager reads:

- **revenue** from delivered orders falls from R$ 2,501,334.35 to R$ 2,493,548.15, the seven typed
  totals coming back to what their lines say;
- **the mean order** falls only from 94.35 to 94.06, and to 89.86 for households alone;
- **the median** does not move at all, R$ 57.60, and barely for households, R$ 57.50.

That last line repeats `statistics` lesson 4 in a real case: the median ignores what happens at the
ends, which makes it the right summary of a typical order and the wrong place to look for errors.

| what was found | decision | flag |
|---|---|---|
| total ten times its lines | replace with the lines' total | `total recomputed from lines` |
| corporate December orders | keep, label | `corporate order` |
| coupon above basket | set to zero, as charged | `coupon above basket: charged 0` |
| 23 refunds from one new account | report to the fraud team | none: not a cleaning decision |
| sugar charged at R$ 134.90 | report to buyers and finance | none: not a cleaning decision |

**The table is the deliverable.** A cleaned file without it asks the next reader to trust seven
changed totals; with it, every change can be checked, and the two findings that were not cleaning
are on somebody's desk instead of in a footnote nobody writes.
