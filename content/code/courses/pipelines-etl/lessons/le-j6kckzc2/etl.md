---
title: ETL: transform on the way
version: 1
---

The question for this lesson: **how many books, and how much revenue, did each category sell on
each day of the first week of March?** Ana plays the week into the shop first:

```
ana@vm:~/etl$ sudo shop until 2026-03-07
```

The ETL version reads the rows it needs, does the arithmetic in Python, and writes only the answer:

```schooling-example
{
  "language": "python",
  "file": "etl.py",
  "parts": [
    {
      "code": "\"\"\"ETL: books and revenue by day and category, worked out in Python before\nanything reaches the warehouse.\"\"\"\nimport collections\nimport datetime as dt\nimport sys\n\nimport psycopg\n\n"
    },
    {
      "code": "first, last = (dt.date.fromisoformat(a) for a in sys.argv[1:3])\nwith psycopg.connect(\"dbname=shop\") as shop:\n    rows = shop.execute(\n        \"\"\"SELECT o.ordered_at, o.status, b.category, l.quantity, l.unit_price_cents\n             FROM orders o\n             JOIN order_lines l USING (order_id)\n             JOIN books b USING (book_id)\n            WHERE o.ordered_at >= %s AND o.ordered_at < %s\"\"\",\n        (first, last + dt.timedelta(days=1)),\n    ).fetchall()\n\n",
      "note": "**Extract.** Every order line of the period, with its order's status and its book's category, read from the shop in one query. Nothing is decided here yet: cancelled orders come too."
    },
    {
      "code": "totals = collections.defaultdict(lambda: [0, 0])\nfor ordered_at, status, category, quantity, price in rows:\n    if status != \"completed\":\n        continue\n    key = (ordered_at.date(), category)\n    totals[key][0] += quantity\n    totals[key][1] += quantity * price\n\n",
      "note": "**Transform**, in Python, in this program's memory. Cancelled and refunded orders are dropped, and each line is added to its day and category. `ordered_at` arrives in São Paulo time, so `.date()` is the shop's own day."
    },
    {
      "code": "with psycopg.connect(\"dbname=wh\") as wh:\n    wh.execute(\"\"\"CREATE TABLE IF NOT EXISTS etl_sales_by_category (\n                    day date, category text, books integer, revenue_cents bigint)\"\"\")\n    wh.execute(\"DELETE FROM etl_sales_by_category WHERE day BETWEEN %s AND %s\", (first, last))\n    with wh.cursor() as cur:\n        cur.executemany(\"INSERT INTO etl_sales_by_category VALUES (%s, %s, %s, %s)\",\n                        [(d, c, b, r) for (d, c), (b, r) in sorted(totals.items())])\n",
      "note": "**Load** only the answer. The `DELETE` clears the same days first, so running it again for a week replaces the week instead of adding it twice; lesson 15 is about why that matters."
    },
    {
      "code": "print(f\"read {len(rows)} rows from the shop, wrote {len(totals)} to the warehouse\")"
    }
  ]
}
```

```
ana@vm:~/etl$ time python etl.py 2026-03-01 2026-03-07
read 3048 rows from the shop, wrote 98 to the warehouse

real	0m0.211s
user	0m0.170s
sys	0m0.020s
```

Three thousand rows in, ninety-eight out: fourteen categories on seven days. The warehouse sees
nothing but the answer:

```
ana@vm:~/etl$ psql -d wh -c "SELECT * FROM etl_sales_by_category WHERE day = '2026-03-07' ORDER BY revenue_cents DESC LIMIT 5"
    day     |    category     | books | revenue_cents 
------------+-----------------+-------+---------------
 2026-03-07 | Picture books   |   106 |        621790
 2026-03-07 | Cooking         |    57 |        405980
 2026-03-07 | Science fiction |    61 |        363240
 2026-03-07 | Graphic novels  |    47 |        340630
 2026-03-07 | History         |    46 |        327440
(5 rows)
```

## What this shape is good at

**The warehouse stays small and clean.** Nothing arrives in it that a report does not use, and
nothing arrives that has not been checked. For decades that mattered more than anything: warehouse
storage and processors were the most expensive machines in the building, and loading raw rows into
them to be cleaned there would have been a waste of both.

**The transformation can be anything.** It runs in a general-purpose language, so it can call an
API, parse a PDF, resize an image or apply a rule that would be unreadable in SQL.

**And some data never arrives at all.** A transformation that drops a customer's e-mail address or
masks a card number before loading means the warehouse never held it — which is a different and
stronger claim than "we deleted it later". The last section of this lesson comes back to that.

What it costs is in two sections' time, and it is the reason the other shape exists.
