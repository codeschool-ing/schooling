---
title: The two decisions, priced
version: 1
---

**Partitioning and clustering multiply, and the bill is the product.** Partitioning decides which days
a query reads, clustering decides which blocks of those days, and on demand bills the columns named in
whatever is left. The program below puts the three layouts of this lesson side by side for the
question Quitanda's store dashboard asks every hour, the sales of one store yesterday, and prices each
with lesson 14's rules. Save it as `~/gcp/layout_bill.py`:

```schooling-example
{"language": "python", "file": "layout_bill.py", "parts": [{"code": "import math\nimport sys\n\nimport duckdb\n\nSCALE = int(sys.argv[1])\nPRICE_PER_TIB, MB, TIB = 11.25, 2**20, 2**40  # on demand, southamerica-east1, read 2026-10-30\nDAY, STORE = '2026-09-29', 7\n\n", "note": "**The question is the dashboard's**: the sales of one store on one day. `SCALE` multiplies every byte, so the same program can price Quitanda as it is and a company a thousand times larger."}, {"code": "con = duckdb.connect()\nrows = con.sql(\"SELECT count(*) FROM read_parquet('warehouse/orders/*/*.parquet')\").fetchone()[0]\nday = con.sql(f\"SELECT count(*) FROM read_parquet('warehouse/orders/dt={DAY}/*.parquet')\").fetchone()[0]\n", "note": "**Two measurements of rows**: the whole table, which an unpartitioned table would read, and the one day a partition filter leaves."}, {"code": "groups, hit = con.sql(f\"\"\"\n    SELECT count(*), count(*) FILTER (WHERE stats_min_value::INT <= {STORE}\n                                        AND stats_max_value::INT >= {STORE})\n    FROM parquet_metadata('warehouse/orders_by_store/dt={DAY}/*.parquet')\n    WHERE path_in_schema = 'store_id'\"\"\").fetchone()\n\n", "note": "**The clustering measurement** of the last section: of the day's row groups, sorted by store, how many might hold the store asked for. Their share stands in for BigQuery's blocks."}, {"code": "read = 3 * 8  # dt, store_id and total_cents: three 8-byte columns a row\nlayouts = {\n    'no partitions': rows * read,\n    'partitioned by dt': day * read,\n    'partitioned by dt, clustered by store_id': day * read * hit / groups,\n}\n", "note": "**The logical bytes each layout reads.** The query references three columns, all `INT64` or `DATE`, so 24 bytes a row, over the rows each layout cannot avoid."}, {"code": "print(f'sum(total_cents) for store {STORE} on {DAY}, at {SCALE:,} times the data')\nfor name, logical in layouts.items():\n    billed = math.ceil(max(logical * SCALE, 10 * MB) / MB) * MB\n    usd = billed / TIB * PRICE_PER_TIB\n    print(f'  {name:<42}{billed:>16,} bytes {usd:9.4f} USD   hourly for a month {usd * 720:8.2f} USD')\n", "note": "**Lesson 14's rules, applied**: the 10 MB minimum, the rounding to the MB, the price per TiB, and a month of the dashboard refreshing every hour, 720 times."}]}
```

```
ana@laptop:~/gcp$ python3 layout_bill.py 1
sum(total_cents) for store 7 on 2026-09-29, at 1 times the data
  no partitions                                   30,408,704 bytes    0.0003 USD   hourly for a month     0.22 USD
  partitioned by dt                               10,485,760 bytes    0.0001 USD   hourly for a month     0.08 USD
  partitioned by dt, clustered by store_id        10,485,760 bytes    0.0001 USD   hourly for a month     0.08 USD
ana@laptop:~/gcp$ python3 layout_bill.py 1000
sum(total_cents) for store 7 on 2026-09-29, at 1,000 times the data
  no partitions                               29,883,367,424 bytes    0.3058 USD   hourly for a month   220.15 USD
  partitioned by dt                              393,216,000 bytes    0.0040 USD   hourly for a month     2.90 USD
  partitioned by dt, clustered by store_id        88,080,384 bytes    0.0009 USD   hourly for a month     0.65 USD
```

**At Quitanda's own size, partitioning saves 20 MB a query and clustering saves nothing.** The table
without partitions is billed 30,408,704 bytes, its three columns over every row. Partitioned, one day
of three columns is 392,616 bytes, far under the 10 MB minimum, so it is billed 10,485,760; clustering
cuts the bytes it reads further and the minimum swallows that too. Twenty-two cents a month against
eight is not a reason to do anything.

**At a thousand times the size, the layouts are three different bills.** Without partitions, every
hourly refresh reads the whole table, 0.3058 USD, and the month comes to 220.15 USD. Partitioned by day,
it reads one day of sixty, 2.90 USD a month. Clustered by store as well, it reads two ninths of that
day, 0.65 USD a month: **about a three-hundred-and-fortieth of the first**, for a table holding the same
rows and answering with the same numbers.

**These are computed numbers, and two of their inputs are DuckDB's.** The row counts are measured. The
clustering share is the share of Parquet row groups in the last section, standing in for BigQuery's
blocks, whose real share BigQuery reports only after a query has run. The multiplication by a thousand
treats a larger company as more of the same orders, which is fair for the bytes of a column and says
nothing about how its stores and days are distributed. It is the size of a bill, not an invoice.

## The table, sixty days against three years

**The unpartitioned line grows with the history and the partitioned lines do not.** Sixty days of data
is what this lab holds; Quitanda keeps three years. Without partitions, the hourly dashboard reads three
years of rows to answer about yesterday, eighteen times the sixty days, so its 220.15 USD a month
becomes about eighteen times as much as the history fills up, while the partitioned dashboard keeps
reading one day. **Partitioning turns a cost that grows with time into one that stays flat**, and that
is the main reason it is worth deciding on the first day rather than the hundredth.

## What changing your mind costs

**Both decisions are made when the table is created, and changing either means writing the table
again.** BigQuery cannot repartition a table in place. The way to move to a new layout is a query that
reads the whole old table and writes a new one, `CREATE TABLE ... PARTITION BY ... CLUSTER BY ... AS
SELECT * FROM` the old one, and on demand that query is billed for every byte of every column it reads,
once. On Quitanda's table today that is a 10 MB minimum; on three years of a click stream it is the
largest single query the warehouse will ever run. Clustering is the gentler of the two: it can be changed on an
existing table, with `bq update --clustering_fields`, without one query rewriting it all.

## Quitanda's orders, decided

**Partitioned by `dt`, by day**, because nearly every question names a day, a week or a month, and a
day of orders is a partition worth having.

**Clustered by `store_id`**, the second filter of the dashboards, with room for a second clustering
column, such as `payment`, if the questions turn out to ask it.

**`require_partition_filter` on**, so the query that forgot its date fails for free instead of reading
three years.

**`partition_expiration_days` at 1,095**, three years, if that is the history the business needs, so
that old days leave the table, and its bill, on their own.

And every query that reads it **names the columns it needs**, which no layout can do for it.
