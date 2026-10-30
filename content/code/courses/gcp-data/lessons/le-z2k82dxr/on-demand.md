---
title: On demand, priced by the byte
version: 1
---

**On demand is BigQuery's default, and it bills a query by the bytes it reads, never by the time it
takes.** A project that has bought nothing is on it. A query that reads 1 TiB costs 11.25 USD in
`southamerica-east1`, whether it finishes in two seconds or in two minutes, and whether it returns
one row or a million. The price is from `cloud.google.com/bigquery/pricing`, read on 2026-10-30, like
every price in this lesson, and the first TiB of every month is free.

That sounds like the simplest bill in the cloud, and it hides five rules, all of them on the pricing
page. Each one changes a number you would otherwise get wrong.

## The five rules

**The bytes are the logical bytes of the columns the query references**, counted by type as lesson
13 counted them. A column named anywhere in the query counts: in the `SELECT`, the `WHERE`, the
`GROUP BY` or a `JOIN`. A column the query never names costs nothing.

**`LIMIT` does not reduce the bill.** The page says it outright: "When you run a query, you're
charged according to the data processed in the columns you select, even if you set an explicit LIMIT
on the results." `SELECT * FROM orders LIMIT 10` reads every column of every row to find ten of them,
and is billed for all of it.

**Every query is rounded up to the next MB, and is billed for at least 10 MB.** The minimum applies
to each table the query references, and to the query as a whole. BigQuery counts a MB as 2^20 bytes,
so the smallest query it bills is 10,485,760 bytes.

**A query that fails costs nothing, and so does one answered from the cache.** BigQuery keeps the
result of a query for a while and, if the same query arrives again and the tables have not changed,
it returns the stored result and bills no bytes.

**Cancelling is not a refund.** In the page's words, "Canceling a running query job might incur
charges up to the full cost for the query if you let the query run to completion." A query that has
already read the table has been billed for reading it.

## The rules, as a program

Save this as `~/gcp/ondemand.py`. It takes the bytes a query reads from each table it references,
one number per table, and applies the minimum, the rounding and the price:

`ondemand.py`:

```python
import math
import sys

PRICE_PER_TIB = 11.25  # USD, on demand, southamerica-east1, cloud.google.com/bigquery/pricing, read 2026-10-30
MB, TIB = 2**20, 2**40
MINIMUM = 10 * MB


def billed(bytes_per_table):
    per_table = [max(b, MINIMUM) for b in bytes_per_table]
    return math.ceil(max(sum(per_table), MINIMUM) / MB) * MB


tables = [int(b) for b in sys.argv[1:]]
b = billed(tables)
print(f'read {sum(tables):>15,} bytes   billed {b:>15,} bytes   {b / TIB * PRICE_PER_TIB:.6f} USD')
```

**The bytes to feed it come from lesson 13's rule**: a column of `INT64` is 8 bytes a row. DuckDB
counts the rows, over the whole table and over its last day:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT 8 * count(*) AS total_cents_bytes, 8 * count(*) FILTER (WHERE dt = DATE '2026-09-29') AS one_day FROM orders"
┌───────────────────┬─────────┐
│ total_cents_bytes │ one_day │
│       int64       │  int64  │
├───────────────────┼─────────┤
│           9960944 │  130872 │
└───────────────────┴─────────┘
```

Five queries, priced. `total_cents` over the whole table; the same column for one day; `SELECT *`,
which lesson 13 measured at 99,177,572 bytes; a join that reads `store_id` and `total_cents` from
`orders` and a few hundred bytes from a table of sixteen stores; and a `SELECT *` over a table of 2 TiB:

```
ana@laptop:~/gcp$ python3 ondemand.py 9960944
read       9,960,944 bytes   billed      10,485,760 bytes   0.000107 USD
ana@laptop:~/gcp$ python3 ondemand.py 130872
read         130,872 bytes   billed      10,485,760 bytes   0.000107 USD
ana@laptop:~/gcp$ python3 ondemand.py 99177572
read      99,177,572 bytes   billed      99,614,720 bytes   0.001019 USD
ana@laptop:~/gcp$ python3 ondemand.py 19921888 400
read      19,922,288 bytes   billed      30,408,704 bytes   0.000311 USD
ana@laptop:~/gcp$ python3 ondemand.py 2199023255552
read 2,199,023,255,552 bytes   billed 2,199,023,255,552 bytes   22.500000 USD
```

**Quitanda's orders are too small to cost anything worth counting**, and the first two lines show
the minimum doing all the work. The whole table's `total_cents` is 9,960,944 bytes and is billed as
10,485,760; one day of it is 130,872 bytes and is billed as the same 10,485,760, eighty times what it
read. **Reading less than 10 MB saves nothing.** That matters in lesson 15, because a partition filter
that turns a 9 MB scan into a 0.1 MB one changes nothing on the bill of a table this small.

**The join is billed for 20 MB of minimums and a little more**, 30,408,704 bytes, because each table
it references is billed for at least 10 MB on its own. A query that joins five small tables pays for
fifty. **And `SELECT *` over 2 TiB costs 22.50 USD every time it runs.** Nothing about it is unusual:
two TiB is the size a click stream reaches in a few months, and a query written without thought for
its columns is the commonest query there is.

## A month of it

**The bill that hurts is never one query, it is a query that repeats.** The 2 TiB query run every hour
by a dashboard, for a 30-day month, with and without the free TiB:

```
ana@laptop:~/gcp$ python3 -c 'print(24 * 30 * 22.5, (24 * 30 * 2**41 / 2**40 - 1) * 11.25)'
16200.0 16188.75
```

**16,200 USD before the free TiB and 16,188.75 after it.** The free tier is worth 11.25 USD a month,
which is real money to a student and nothing to a dashboard. The same dashboard reading the two
columns it draws, from the last day's partition only, would be billed a few MB an hour, which is
lessons 15 and 16.

**On demand also has a ceiling on speed, and the ceiling is shared.** The page says a project on demand
has "access to up to 2,000 concurrent slots, shared among all queries in a single project", which it
may briefly exceed, and which may be fewer when the region is busy. A project that runs a hundred heavy
queries at once divides those slots among them. That is not a cost, and it is the first reason a
company moves off on demand: not to pay less, but to know how much compute it will have.
