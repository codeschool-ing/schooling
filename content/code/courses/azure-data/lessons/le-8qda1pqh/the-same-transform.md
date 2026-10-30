---
title: The same night, written as code
version: 1
---

**Neither a mapping data flow nor a Spark notebook runs on a laptop without Azure, and this section
runs neither.** What it runs is the transformation itself: the night's export as the shop writes it,
cleaned, deduplicated and summarised, by a program of the kind a notebook holds, with DuckDB doing
the work Spark would do on a cluster and Azurite holding the files. The logic is the same at any size;
what a cluster adds is the size, and that is what the next sections price.

## The export, as the shop writes it

**A raw export is never the clean table lesson 17 generated.** Quitanda's shop writes its export
with three habits that every load has to undo: an order sent twice when the shop's own upload is
retried, a payment method written in any case and with spaces around it, and a total in reais with a
comma, `42,87`, because that is how a Brazilian screen shows it. This program writes one night like
that, from the same orders as `orders.py`:

`export.py`:

```python
"""export.py: one night's export, written the way Quitanda's shop really writes it."""
import csv
import random
import sys

from orders import october

day = october(days=1).to_pylist()
rnd = random.Random(29)
rows = []
for o in day:
    total = f"{o['total_cents'] // 100},{o['total_cents'] % 100:02d}"
    payment = rnd.choice([o["payment"], o["payment"].upper(), f" {o['payment']} "])
    rows.append([o["order_id"], f"{o['dt']} {o['hour']:02d}:{rnd.randint(0, 59):02d}",
                 o["customer_id"], o["neighbourhood"], payment, total])
    if rnd.random() < 0.02:
        rows.append(rows[-1])

with open(sys.argv[1], "w", newline="") as f:
    out = csv.writer(f, lineterminator="\n")
    out.writerow(["order_id", "created_at", "customer_id", "neighbourhood", "payment", "total"])
    out.writerows(rows)
print(f"{len(rows):,} rows written to {sys.argv[1]}")
```

## The transformation

The program a notebook would hold has three parts: a function that cleans, a function that
summarises, and the code that reads from storage and writes back. Kept apart, the first two can be
tested without any storage at all, which is the next section.

```schooling-example
{"language": "python", "file": "clean.py", "parts": [
{"code": "\"\"\"clean.py: the night's transformation, written as a notebook would hold it, run over Azurite.\n\n    python clean.py 2026-10-01\n\"\"\"\nimport io\nimport os\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.csv as csv\nimport pyarrow.parquet as pq\nfrom azure.storage.blob import BlobServiceClient\n\n", "note": "The Azure SDK for Blob Storage reads and writes the files; PyArrow reads the CSV and writes the Parquet; DuckDB does the transformation in SQL, as Spark SQL would in a notebook."},
{"code": "COLUMNS = [\"order_id\", \"created_at\", \"customer_id\", \"neighbourhood\", \"payment\", \"total\"]\n\n\n", "note": "**Every column is read as text.** The export's total is `42,87`, which no number parser reads, and guessing types from a sample is how a load fails on the first night a column looks different."},
{"code": "def clean(raw):\n    return duckdb.sql(\"\"\"\n        SELECT DISTINCT ON (order_id)\n               order_id,\n               strftime(CAST(created_at AS TIMESTAMP), '%Y-%m-%d') AS dt,\n               hour(CAST(created_at AS TIMESTAMP)) AS hour,\n               customer_id,\n               neighbourhood,\n               lower(trim(payment)) AS payment,\n               CAST(round(CAST(replace(total, ',', '.') AS DECIMAL(12, 2)) * 100) AS BIGINT) AS total_cents\n        FROM raw\n        ORDER BY order_id\n    \"\"\").to_arrow_table()\n\n\n", "note": "**The rules of the night, in one query.** `DISTINCT ON (order_id)` keeps one row per order, whatever the shop resent. The time becomes a day and an hour. The payment is trimmed and lowered. The total has its comma turned into a point, becomes a decimal, and is stored in cents, as an integer, the only safe way to keep money."},
{"code": "def summary(orders):\n    return duckdb.sql(\"\"\"\n        SELECT neighbourhood, count(*) AS orders, sum(total_cents) / 100 AS reais\n        FROM orders GROUP BY neighbourhood ORDER BY reais DESC LIMIT 5\n    \"\"\")\n\n\n", "note": "A summary for the people waiting on the night: the five neighbourhoods that sold most. In a pipeline this would be a table of its own; here it is printed."},
{"code": "def main(day):\n    lake = BlobServiceClient.from_connection_string(os.environ[\"AZURE_STORAGE_CONNECTION_STRING\"])\n    data = lake.get_blob_client(\"raw\", f\"orders/{day}.csv\").download_blob().readall()\n    types = csv.ConvertOptions(column_types=dict.fromkeys(COLUMNS, pa.string()))\n    raw = csv.read_csv(io.BytesIO(data), convert_options=types)\n    orders = clean(raw)\n    out = io.BytesIO()\n    pq.write_table(orders, out, compression=\"zstd\")\n    lake.get_blob_client(\"curated\", f\"orders/dt={day}/orders.parquet\").upload_blob(\n        out.getvalue(), overwrite=True)\n    print(f\"{raw.num_rows:,} rows read, {raw.num_rows - orders.num_rows} duplicates dropped, \"\n          f\"{orders.num_rows:,} orders written as {out.tell():,} bytes of Parquet\")\n    summary(orders).show()\n\n\n", "note": "**Read, clean, write, in that order, and the write replaces.** The raw file comes from `raw/orders/<day>.csv` and the result goes to `curated/orders/dt=<day>/orders.parquet` with `overwrite=True`, so running the night twice leaves one copy of the day, which lesson 19 asked of every load."},
{"code": "if __name__ == \"__main__\":\n    main(sys.argv[1])\n"}
]}
```

Make the two containers, write the export, put it where the shop would, and run the night:

```
ana@laptop:~/azure$ az storage container create -n raw -o none && az storage container create -n curated -o none
ana@laptop:~/azure$ python export.py export.csv
2,972 rows written to export.csv
ana@laptop:~/azure$ head -4 export.csv
order_id,created_at,customer_id,neighbourhood,payment,total
1001-00001,2026-10-01 07:04,c-6292,Moema, pix ,"42,87"
1001-00002,2026-10-01 07:18,c-7914,Bela Vista, meal-voucher ,"168,21"
1001-00003,2026-10-01 07:25,c-1255,Vila Madalena,PIX,"64,11"
ana@laptop:~/azure$ wc -c export.csv
176106 export.csv
ana@laptop:~/azure$ az storage blob upload -c raw -n orders/2026-10-01.csv -f export.csv -o none
Finished[#############################################################]  100.0000%
ana@laptop:~/azure$ python clean.py 2026-10-01
2,972 rows read, 51 duplicates dropped, 2,921 orders written as 31,810 bytes of Parquet
┌───────────────┬────────┬──────────┐
│ neighbourhood │ orders │  reais   │
│    varchar    │ int64  │  double  │
├───────────────┼────────┼──────────┤
│ Butantã       │    204 │ 34759.67 │
│ Tatuapé       │    197 │ 32242.19 │
│ Mooca         │    184 │ 31313.87 │
│ Ipiranga      │    183 │ 31133.88 │
│ Liberdade     │    190 │ 31070.65 │
└───────────────┴────────┴──────────┘
```

**2,972 rows in, 51 of them a second copy of an order, 2,921 orders out**, as 31,810 bytes of Parquet
compressed with zstd, against the 176,106 bytes of the CSV. The summary is the first thing an analyst
would ask of the night, and it is computed from the clean orders, so no resent order counts twice in
Butantã's 34,759.67 reais.

The night has to be safe to run again, because lesson 19's triggers and people both rerun nights:

```
ana@laptop:~/azure$ az storage blob list -c curated --query '[].{name:name, bytes:properties.contentLength}' -o table
Name                                 Bytes
-----------------------------------  -------
orders/dt=2026-10-01/orders.parquet  31810
ana@laptop:~/azure$ python clean.py 2026-10-01 | head -1
2,972 rows read, 51 duplicates dropped, 2,921 orders written as 31,810 bytes of Parquet
ana@laptop:~/azure$ az storage blob list -c curated --query 'length(@)'
1
```

**One file for the day, the same size, after two runs.** The write replaced the day's Parquet, so the
second run left exactly what the first did. Had `clean.py` written a new file name each time, the
second run would have left the day twice in `curated`, and every reader of the folder would have
counted it twice.

## What a cluster would change

**On Spark, the same rules would be the same SQL, or the same few lines of PySpark**, run by a
cluster over thousands of files instead of one process over one. A notebook in Fabric, Synapse or
Databricks holding this code would read `abfss://` paths instead of calling the blob SDK, and would
write a Delta table instead of a Parquet file, with lesson 18's overwrite of one partition doing what
`overwrite=True` does here. A mapping data flow would draw the same rules as boxes: a source, a
derived column for the payment and the total, an aggregate for the duplicates, a sink. The next two
sections are about what differs between those two once the rules are the same.
