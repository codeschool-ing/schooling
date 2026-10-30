---
title: The idea of an incremental aggregate, on DuckDB
version: 1
---

**This section is the idea of incremental refresh, done by hand, and not BigQuery's implementation of
it.** A materialised view keeps a stored aggregate current by aggregating only what is new and adding
it to what is there. DuckDB has no materialised views of the BigQuery kind, so a short program does the
bookkeeping itself: one folder of the aggregate per day of orders, and a run that fills in only the days
the aggregate does not have yet. What it shows is why incremental is cheap, measured in rows read. What
it does not show is anything about how BigQuery schedules, stores or rewrites, which the last section
took from the documentation.

## The program

Save it as `~/gcp/incremental.py`:

```schooling-example
{"language": "python", "file": "incremental.py", "parts": [{"code": "import pathlib\n\nimport duckdb\n\nORDERS, SALES = pathlib.Path('warehouse/orders'), pathlib.Path('warehouse/daily_sales')\n\ncon = duckdb.connect()\ncon.sql(f\"CREATE VIEW orders AS SELECT * FROM read_parquet(\"\n        f\"'{ORDERS}/**/*.parquet', hive_partitioning = true)\")\n\n", "note": "**Two tables in the warehouse folder**: the orders, as lesson 13 wrote them, and `daily_sales`, the aggregate this program maintains, one folder per day like the orders. Because it sits under `warehouse/`, `ask.py` can query it by name."}, {"code": "done = {p.name for p in SALES.glob('dt=*')}\nnew = sorted(p.name for p in ORDERS.glob('dt=*') if p.name not in done)\n\n", "note": "**What is new is what the aggregate does not have yet**: a day folder in `orders` with no folder of the same name in `daily_sales`. This is the bookkeeping BigQuery does for a materialised view, done by comparing names."}, {"code": "read = 0\nfor folder in new:\n    day = folder.removeprefix('dt=')\n    (SALES / folder).mkdir(parents=True, exist_ok=True)\n    con.sql(f\"\"\"COPY (SELECT district, count(*) AS orders, sum(total_cents)::BIGINT AS sales\n                      FROM orders WHERE dt = DATE '{day}'\n                      GROUP BY district ORDER BY district)\n                TO '{SALES / folder}/part-000.parquet' (FORMAT parquet)\"\"\")\n    read += con.sql(f\"SELECT count(*) FROM orders WHERE dt = DATE '{day}'\").fetchone()[0]\n\n", "note": "**Each new day is aggregated from that day's orders only**, and written as that day's partition of the aggregate. Orders per district, and their sum, cast back to `BIGINT` so the money stays integer cents. The rows read are counted, because how many the refresh reads is the whole point."}, {"code": "print(f'new days aggregated: {len(new)}, order rows read: {read:,}, days in daily_sales: {len(done) + len(new)}')\n", "note": "**One line of accounts**, so each run says what it did."}]}
```

## A day arrives

**To watch one day arrive, the last one is moved aside first**, as though the nightly load of 29
September had not happened yet. Then the aggregate is built, run again with nothing new, and run once
more after the day comes back:

```
ana@laptop:~/gcp$ mv warehouse/orders/dt=2026-09-29 day-60
ana@laptop:~/gcp$ python3 incremental.py
new days aggregated: 59, order rows read: 1,228,759, days in daily_sales: 59
ana@laptop:~/gcp$ python3 incremental.py
new days aggregated: 0, order rows read: 0, days in daily_sales: 59
ana@laptop:~/gcp$ mv day-60 warehouse/orders/dt=2026-09-29
ana@laptop:~/gcp$ python3 incremental.py
new days aggregated: 1, order rows read: 16,359, days in daily_sales: 60
```

**The first run read 1,228,759 orders to build 59 days**: everything there was, which is what creating
a materialised view costs. **The second run read nothing**, because nothing was new; a refresh with no
change to the base table is free. **The third read 16,359 orders, one day's worth**, and left 59 days
of the aggregate untouched. That ratio, one day's rows against all of them, is what incremental
maintenance saves on every refresh, and it grows with the history: against three years of orders, a
night's refresh reads about a thousandth of the table.

## Is it right?

**An incremental aggregate is only worth having if it matches a full recomputation**, so ask DuckDB
for the difference between the two, the aggregate computed from scratch out of every order, minus the
one the program kept:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT count(*) AS differences FROM (SELECT dt, district, count(*) AS orders, sum(total_cents) AS sales FROM orders GROUP BY ALL EXCEPT SELECT dt, district, orders, sales FROM daily_sales)"
┌─────────────┐
│ differences │
│    int64    │
├─────────────┤
│           0 │
└─────────────┘

ana@laptop:~/gcp$ python3 ask.py "SELECT district, orders, sales FROM daily_sales WHERE dt = DATE '2026-09-29' ORDER BY district"
┌──────────────┬────────┬──────────┐
│   district   │ orders │  sales   │
│   varchar    │ int64  │  int64   │
├──────────────┼────────┼──────────┤
│ Butantã      │   2132 │ 51441722 │
│ Lapa         │   2018 │ 47482131 │
│ Moema        │   1967 │ 47805392 │
│ Mooca        │   2111 │ 50703844 │
│ Pinheiros    │   2040 │ 48877437 │
│ Santana      │   1975 │ 48953221 │
│ Tatuapé      │   2071 │ 49693044 │
│ Vila Mariana │   2045 │ 48705315 │
└──────────────┴────────┴──────────┘
```

**No differences**, and the last day's eight rows are there, with their orders and their sales in
integer cents. `EXCEPT` returns the rows of the first query that are not in the second, so zero means
every day and district the full computation produced is in the incremental one, with the same numbers.

## A correction

**A change to a day already aggregated is not something the program notices**, because it only looks
for days it has never seen. The fix is to throw that day of the aggregate away and run again, which is
what BigQuery does for a materialised view when a base partition changes:

```
ana@laptop:~/gcp$ rm -r 'warehouse/daily_sales/dt=2026-09-15' && python3 incremental.py
new days aggregated: 1, order rows read: 16,279, days in daily_sales: 60
```

**One day recomputed, from 16,279 orders.** The program's rule is crude, a whole day for any change,
and BigQuery's is the same in shape: the unit of recomputation is the partition. It is also the reason a
view's partitioning should follow its base table's: a correction to one day then costs one day, where a
view partitioned differently, or not at all, would have to be recomputed from everything.
