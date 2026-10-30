---
title: One question, four amounts of bytes
version: 1
---

**A serverless pool charges for what it reads, so the same question can cost very different amounts
depending on the files it is asked of.** This section asks one question, October's sales by way of
payment, four times: of the CSV and of the Parquet, for the whole month and for one day. The engine is
**DuckDB, not Synapse**: it reads the files in Azurite through a small file system written here, which
counts every byte it fetches. The counts are what a lake reader has to fetch for each question; what a
serverless pool would bill is at least that, with the 10 MB minimum and the rounding of the previous
section applied, at an illustrative price.

Save this as `ask.py`, beside `gen.py`:

```schooling-example
{"language": "python", "file": "ask.py", "parts": [
{"code": "import io\nimport os\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.dataset as ds\nimport pyarrow.fs as pafs\nfrom azure.storage.blob import BlobServiceClient\n\nPRICE_PER_TB = 5.00   # USD, ILLUSTRATIVE: run the price sheet of lesson 1 for the real one\n", "note": "DuckDB answers the SQL, PyArrow reads the files, and the Azure library fetches the bytes. The price is illustrative, as every price in this course is."},
{"code": "\n\nclass Lake(pafs.FileSystemHandler):\n    \"\"\"The lake container in Azurite, read-only, counting every byte it hands over.\"\"\"\n\n    def __init__(self):\n        service = BlobServiceClient.from_connection_string(os.environ[\"AZURE_STORAGE_CONNECTION_STRING\"])\n        self.container = service.get_container_client(\"lake\")\n        self.bytes, self.requests, self.blobs = 0, 0, set()\n", "note": "`Lake` presents the `lake` container to PyArrow as a file system, and counts what it hands over: bytes, read requests and the blobs opened."},
{"code": "\n    def get_file_info(self, paths):\n        infos = []\n        for path in paths:\n            blob = self.container.get_blob_client(path)\n            if blob.exists():\n                infos.append(pafs.FileInfo(path, pafs.FileType.File, size=blob.get_blob_properties().size))\n            elif any(True for _ in self.container.list_blobs(name_starts_with=path.rstrip(\"/\") + \"/\")):\n                infos.append(pafs.FileInfo(path, pafs.FileType.Directory))\n            else:\n                infos.append(pafs.FileInfo(path, pafs.FileType.NotFound))\n        return infos\n\n    def get_file_info_selector(self, selector):\n        base = selector.base_dir.rstrip(\"/\") + \"/\"\n        infos, dirs = [], set()\n        for blob in self.container.list_blobs(name_starts_with=base):\n            infos.append(pafs.FileInfo(blob.name, pafs.FileType.File, size=blob.size))\n            parts = blob.name[len(base):].split(\"/\")[:-1]\n            dirs.update(base + \"/\".join(parts[:i + 1]) for i in range(len(parts)))\n        return infos + [pafs.FileInfo(d, pafs.FileType.Directory) for d in sorted(dirs)]\n", "note": "Listing. PyArrow asks what is at a path and what is under a folder, and both answers come from listing blobs by prefix, which reads no data."},
{"code": "\n    def open_input_file(self, path):\n        return pa.PythonFile(Blob(self, path), mode=\"r\")\n", "note": "Opening a file returns a `Blob`, below, wrapped so PyArrow can seek and read in it."},
{"code": "\n    def get_type_name(self):\n        return \"azurite-lake\"\n\n    def normalize_path(self, path):\n        return path\n\n    def _read_only(self, *args, **kwargs):\n        raise NotImplementedError(\"the lake is read-only here\")\n\n    create_dir = delete_dir = delete_dir_contents = delete_root_dir_contents = _read_only\n    delete_file = move = copy_file = _read_only\n    open_input_stream = open_output_stream = open_append_stream = _read_only\n", "note": "The rest of what a file system must offer. Nothing here writes, moves or deletes, so all of it refuses."},
{"code": "\n\nclass Blob(io.RawIOBase):\n    \"\"\"One blob, read in byte ranges: each read is one ranged GET to Azurite.\"\"\"\n\n    def __init__(self, lake, path):\n        self.lake, self.client = lake, lake.container.get_blob_client(path)\n        self.size, self.pos = self.client.get_blob_properties().size, 0\n        lake.blobs.add(path)\n\n    def readable(self):\n        return True\n\n    def seekable(self):\n        return True\n\n    def tell(self):\n        return self.pos\n\n    def seek(self, offset, whence=0):\n        self.pos = [offset, self.pos + offset, self.size + offset][whence]\n        return self.pos\n\n    def readinto(self, buffer):\n        n = min(len(buffer), self.size - self.pos)\n        if n <= 0:\n            return 0\n        buffer[:n] = self.client.download_blob(offset=self.pos, length=n).readall()\n        self.pos += n\n        self.lake.bytes += n\n        self.lake.requests += 1\n        return n\n", "note": "**The counting is here.** Every `readinto` is one ranged read of the blob, `download_blob` with an offset and a length, and adds its bytes to the count. A reader that seeks to a column and reads only it is visible as a small number."},
{"code": "\n\nlake = Lake()\nfs = pafs.PyFileSystem(lake)\nsql = sys.argv[1]\nif \" orders_csv\" in sql:\n    orders_csv = ds.dataset(\"orders_csv\", filesystem=fs, format=\"csv\", partitioning=\"hive\")\nelse:\n    orders = ds.dataset(\"orders\", filesystem=fs, format=\"parquet\", partitioning=\"hive\")\n", "note": "The two tables. A dataset is a folder of files with the `dt=` folders read as a column, and only the one the query names is opened, so that a question about Parquet is not charged for looking at the CSV."},
{"code": "\nduckdb.sql(sql).show()\nif len(lake.blobs) < 5:\n    print(\"blobs opened:\", \", \".join(sorted(lake.blobs)))\nmb = max(10, -(-lake.bytes // 1_000_000))\nprint(f\"read from the lake: {lake.bytes:,} bytes in {lake.requests} ranged reads of {len(lake.blobs)} blobs\")\nprint(f\"billed as {mb} MB (whole MB, 10 MB minimum): {mb / 1_000_000 * PRICE_PER_TB:.6f} USD at an illustrative {PRICE_PER_TB:.2f} USD per TB\")\n", "note": "DuckDB runs the query, finding `orders` or `orders_csv` among the program's variables. It pushes the columns the query needs and its filter on `dt` down into the dataset, which is what decides what is read. Then the count, and the bill a serverless pool would apply to that many bytes."}
]}
```

## The whole month, as CSV and as Parquet

```
ana@laptop:~/azure$ python ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders_csv GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 307681 │ 63109558.55 │
│ credit       │ 219350 │ 44934884.91 │
│ debit        │  87078 │  17837618.2 │
│ meal-voucher │  53454 │ 10989255.43 │
└──────────────┴────────┴─────────────┘

read from the lake: 34,900,248 bytes in 50 ranged reads of 31 blobs
billed as 35 MB (whole MB, 10 MB minimum): 0.000175 USD at an illustrative 5.00 USD per TB
```

**34,900,248 bytes: every byte of every CSV file**, and a little more than the 33,935,337 stored,
because PyArrow first read the start of one file to learn the columns, as the one-day questions below
show more plainly. The question needs two columns of seven, and a
CSV gives a reader no way to skip the other five.

```
ana@laptop:~/azure$ python ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 307681 │ 63109558.55 │
│ credit       │ 219350 │ 44934884.91 │
│ debit        │  87078 │  17837618.2 │
│ meal-voucher │  53454 │ 10989255.43 │
└──────────────┴────────┴─────────────┘

read from the lake: 5,600,246 bytes in 94 ranged reads of 31 blobs
billed as 10 MB (whole MB, 10 MB minimum): 0.000050 USD at an illustrative 5.00 USD per TB
```

**The same four rows from 5,600,246 bytes**, a sixth of the CSV's. DuckDB asked PyArrow for `payment` and
`total_cents` only, and PyArrow read each file's footer, then the blocks of those two columns, and
nothing else: 94 ranged reads, about three per file, where the CSV needed fewer and larger ones.

## One day, as Parquet and as CSV

```
ana@laptop:~/azure$ python ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │   8415 │ 1720742.02 │
│ credit       │   5928 │ 1219676.93 │
│ debit        │   2357 │  478763.39 │
│ meal-voucher │   1488 │  306383.34 │
└──────────────┴────────┴────────────┘

blobs opened: orders/dt=2026-10-01/part-0.parquet, orders/dt=2026-10-15/part-0.parquet
read from the lake: 228,895 bytes in 4 ranged reads of 2 blobs
billed as 10 MB (whole MB, 10 MB minimum): 0.000050 USD at an illustrative 5.00 USD per TB
```

**228,895 bytes from two blobs.** The filter on `dt` was settled before anything was read: `dt` is in the
folder name, so the other days were never opened. The second blob is the 15th; the first, the 1st of
October, was opened when the dataset was created, because PyArrow reads one file to learn the table's
columns. A serverless pool has the same need, and the same kind of cost, when it is not told the schema.

```
ana@laptop:~/azure$ python ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders_csv WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │   8415 │ 1720742.02 │
│ credit       │   5928 │ 1219676.93 │
│ debit        │   2357 │  478763.39 │
│ meal-voucher │   1488 │  306383.34 │
└──────────────┴────────┴────────────┘

blobs opened: orders_csv/dt=2026-10-01/part-0.csv, orders_csv/dt=2026-10-15/part-0.csv
read from the lake: 1,889,288 bytes in 2 ranged reads of 2 blobs
billed as 10 MB (whole MB, 10 MB minimum): 0.000050 USD at an illustrative 5.00 USD per TB
```

**The CSV read the whole of the 15th, 1,889,288 bytes, about eight times the Parquet.** Partitioning
worked for both formats: each opened two files out of thirty-one. **The two decisions are independent
and they multiply**: the folders decide how many files a question opens, and the format decides how
much of each file it reads. Together they took the question from 34,900,248 bytes to 228,895, about 150
times less.

## What the bill would say

At this size every query but the first falls under the 10 MB minimum, so on a serverless pool three of
the four would cost the same, and the first three and a half times as much. That is a property of a
small lake, not a reason to ignore the layout: the ratios stay and the minimum does not. A year of these
orders read as CSV by a dashboard that refreshes every five minutes is the CSV month twelve times over,
288 times a day. The same dashboard over Parquet, partitioned by day and asking for today, reads a
footer and two columns of one file. Both answer correctly, and only one of them is a bill anybody
notices.
