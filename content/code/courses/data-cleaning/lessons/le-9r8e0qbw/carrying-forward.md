---
title: Carrying the last value forward
version: 1
---

**In a series over time, a blank is often filled with the last value before it.** For some
columns that is exactly right and for others it invents data, and the difference is whether the
column describes a **state** or a **flow**.

A state persists until it changes: a price, a stock level, an exchange rate, a customer's address.
If the price was R$ 6.90 on Monday and nothing was recorded on Tuesday, R$ 6.90 is the best
estimate for Tuesday. A flow is a count over a period: sales, deliveries, visitors. Monday's sales
say nothing about Tuesday's.

The Batel shop, in the week of Easter 2025, by day:

```schooling-example
{
  "language": "python",
  "file": "daily.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "sales = pd.read_csv(\"raw/store_sales.csv\", sep=\";\", encoding=\"latin-1\", dtype=str)\nsales[\"day\"] = pd.to_datetime(sales[\"data\"], format=\"%d/%m/%Y\")\n",
      "note": "The till's file read as lesson 2 found it, with its day-first dates parsed by an explicit format."
    },
    {
      "code": "sales[\"reais\"] = pd.to_numeric(sales[\"total\"].str[3:].str.replace(\",\", \".\"))\n",
      "note": "`R$ 94,50` becomes 94.50: drop the `R$ `, turn the comma into a point. Enough for 2025, which has no sale of a thousand reais; lesson 7 writes the conversion that also survives one."
    },
    {
      "code": "batel = sales[sales[\"loja\"] == \"Batel\"].groupby(\"day\")[\"reais\"].sum()\n",
      "note": "One total per day for the Batel shop. A day with no sale has no row at all."
    },
    {
      "code": "days = pd.date_range(\"2025-04-14\", \"2025-04-22\")\nweek = batel.reindex(days)\n",
      "note": "`reindex` over every calendar day of Easter week puts the absent days back, as `NaN`."
    },
    {
      "code": "print(pd.DataFrame({\"as_found\": week, \"ffill\": week.ffill(), \"zero\": week.fillna(0)}))\n",
      "note": "The same week three ways: as found, carried forward, and filled with zero."
    }
  ]
}
```

```
ana@lab:~/clean$ python daily.py
            as_found  ffill   zero
2025-04-14     598.8  598.8  598.8
2025-04-15     790.1  790.1  790.1
2025-04-16     514.5  514.5  514.5
2025-04-17     348.0  348.0  348.0
2025-04-18       NaN  348.0    0.0
2025-04-19     800.9  800.9  800.9
2025-04-20       NaN  800.9    0.0
2025-04-21       NaN  800.9    0.0
2025-04-22     492.5  492.5  492.5
```

Three days have no sales at all. Friday the 18th was Good Friday, Sunday the 20th a Sunday, Monday
the 21st Tiradentes — the shops close on Sundays and national holidays, as lesson 14 confirms from
the calendar. **The days are missing from the file because nothing happened**, not because a record
was lost.

`ffill` fills Good Friday with Thursday's R$ 348.00 and both Sunday and Tiradentes with Saturday's
R$ 800.90: R$ 1,949.80 of sales in a week that never happened, in a shop that was closed. Filled
with zero, the week adds up to what the till took. **For a flow, a day with no record is a day with
no flow**, provided the business confirms it was closed — a till that crashed would also leave an
empty day, and that one is genuinely missing.

The rule is short enough to remember: carry states forward, set flows to zero when nothing
happened, and leave a flow blank when something happened that nobody recorded.
