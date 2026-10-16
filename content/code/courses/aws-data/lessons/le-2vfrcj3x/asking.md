---
title: Asking the lake, and counting what it read
version: 1
---

**Athena's answer comes with one number that decides its price**, `DataScannedInBytes`, and moto's
is always 0. So the question goes to a program of your own that does two things: answers the SQL
with DuckDB, and counts every byte DuckDB takes out of S3 to do it. That count is the quantity
Athena bills, measured on the same objects, and the program prices it with the line the sheet
printed.

Save it as `~/aws/ask.py`, beside `lake.py` and `prices.py`, both of which it imports:

```schooling-example
{"language": "python", "file": "ask.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"ask.py: SQL over the lake in S3, and the bytes the query read to answer it.\n\n    python3 ask.py \"SELECT payment, sum(total_cents) FROM orders GROUP BY payment\"\n    python3 ask.py -t daily=quitanda-curated-prod/daily/:parquet \"SELECT ...\"\n\nATHENA IS NOT RUN HERE. moto accepts an Athena query and runs nothing, so the\nengine is DuckDB, inside this program, reading the same objects in S3 that\nAthena would read. What it measures is what Athena bills for: every byte the\nengine pulls out of S3. Two tables are always defined:\n\n    orders       s3://quitanda-curated-prod/orders/    Parquet\n    orders_csv   s3://quitanda-raw-prod/raw/orders/     CSV\n\nBoth are partitioned by dt, which is read from the keys (dt=2026-10-01/).\n\"\"\"\n", "note": "**Athena is not run here, and the docstring says so first.** The engine is DuckDB, inside this program; the tables are the two layers `lake.py` wrote, and `-t` adds any other prefix in S3 as a table."}, {"code": "import argparse\nimport math\nimport os\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.dataset as ds\nimport pyarrow.fs as fs\n\nfrom lake import CURATED, RAW, filesystem\nfrom prices import price\n\n", "note": "`lake.py` gives the two prefixes and the S3 connection, and `prices.py`, from lesson 1, gives the price of a terabyte scanned. Both have to be in the same directory as this program."}, {"code": "TABLES = {'orders': f'{CURATED}/:parquet', 'orders_csv': f'{RAW}/:csv'}\nMB, TB = 2 ** 20, 2 ** 40\n\n\n", "note": "The two tables every run has, and the units, which are binary: a megabyte here is 2 to the 20th bytes and a terabyte 2 to the 40th."}, {"code": "class Counted(fs.FileSystemHandler):\n    \"\"\"S3 as PyArrow sees it, with a counter on every read.\"\"\"\n\n    def __init__(self, inner):\n        self.inner, self.bytes, self.gets, self.objects = inner, 0, 0, set()\n\n    def open_input_file(self, path):\n        self.objects.add(path)\n        inner, count = self.inner.open_input_file(path), self\n\n        class File:\n            closed = False\n\n            def read(self, n=-1):\n                data = inner.read() if n is None or n < 0 else inner.read(n)\n                count.bytes += len(data)\n                count.gets += 1\n                return data\n\n            def seek(self, *where): return inner.seek(*where)\n            def tell(self): return inner.tell()\n            def size(self): return inner.size()\n            def close(self): inner.close()\n            def readable(self): return True\n            def seekable(self): return True\n\n        return pa.PythonFile(File(), mode='r')\n\n", "note": "**The whole measurement is this class.** It stands between PyArrow and S3, and every `read` the engine makes passes through it: the bytes are added up, each read is one ranged GET request to S3, and the object is remembered."}, {"code": "    def open_input_stream(self, path): return self.open_input_file(path)\n    def get_type_name(self): return 'counted'\n    def normalize_path(self, path): return self.inner.normalize_path(path)\n    def get_file_info(self, paths): return self.inner.get_file_info(paths)\n    def get_file_info_selector(self, selector): return self.inner.get_file_info(selector)\n\n    def refuse(self, *args): raise OSError('ask.py only reads')\n    create_dir = delete_dir = delete_dir_contents = delete_root_dir_contents = refuse\n    delete_file = move = copy_file = open_output_stream = open_append_stream = refuse\n\n\n", "note": "The rest of what PyArrow asks a filesystem: listings and file information are passed straight to S3, and anything that would write is refused, because asking a question must never change the lake."}, {"code": "def main():\n    args = argparse.ArgumentParser()\n    args.add_argument('-t', '--table', action='append', default=[],\n                      help='NAME=BUCKET/PREFIX/:FORMAT, the format parquet, csv, json or orc')\n    args.add_argument('sql')\n    args = args.parse_args()\n    count = Counted(filesystem())\n    s3 = fs.PyFileSystem(count)\n    db = duckdb.connect()\n    tables = dict(TABLES, **dict(t.split('=', 1) for t in args.table))\n    for name, where in tables.items():\n        prefix, kind = where.rsplit(':', 1)\n        try:\n            db.register(name, ds.dataset(prefix, filesystem=s3, format=kind, partitioning='hive'))\n        except FileNotFoundError:\n            print(f'{name}: nothing under s3://{prefix} yet', file=sys.stderr)\n    count.bytes, count.gets, count.objects = 0, 0, set()\n", "note": "Each table is a PyArrow dataset over a prefix, registered in DuckDB by name. `partitioning='hive'` turns `dt=2026-10-01` in a key into a column `dt`, which is also what lets a filter on `dt` skip whole objects. A prefix with nothing under it yet is skipped, with a line saying so. The counters start at zero only after the tables are found, so the listing is not counted as part of the question."}, {"code": "    try:\n        db.sql(args.sql).show(max_rows=40)\n    except duckdb.Error as e:\n        sys.exit(str(e))\n    billed = max(10 * MB, math.ceil(count.bytes / MB) * MB)\n    usd = price('AmazonAthena', 'DataScannedInTB')\n    objects = len(count.objects)\n    print(f'read from S3: {count.bytes:,} bytes in {count.gets} GET requests '\n          f'to {objects} object{\"s\" * (objects != 1)}')\n    print(f'Athena would bill {billed // MB} MB (whole MB, 10 MB minimum): '\n          f'{billed / TB * usd:.6f} USD at {usd:.2f} USD per TB', flush=True)\n    os._exit(0)\n\n\nif __name__ == '__main__':\n    main()\n", "note": "The question, its answer, and the count. **What Athena would bill is the bytes read, rounded up to a whole megabyte, with ten megabytes as the least a query costs.** `os._exit` leaves at once: after a `LIMIT`, PyArrow may still be reading ahead in the background, and an ordinary exit would stop the interpreter under it."}]}
```

**The count is made where the bytes pass, not estimated from the SQL.** DuckDB does not fetch
objects itself here: it asks PyArrow for the rows of a table, PyArrow reads them from S3 through
whatever filesystem it was handed, and the one it is handed is `Counted`, which adds up what every
read returned. So a column the query never names is a column nobody read, and a day the filter
excludes is an object nobody opened, and the numbers at the bottom show both. They are counts of
what this engine did, which is close to what Athena's engine does with the same files, and not a
copy of it: two engines can read the same footer in a different number of requests.

## The first question

How much did Quitanda sell in October, by way of paying? Asked of the CSV:

```
ana@laptop:~/aws$ python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders_csv GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 348030 │ 41382125.37 │
│ credit       │ 249543 │ 29611096.91 │
│ debit        │  97614 │ 11585221.55 │
│ meal-voucher │  60324 │  7158978.69 │
└──────────────┴────────┴─────────────┘

read from S3: 40,641,097 bytes in 93 GET requests to 31 objects
Athena would bill 39 MB (whole MB, 10 MB minimum): 0.000335 USD at 9.00 USD per TB
```

**The answer is four rows, and the read was every byte of every file**: 40,641,097 bytes, the
total `lake.py` printed for the raw layer, to the byte. A CSV file has no way to say where a column
starts, so the engine read every line whole to find two values in each, the payment and the total,
and threw the other five away. The 31 objects are the 31 days, and the 93 GET requests are PyArrow
reading each one in three pieces.

The bill under it is the arithmetic of the rules in "Athena reads the files where they lie": 40,641,097 bytes is 38.8 megabytes,
rounded up to 39, and 39 megabytes at 9 dollars a terabyte is 0.000335 dollars. A small number,
because a month of one shop is a small lake; the next section is about the ratio, which does not
shrink when the lake grows.

## When the question is wrong

A column that is not there is the commonest mistake, and DuckDB says which ones would have been:

```
ana@laptop:~/aws$ python3 ask.py "SELECT sum(total) FROM orders"
Binder Error: Referenced column "total" not found in FROM clause!
Candidate bindings: "total_cents", "dt", "customer_id"
```

No byte count follows, because nothing was read: the error came while the query was being planned,
before a single object was opened. Athena fails the same query at the same stage, with an error of
its own wording, and a failed query costs nothing there either.

**One difference to keep in mind for every question in this course.** `ask.py` lists the prefix each
time it runs, so a day written a second ago is in the next answer. Athena reads the list of
partitions from the catalog, and a day nobody registered is not in its answer at all, which is the surprise "Athena reads the files where they lie" describes. A lake queried by both, which is the ordinary case, can
give two answers to the same SQL for exactly that reason.

