---
title: A lakehouse table, written into a container you can open
version: 1
---

**Fabric itself is not on your computer, and nothing in this section is Fabric.** What is here is
the thing Fabric stores: a Delta table, which is a folder of Parquet files and a log beside them,
written into a blob container in the place a lakehouse keeps its tables. The program that writes
it is `deltalake`, the open-source Delta library, and the container is Azurite's. Every byte of it
is a byte Fabric's Spark, its warehouse and Power BI would read the same way, because they all read
the open format and nothing private.

## A month of orders

Every program from here to lesson 20 reads the same month: Quitanda's October 2026, about a
hundred thousand orders, made by a program so that every computer gets exactly the same rows. Save
it in `~/azure`:

`orders.py`:

```python
"""orders.py: Quitanda's October 2026, one row per order, the same on every computer."""
import random
from datetime import date, timedelta

import pyarrow as pa

PLACES = ["Pinheiros", "Vila Madalena", "Moema", "Tatuapé", "Santana", "Mooca", "Butantã", "Lapa",
          "Perdizes", "Itaim Bibi", "Bela Vista", "Liberdade", "Ipiranga", "Saúde", "Vila Mariana", "Penha"]
PAYMENTS = ["pix"] * 9 + ["credit"] * 7 + ["debit"] * 3 + ["meal-voucher"] * 2


def october(days=31, seed=2026):
    rnd = random.Random(seed)
    cols = {c: [] for c in ("order_id", "dt", "hour", "customer_id", "neighbourhood", "payment", "total_cents")}
    for d in range(days):
        day = date(2026, 10, 1) + timedelta(days=d)
        hours = sorted(rnd.choices(range(7, 24), k=rnd.randint(2800, 3600)))
        for n, hour in enumerate(hours, 1):
            cols["order_id"].append(f"{day:%m%d}-{n:05d}")
            cols["dt"].append(day.isoformat())
            cols["hour"].append(hour)
            cols["customer_id"].append(f"c-{rnd.randint(1, 9000)}")
            cols["neighbourhood"].append(rnd.choice(PLACES))
            cols["payment"].append(rnd.choice(PAYMENTS))
            cols["total_cents"].append(rnd.randint(900, 32000))
    return pa.table(cols)
```

**The seed is what makes it the same everywhere.** `random.Random(2026)` draws the same numbers in
the same order on any machine with Python 3, so the totals printed below are the totals you will
get. Each day's orders are sorted by hour, as a shop's export would be.

## Writing the table

The next program writes the month as one Delta table, where a lakehouse called `sales` in a
workspace called `quitanda-analytics` would keep a table called `orders`:

```schooling-example
{"language": "python", "file": "onelake.py", "parts": [
{"code": "\"\"\"onelake.py: October's orders as a Delta table, where a lakehouse keeps its tables.\"\"\"\nfrom deltalake import DeltaTable, write_deltalake\n\nfrom orders import october\n\n", "note": "`deltalake` is the Delta library written in Rust with a Python face. It needs no Spark and no Java, which is why it fits in a laptop's lab."},
{"code": "AZURITE = {\"account_name\": \"devstoreaccount1\", \"use_emulator\": \"true\"}\nTABLE = \"az://quitanda-analytics/sales.Lakehouse/Tables/orders\"\n\n", "note": "**`use_emulator` points the library at Azurite** on `127.0.0.1:10000`, with the published account and key. The path is the container, then the lakehouse's folder, then `Tables`, then the table: the same shape as a OneLake path, with Azurite's container standing in for the workspace."},
{"code": "if __name__ == \"__main__\":\n    write_deltalake(TABLE, october(), storage_options=AZURITE)\n    table = DeltaTable(TABLE, storage_options=AZURITE)\n    print(f\"version {table.version()}, {len(table.file_uris())} data file, {table.count():,} rows\")\n", "note": "One call writes the Parquet and then the log entry that makes it a table. The table is then opened again from the container, so what is printed is what a second reader would find, not what the writer remembers."}
]}
```

And a third, which asks a question of the table with DuckDB, a SQL engine that runs inside the
Python program:

`ask.py`:

```python
import sys

import duckdb
from deltalake import DeltaTable

from onelake import AZURITE, TABLE

orders = DeltaTable(TABLE, storage_options=AZURITE).to_pyarrow_dataset()
duckdb.sql(sys.argv[1]).show()
```

With Azurite running and the four lines of lesson 1's "Every time you open a terminal" typed, make
the container, write the table, and put the night's raw export beside it, in the lakehouse's other
half:

```
ana@laptop:~/azure$ az storage container create -n quitanda-analytics
{
  "created": true
}
ana@laptop:~/azure$ python onelake.py
version 0, 1 data file, 98,727 rows
ana@laptop:~/azure$ python -c "import orders, pyarrow.csv as c; c.write_csv(orders.october(days=1), 'export.csv')"
ana@laptop:~/azure$ az storage blob upload -c quitanda-analytics -f export.csv -n sales.Lakehouse/Files/exports/2026-10-01.csv -o none
Finished[#############################################################]  100.0000%
ana@laptop:~/azure$ az storage blob list -c quitanda-analytics --query '[].{name:name, bytes:properties.contentLength}' -o table
Name                                                                                               Bytes
-------------------------------------------------------------------------------------------------  -------
sales.Lakehouse/Files/exports/2026-10-01.csv                                                       182294
sales.Lakehouse/Tables/orders/_delta_log/00000000000000000000.json                                 1949
sales.Lakehouse/Tables/orders/part-00000-f29949c4-d009-44ee-9f5e-a1b643a5e98d-c000.snappy.parquet  1205188
```

**Three blobs, and only two of them are the table.** Under `Files` is a CSV like any other blob,
which nothing will query until somebody loads it. Under `Tables/orders` are the Parquet file, with a
random name, and the log, numbered from zero. The 98,727 orders take 1,205,188 bytes as Parquet
compressed with Snappy; the first day alone, as CSV, is 182,294.

## The log is the table

**A reader does not list the folder to find a Delta table's rows; it reads the log.** Each file in
`_delta_log` is one commit, and each line of it is one action. Download the first and look at its
lines:

```
ana@laptop:~/azure$ az storage blob download -c quitanda-analytics -n sales.Lakehouse/Tables/orders/_delta_log/00000000000000000000.json -f v0.json -o none
Finished[#############################################################]  100.0000%
ana@laptop:~/azure$ jq -c keys v0.json
["commitInfo"]
["protocol"]
["metaData"]
["add"]
ana@laptop:~/azure$ jq -c '.protocol // empty' v0.json
{"minReaderVersion":1,"minWriterVersion":2}
ana@laptop:~/azure$ jq -r '.metaData // empty | .schemaString | fromjson | .fields[] | "\(.name) \(.type)"' v0.json
order_id string
dt string
hour long
customer_id string
neighbourhood string
payment string
total_cents long
ana@laptop:~/azure$ jq -c '.add // empty | .stats | fromjson | {numRecords, minValues: {dt: .minValues.dt}, maxValues: {dt: .maxValues.dt}}' v0.json
{"numRecords":98727,"minValues":{"dt":"2026-10-01"},"maxValues":{"dt":"2026-10-31"}}
```

Four actions, and each one is a promise to any reader:

- **`protocol`** says which features of the format a reader must understand to read the table at
  all. Reader version 1 and writer version 2 ask for nothing beyond the basics; a table that uses a
  newer feature, such as deletion vectors, raises them, and a reader too old for the feature must
  refuse the table rather than read it wrong.
- **`metaData`** carries the schema, the partition columns (none here) and the table's settings.
- **`add`** names one Parquet file as part of the table, with its size and **statistics**: how many
  rows, and each column's smallest and largest value. A reader asked for one day can skip a file
  whose range of `dt` does not include it without opening it.
- **`commitInfo`** records who did what and when, which lesson 18 uses for time travel.

**Anything in the folder that no `add` names is not in the table**, and a file that a later commit
removes stays on disk until somebody cleans up. Lesson 18 shows both, because that is where the
bill for a Delta table hides.

## Asking it a question

```
ana@laptop:~/azure$ python ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │  42487 │ 6989795.82 │
│ credit       │  32725 │ 5364244.14 │
│ debit        │  14202 │  2317012.7 │
│ meal-voucher │   9313 │ 1538313.03 │
└──────────────┴────────┴────────────┘

```

**DuckDB did not know the table was Delta**: `deltalake` read the log, worked out which Parquet
files are the table, and handed DuckDB those files as one dataset. That division of labour, one
library for the log and any engine for the files, is the reason a table written by one Fabric
engine is readable by the others, and by Databricks in lesson 21, with no export in between.

## What Azurite cannot stand in for

**OneLake answers the Data Lake endpoint, `dfs`, and Azurite does not have one**, as lesson 3
showed. `deltalake` wrote here through the plain blob interface, which Azure Blob Storage, ADLS
Gen2 and OneLake all answer too. On Fabric the same table would be at:

```
abfss://quitanda-analytics@onelake.dfs.fabric.microsoft.com/sales.Lakehouse/Tables/orders
```

That path was not used in this course, because it needs a Fabric tenant and a sign-in. What
changes between the two is the address and the credentials; the folder, the log and the files are
the same.
