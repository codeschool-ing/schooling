---
title: Questions first
version: 1
---

**Exploratory data analysis** is the first look at data you now trust: summaries, counts and
charts, chosen to find out what the data says before anyone decides what it should say. It is not
a separate activity from cleaning. Every lesson so far explored a little to find the next defect;
the difference now is that the defects are dealt with, so what turns up is about the business, not
about the files.

Exploration goes better with questions written down first, even simple ones, because a question
decides what to compute and keeps a long afternoon from turning into a tour of every column:

- **What is typical, and how much does it vary?** One column at a time.
- **When does it happen, and how does it change?** The same columns over time.
- **What moves together?** Two columns at a time.
- **Where is the money?** The total, broken down.

The answers start from one small file that every command in this lesson imports. It applies the
decisions of the earlier lessons once, so no chart is drawn from a column that a previous lesson
already corrected:

```schooling-example
{
  "language": "python",
  "file": "explore.py",
  "parts": [
    {
      "code": "from categorise import products  # lesson 8: one category and department per product\nfrom derive import orders  # lesson 12: decided totals, hour, weekday, items, corporate\nfrom lines import lines\n\n",
      "note": "Three earlier lessons, imported rather than repeated: categories, decided orders and converted lines."
    },
    {
      "code": "delivered = orders[orders[\"status\"] == \"delivered\"].copy()\n",
      "note": "**Delivered orders only**: a cancelled or refunded order is not a sale."
    },
    {
      "code": "delivered[\"month\"] = delivered[\"placed\"].dt.to_period(\"M\")\n",
      "note": "Each order's month, for everything over time."
    },
    {
      "code": "catalogue = products.drop_duplicates(\"product_code\").rename(columns={\"product_code\": \"code\"})\n",
      "note": "One row per product code, as lesson 11 required before joining."
    },
    {
      "code": "sold = lines[lines[\"order_id\"].isin(delivered[\"order_id\"])].merge(\n    catalogue[[\"code\", \"category\", \"department\"]], on=\"code\", how=\"left\", validate=\"many_to_one\")\n",
      "note": "**The lines of delivered orders**, each with its category, joined many to one."
    }
  ]
}
```

Two choices in it shape every number that follows, and both are stated here so nobody has to
guess. **Only delivered orders count**, 26,510 of them, because a cancelled or refunded order is
not a sale. **The sixteen corporate orders stay in, flagged**, so each section can show them or
set them aside on purpose.
