---
title: Quitanda's orders, made on your laptop
version: 1
---

**The data these six lessons query is two months of Quitanda's orders, and you make it yourself.**
A real warehouse would be loaded from the nightly exports of lesson 1, and the lab has no real
exports to load. So a short program writes them: every order a row, with the store, the district,
the number of items, the total, the way it was paid and the moment it was placed. It is seeded, so
the orders on your disk are the ones in these transcripts, and every number this lesson prints you
can print too.

## The generator

Save it as `~/gcp/make_orders.py`:

```schooling-example
{"language": "python", "file": "make_orders.py", "parts": [{"code": "import datetime as dt\nimport pathlib\nimport random\n\nimport pyarrow as pa\nimport pyarrow.parquet as pq\n\nrng = random.Random(13)\nFIRST_DAY, DAYS = dt.date(2026, 8, 1), 60\nDISTRICTS = ['Pinheiros', 'Moema', 'Vila Mariana', 'Tatuapé',\n             'Santana', 'Butantã', 'Lapa', 'Mooca']\nSTORE_DISTRICT = {store: DISTRICTS[(store - 1) // 2] for store in range(1, 17)}\nWEEKDAY = [0.9, 0.85, 0.9, 0.95, 1.1, 1.3, 1.2]\nSAO_PAULO = dt.timezone(dt.timedelta(hours=-3))\n\n\n", "note": "**The generator is seeded**, so every run writes the same orders, and your numbers will match the ones in this lesson. Sixty days from 1 August 2026, sixteen stores, two in each of eight districts. `WEEKDAY` makes a Saturday 30% busier than an average day and a Tuesday 15% quieter, because Monday is 0 in Python."}, {"code": "SCHEMA = pa.schema([\n    ('order_id', pa.string()),\n    ('customer_id', pa.string()),\n    ('store_id', pa.int64()),\n    ('district', pa.string()),\n    ('items', pa.int64()),\n    ('total_cents', pa.int64()),\n    ('payment', pa.string()),\n    ('created_at', pa.timestamp('us', tz='UTC')),\n])\n\n\n", "note": "**The columns, with their types written down** rather than guessed from the values. Each Parquet type here has one BigQuery type it loads as: `string` becomes `STRING`, `int64` becomes `INT64`, and a timestamp in microseconds with a time zone becomes `TIMESTAMP`. Money is integer cents, never a float. There is no `dt` column: the date is in the folder's name."}, {"code": "def one_day(day):\n    opens = dt.datetime.combine(day, dt.time(7), SAO_PAULO)\n    count = int(20_000 * WEEKDAY[day.weekday()] * rng.uniform(0.95, 1.05))\n    seconds = sorted(rng.randrange(16 * 3600) for _ in range(count))\n    rows = {name: [] for name in SCHEMA.names}\n    for n, second in enumerate(seconds, start=1):\n        store = rng.randint(1, 16)\n        items = rng.randint(1, 30)\n        rows['order_id'].append(f'o-{day:%y%m%d}-{n:05d}')\n        rows['customer_id'].append(f'c-{rng.randint(1, 40_000):05d}')\n        rows['store_id'].append(store)\n        rows['district'].append(STORE_DISTRICT[store])\n        rows['items'].append(items)\n        rows['total_cents'].append(items * rng.randint(600, 2_500))\n        rows['payment'].append(rng.choices(['pix', 'card', 'cash'], [12, 7, 1])[0])\n        rows['created_at'].append(opens + dt.timedelta(seconds=second))\n    return pa.table(rows, schema=SCHEMA)\n\n\n", "note": "**One day of orders.** About twenty thousand, between seven in the morning and eleven at night, São Paulo time, in the order they were placed. Customers come from a pool of forty thousand, so most of them order more than once in two months. Pix is twelve orders in twenty, a card seven and cash one."}, {"code": "total = 0\nfor i in range(DAYS):\n    day = FIRST_DAY + dt.timedelta(days=i)\n    folder = pathlib.Path('warehouse/orders') / f'dt={day}'\n    folder.mkdir(parents=True, exist_ok=True)\n    table = one_day(day)\n    pq.write_table(table, folder / 'part-000.parquet')\n    total += table.num_rows\nprint(f'{DAYS} days, {total:,} orders, from {FIRST_DAY} to {day}')\n", "note": "**One Parquet file per day**, in a folder named `dt=2026-08-01` and so on. That naming is the convention called Hive partitioning: the column's name, an equals sign and its value. DuckDB reads the date back out of the path, and so does BigQuery when it loads these files or reads them in place (lesson 17)."}]}
```

**Twenty thousand orders a day is a grocery business of a believable size**, and over sixty days it
makes a table of a little over a million rows. That is small for BigQuery and large enough that a
query which reads the wrong columns, or the wrong days, shows it in the numbers. Run it:

```
ana@laptop:~/gcp$ time python3 make_orders.py
60 days, 1,245,118 orders, from 2026-08-01 to 2026-09-29

real	0m9.559s
user	0m8.931s
sys	0m0.471s
ana@laptop:~/gcp$ ls warehouse/orders | head -3; ls warehouse/orders | wc -l
dt=2026-08-01
dt=2026-08-02
dt=2026-08-03
60
ana@laptop:~/gcp$ du -sh warehouse/orders
32M	warehouse/orders
```

**1,245,118 orders in sixty folders, 32 MB on disk**, written in nine seconds on the machine these
lessons were recorded on. The count is the same on yours, because the seed fixes every choice the
program makes; the time is whatever your processor takes.

## The same files, in the bucket

**A warehouse loads its tables from Cloud Storage**, and Quitanda's curated orders belong in
`quitanda-curated-prod`, the bucket that lesson 1's naming scheme set aside for data that has been
cleaned. With fake-gcs-server running in its own terminal, as in lesson 1, create it and copy the
folder up:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ gcloud storage cp --recursive warehouse/orders gs://quitanda-curated-prod/ 2>&1 | tail -1
Average throughput: 54.3MiB/s
ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-curated-prod/orders/ | head -3
gs://quitanda-curated-prod/orders/dt=2026-08-01/
gs://quitanda-curated-prod/orders/dt=2026-08-02/
gs://quitanda-curated-prod/orders/dt=2026-08-03/
ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-curated-prod/orders/** | wc -l
60
ana@laptop:~/gcp$ gcloud storage du --summarize gs://quitanda-curated-prod/orders/
32451790     gs://quitanda-curated-prod/orders/
```

**Sixty objects, 32,451,790 bytes**, each under a key such as `orders/dt=2026-08-01/part-000.parquet`.
The folders the listing shows are not objects: Cloud Storage has only keys, and `gcloud` draws a
folder wherever a key has a `/` in it, as lesson 1 showed. The emulator keeps them in memory, so if
you stop it, the copy is gone and the files on your disk are not; the `cp` line puts them back.
Lesson 17 reads these objects back out of the bucket.

## Loading them into BigQuery, which was not run

On Google Cloud, the next two steps would make a dataset in São Paulo and load the files into a
table. Both commands are shown as you would type them, and neither was run here:

```sh
bq mk --dataset --location=southamerica-east1 planner-dev:quitanda
bq load --source_format=PARQUET \
  --hive_partitioning_mode=AUTO \
  --hive_partitioning_source_uri_prefix=gs://quitanda-curated-prod/orders/ \
  quitanda.orders 'gs://quitanda-curated-prod/orders/*'
```

**`--hive_partitioning_mode=AUTO` is what turns `dt=2026-08-01` into a column**, so the loaded table
has nine columns, the eight in the files and `dt`. **A batch load costs nothing**: the pricing page
lists it among the free operations, done on a shared pool of slots, and once the data is in BigQuery
you pay to store it. The load also leaves the files in the bucket: nothing deletes them for you,
so the same orders are then billed twice, once as objects in
Cloud Storage and once as a table in BigQuery. Lesson 17 is the other choice, a table that reads the
files where they are.

## Asking DuckDB

**`ask.py` gives every folder under `warehouse/` a name DuckDB can query**, the way a dataset gives a
table a name. It is the only interface to DuckDB these lessons need, and every query in them goes
through it.

`ask.py`:

```python
import pathlib
import sys

import duckdb

con = duckdb.connect()
for folder in sorted(pathlib.Path('warehouse').iterdir()):
    con.sql(f"CREATE VIEW {folder.name} AS SELECT * FROM read_parquet("
            f"'{folder}/**/*.parquet', hive_partitioning = true)")
sql = sys.argv[1]
if sql.endswith('.sql'):
    sql = pathlib.Path(sql).read_text()
if sql.lstrip().upper().startswith('EXPLAIN'):
    print(con.sql(sql).fetchall()[0][1])
else:
    con.sql(sql).show(max_width=100)
```

**`hive_partitioning = true` is DuckDB's version of `--hive_partitioning_mode=AUTO`**: it reads `dt`
out of each folder's name and offers it as a column. The view reads the files every time it is
queried, so a folder you rewrite is what the next query sees. The question can be a string, or the
name of a `.sql` file, and a question that starts with `EXPLAIN` prints the plan as text; lessons 15
and 16 read those. Save it as `~/gcp/ask.py`, and ask the first three questions:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT count(*) AS orders, min(dt) AS first_day, max(dt) AS last_day FROM orders"
┌─────────┬────────────┬────────────┐
│ orders  │ first_day  │  last_day  │
│  int64  │    date    │    date    │
├─────────┼────────────┼────────────┤
│ 1245118 │ 2026-08-01 │ 2026-09-29 │
└─────────┴────────────┴────────────┘

ana@laptop:~/gcp$ python3 ask.py "SELECT column_name, column_type FROM (DESCRIBE orders)"
┌─────────────┬──────────────────────────┐
│ column_name │       column_type        │
│   varchar   │         varchar          │
├─────────────┼──────────────────────────┤
│ order_id    │ VARCHAR                  │
│ customer_id │ VARCHAR                  │
│ store_id    │ BIGINT                   │
│ district    │ VARCHAR                  │
│ items       │ BIGINT                   │
│ total_cents │ BIGINT                   │
│ payment     │ VARCHAR                  │
│ created_at  │ TIMESTAMP WITH TIME ZONE │
│ dt          │ DATE                     │
└─────────────┴──────────────────────────┘

ana@laptop:~/gcp$ python3 ask.py "SELECT order_id, customer_id, store_id, total_cents, created_at, dt FROM orders LIMIT 3"
┌────────────────┬─────────────┬──────────┬─────────────┬──────────────────────────┬────────────┐
│    order_id    │ customer_id │ store_id │ total_cents │        created_at        │     dt     │
│    varchar     │   varchar   │  int64   │    int64    │ timestamp with time zone │    date    │
├────────────────┼─────────────┼──────────┼─────────────┼──────────────────────────┼────────────┤
│ o-260801-00001 │ c-19923     │        7 │       13676 │ 2026-08-01 07:00:11-03   │ 2026-08-01 │
│ o-260801-00002 │ c-05602     │        1 │       24565 │ 2026-08-01 07:00:11-03   │ 2026-08-01 │
│ o-260801-00003 │ c-34549     │        6 │        3584 │ 2026-08-01 07:00:12-03   │ 2026-08-01 │
└────────────────┴─────────────┴──────────┴─────────────┴──────────────────────────┴────────────┘
```

**The nine columns are DuckDB's names for BigQuery's types.** `VARCHAR` is BigQuery's `STRING`,
`BIGINT` is `INT64`, `TIMESTAMP WITH TIME ZONE` is `TIMESTAMP`, and `DATE` is `DATE`. That mapping is
the whole of the next section, because a type is what decides how many bytes BigQuery counts for a
value. The time `07:00:11-03` is São Paulo's: DuckDB shows a timestamp in the time zone of the
machine, and BigQuery would store the same instant and show it in UTC.
