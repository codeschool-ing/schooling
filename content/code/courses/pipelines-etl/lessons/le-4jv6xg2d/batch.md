---
title: Batch: a day at a time
version: 1
---

**Batch ingestion moves data in bounded pieces, on a schedule.** A piece is usually a period —
yesterday, the last hour — and everything that happened in it is read, processed and written
together, after the period has closed. It is the oldest kind of pipeline and still most of them,
because most questions people ask a warehouse are about periods that are over.

Ana's first batch reads one day of sales per shop from the shop and writes it into the warehouse:

```schooling-example
{
  "language": "python",
  "file": "batch.py",
  "parts": [
    {
      "code": "\"\"\"One day of sales per shop, from the shop's database into the warehouse.\"\"\"\nimport datetime as dt\nimport sys\n\nimport psycopg\n\n",
      "note": "Python and one library, `psycopg`, which speaks PostgreSQL's protocol."
    },
    {
      "code": "day = dt.date.fromisoformat(sys.argv[1])\n",
      "note": "The day comes from the command line. **The script does not decide which day it is**, and that one choice is what lets the same script load any day you name."
    },
    {
      "code": "with psycopg.connect(\"dbname=shop\") as shop, psycopg.connect(\"dbname=wh\") as wh:\n    rows = shop.execute(\n        \"\"\"SELECT o.shop_id, count(*), sum(p.amount_cents)\n             FROM orders o JOIN payments p USING (order_id)\n            WHERE o.ordered_at >= %s AND o.ordered_at < %s\n              AND o.status = 'completed'\n            GROUP BY o.shop_id\n            ORDER BY o.shop_id\"\"\",\n        (day, day + dt.timedelta(days=1)),\n    ).fetchall()\n",
      "note": "Two connections, one to each database. The query asks the shop for one day, from midnight to the next midnight, and only orders that were not cancelled or refunded."
    },
    {
      "code": "    wh.execute(\"\"\"CREATE TABLE IF NOT EXISTS daily_sales (\n                    day date, shop_id integer, orders integer, revenue_cents bigint)\"\"\")\n",
      "note": "The destination table is made if it is not there. A real pipeline would not create tables as it goes; lesson 18 says where that belongs."
    },
    {
      "code": "    with wh.cursor() as cur:\n        cur.executemany(\"INSERT INTO daily_sales VALUES (%s, %s, %s, %s)\",\n                        [(day, *r) for r in rows])\n",
      "note": "Seven rows go in, one per shop, in one transaction: the `with` block commits when it ends and rolls back if anything inside it raised."
    },
    {
      "code": "print(f\"{day}: {len(rows)} shops, {sum(r[1] for r in rows)} orders\")"
    }
  ]
}
```

She runs it for the day the lab has just played:

```
ana@vm:~/etl$ time python batch.py 2026-03-01
2026-03-01: 7 shops, 183 orders

real	0m0.221s
user	0m0.172s
sys	0m0.032s
ana@vm:~/etl$ psql -d wh -c "SELECT * FROM daily_sales ORDER BY shop_id"
    day     | shop_id | orders | revenue_cents 
------------+---------+--------+---------------
 2026-03-01 |       1 |     47 |        525660
 2026-03-01 |       2 |     21 |        198750
 2026-03-01 |       3 |     17 |        165140
 2026-03-01 |       4 |     19 |        234280
 2026-03-01 |       5 |     16 |        183730
 2026-03-01 |       6 |     12 |        151640
 2026-03-01 |       7 |     51 |        520010
(7 rows)
```

## What a batch costs, and in what currency

The run took a fifth of a second. That is not the number that matters. **What matters is how old
the answer is when somebody reads it**, and for a nightly batch that is the time since the period
closed plus the time until the next run starts plus however long the run takes. A report opened at
four in the afternoon on 2 March, fed by a run at 2 a.m., shows a day that ended sixteen hours
earlier. For a sales report that is fine. For "is this book out of stock right now" it is useless.

Batch buys three things with that delay:

- **Completeness.** The day is over, so every order of the day is there, including the ones the
  website wrote at 23:59.
- **Simplicity.** One run, one period, one transaction. If it fails, you run it again for the same
  day, and the next section's alternative has no equivalent that simple.
- **Efficiency.** Reading 183 orders at once costs barely more than reading one, and a
  warehouse is built to take rows in large gulps — lesson 19 measures how large.

**Run it twice and look at the table:**

```
ana@vm:~/etl$ python batch.py 2026-03-01
2026-03-01: 7 shops, 183 orders
ana@vm:~/etl$ psql -d wh -c "SELECT count(*), sum(orders) FROM daily_sales"
 count | sum 
-------+-----
    14 | 366
(1 row)
```

It now holds the day twice, fourteen rows and 366 orders where there were 183. This script has none of the four properties of the last section yet; lesson 15 makes it
safe to rerun, and the lessons between them supply the rest.
