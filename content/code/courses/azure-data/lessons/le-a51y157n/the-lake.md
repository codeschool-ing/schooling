---
title: A month of orders in the lake
version: 1
---

**A serverless pool's bill is decided by the files before any query is written**, so the practice
starts with files. This section puts a month of Quitanda's orders into Azurite twice: once as CSV, the
format the shop exports, and once as Parquet, the format a lake keeps. Everything from here to the end
of the next section runs on your machine, with Azurite alone:

```sh
docker compose up -d
```

**None of it is Synapse.** Azurite holds the files, as Blob Storage would; it has no Data Lake endpoint,
as lesson 3 showed, so the files are plain blobs whose names contain slashes. The engine that queries
them in the next section is DuckDB. What carries over to Synapse is the files themselves, their format and
their folders, because those are what a serverless pool reads too.

Save this as `gen.py` in `~/azure`:

```schooling-example
{"language": "python", "file": "gen.py", "parts": [
{"code": "import io\nimport os\nimport random\nfrom datetime import date, timedelta\n\nimport pyarrow as pa\nimport pyarrow.csv as csv\nimport pyarrow.parquet as pq\nfrom azure.storage.blob import BlobServiceClient\n\nSTORES = [\"pinheiros\", \"moema\", \"tatuape\", \"santana\", \"lapa\"]\nPAYMENTS = [\"pix\"] * 46 + [\"credit\"] * 33 + [\"debit\"] * 13 + [\"meal-voucher\"] * 8\nservice = BlobServiceClient.from_connection_string(os.environ[\"AZURE_STORAGE_CONNECTION_STRING\"])\nlake = service.get_container_client(\"lake\")\nif not lake.exists():\n    lake.create_container()\n", "note": "Five stores, four ways to pay in the proportions a São Paulo grocer might see, and a blob container called `lake` in Azurite. The connection string is the one every terminal of this course exports."},
{"code": "\nrng = random.Random(2026)\nn = 0\nfor d in range(31):\n    day = date(2026, 10, 1) + timedelta(days=d)\n    rows = {\"order_id\": [], \"hour\": [], \"customer_id\": [], \"store\": [], \"payment\": [],\n            \"items\": [], \"total_cents\": []}\n    for _ in range(rng.randint(18_000, 26_000)):\n        n += 1\n        rows[\"order_id\"].append(f\"o-{n:07d}\")\n        rows[\"hour\"].append(min(23, max(7, int(rng.gauss(18, 3)))))\n        rows[\"customer_id\"].append(f\"c-{rng.randint(1, 60_000):05d}\")\n        rows[\"store\"].append(rng.choice(STORES))\n        rows[\"payment\"].append(rng.choice(PAYMENTS))\n        rows[\"items\"].append(rng.randint(1, 30))\n        rows[\"total_cents\"].append(rng.randint(990, 39_990))\n    table = pa.table(rows)\n", "note": "A month of orders, made up but always the same: the generator is seeded, so every run, here and on your machine, produces the same 667,563 orders. Each day gets between 18,000 and 26,000 of them, most in the evening."},
{"code": "\n    for layer, write in ((\"orders\", pq.write_table), (\"orders_csv\", csv.write_csv)):\n        out = io.BytesIO()\n        write(table, out)\n        name = f\"{layer}/dt={day}/part-0.{'parquet' if layer == 'orders' else 'csv'}\"\n        lake.upload_blob(name, out.getvalue(), overwrite=True)\n", "note": "Each day is written twice, as Parquet under `orders/` and as CSV under `orders_csv/`, in a folder named `dt=` and the date. That folder name is the partitioning: a reader that knows the convention can tell what day a file holds without opening it."},
{"code": "\nfor layer in (\"orders\", \"orders_csv\"):\n    blobs = list(lake.list_blobs(name_starts_with=layer + \"/\"))\n    print(f\"{layer:11} {len(blobs)} files, {sum(b.size for b in blobs):,} bytes\")\nprint(f\"{n:,} orders in October\")\n", "note": "What is in the lake afterwards."}
]}
```

```
ana@laptop:~/azure$ python gen.py
orders      31 files, 13,433,647 bytes
orders_csv  31 files, 33,935,337 bytes
667,563 orders in October
```

**The same 667,563 orders, 13,433,647 bytes as Parquet and 33,935,337 as CSV**: the Parquet is 40% of
the CSV, holding exactly the same rows. Two things make the difference. Parquet stores each column
together, so a column of `pix`, `pix`, `credit` repeated twenty thousand times compresses to very little,
where CSV writes every value out in full on every line. And it stores numbers as numbers, where CSV
spells `24890` as five characters and a comma.

**Each file says what is inside it, too.** A Parquet file ends with a footer that lists its columns,
their types, and where in the file each column's data starts. That footer is what lets a reader fetch
two columns of seven and skip the rest, which the next section measures. A CSV file has none of this: to
find the `payment` of any order a reader has to read every line from the start.

**And the folders say what day each file holds.** `orders/dt=2026-10-15/part-0.parquet` holds the 15th
of October and nothing else, which is the convention called hive partitioning. A serverless pool reads
it through its `filepath()` function, and DuckDB and PyArrow read it as a column called `dt`. A query
that asks for one day can skip the other thirty files without opening them.
