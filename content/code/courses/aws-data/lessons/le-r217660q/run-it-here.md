---
title: The same job, run where you can watch it
version: 1
---

**The transformation does not need Spark to be understood, only to be big.** A month of Quitanda is
40 MB of CSV, which a laptop reads in seconds. The logic of the job is the same at any size:
what is new, which days it touches, what each day becomes, what the catalog is told, what is
remembered. This program does all five against moto's S3 and moto's catalog, with DuckDB doing the
work Spark would do. Save it as `~/aws/etl.py`:

```schooling-example
{"language": "python", "file": "etl.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"etl.py: the nightly job, raw CSV to curated Parquet, run here instead of on Glue.\n\n    python3 etl.py\n\nGLUE IS NOT RUN HERE. moto marks a Glue job SUCCEEDED and runs nothing, so\nthis program does on your computer what the Glue script of lesson 17 does on\nAWS. It finds the raw files no earlier run has processed, rewrites each day\nthey belong to as one Parquet file with no order in it twice, adds those days\nto the table quitanda.orders in the catalog, and remembers which files it has\ndone in a bookmark it keeps in S3.\n\"\"\"\n", "note": "**Glue is not run here, and the docstring says so before anything else.** What the program does is the job's whole logic, in the order the Glue script does it: find what is new, rewrite the days it touches, tell the catalog, remember."}, {"code": "import json\n\nimport boto3\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.csv as csv\nimport pyarrow.fs as fs\nimport pyarrow.parquet as pq\n\nfrom lake import CURATED, RAW, SCHEMA, filesystem\n\n", "note": "boto3 talks to the catalog, as the AWS command line does, and reads `AWS_ENDPOINT_URL` by itself. DuckDB removes the duplicates; PyArrow reads the CSV and writes the Parquet. `lake.py` gives the two prefixes and the schema, so the curated files get exactly the types lesson 15's did."}, {"code": "BOOKMARK = 'quitanda-glue-prod/bookmarks/orders-etl.json'\n\n\ndef bookmark(s3):\n    try:\n        with s3.open_input_stream(BOOKMARK) as f:\n            return set(json.load(f))\n    except FileNotFoundError:\n        return set()\n\n\n", "note": "**The bookmark is a list of the raw keys already done**, kept as a JSON object in S3. No bookmark yet means nothing has been done, which is the state of a job's first run."}, {"code": "def day_of(path):\n    return path.split('/dt=')[1].split('/')[0]\n\n\n", "note": "The day a raw key belongs to, read out of its `dt=` part."}, {"code": "def rewrite(s3, day, paths):\n    types = csv.ConvertOptions(column_types=SCHEMA)\n    parts = []\n    for path in paths:\n        with s3.open_input_stream(path) as f:\n            parts.append(csv.read_csv(f, convert_options=types))\n    raw = pa.concat_tables(parts)\n    clean = duckdb.sql('SELECT DISTINCT ON (order_id) * FROM raw ORDER BY order_id')\n    clean = clean.to_arrow_table().cast(SCHEMA)\n    out = f'{CURATED}/dt={day}/orders.parquet'\n    pq.write_table(clean, out, filesystem=s3)\n    return raw.num_rows, clean.num_rows, s3.get_file_info(out).size\n\n\n", "note": "**One day, rewritten from every raw file it has, not only the new one.** The CSV is read with the schema's types, so a total that is not a whole number fails here instead of in a query. `DISTINCT ON (order_id)` keeps one row per order, and sorting by `order_id` puts the day back in the order it happened. The Parquet replaces whatever the day had before, which is what makes a second run harmless."}, {"code": "def register(days):\n    glue = boto3.client('glue')\n    storage = glue.get_table(DatabaseName='quitanda', Name='orders')['Table']['StorageDescriptor']\n    there = 0\n    for i in range(0, len(days), 100):\n        rows = [{'Values': [d], 'StorageDescriptor': dict(storage, Location=f\"{storage['Location']}dt={d}/\")}\n                for d in days[i:i + 100]]\n        answer = glue.batch_create_partition(DatabaseName='quitanda', TableName='orders',\n                                             PartitionInputList=rows)\n        for e in answer.get('Errors', []):\n            if e['ErrorDetail']['ErrorCode'] != 'AlreadyExistsException':\n                raise RuntimeError(f\"{e['PartitionValues'][0]}: {e['ErrorDetail']['ErrorMessage']}\")\n            there += 1\n    return there\n\n\n", "note": "The days go into the catalog the way lesson 16 put them there, a hundred per request, each partition a copy of the table's storage descriptor with its own location. **An existing partition is counted, and any other error stops the job**, which is lesson 16's advice about the `Errors` list put into code."}, {"code": "def main():\n    s3 = filesystem()\n    done = bookmark(s3)\n    found = sorted(f.path for f in s3.get_file_info(fs.FileSelector(RAW, recursive=True))\n                   if f.path.endswith('.csv'))\n    new = [p for p in found if p not in done]\n    if not new:\n        print(f'{len(found)} raw files, none of them new: nothing to do')\n        return\n    days = sorted({day_of(p) for p in new})\n    print(f'{len(new)} new raw file{\"s\" * (len(new) != 1)} in {len(days)} day{\"s\" * (len(days) != 1)}')\n    read = kept = size = 0\n    for day in days:\n        paths = [p for p in found if day_of(p) == day]\n        r, k, b = rewrite(s3, day, paths)\n        read, kept, size = read + r, kept + k, size + b\n        if r != k:\n            print(f'  {day}: {r:,} rows in {len(paths)} files, {r - k:,} of them duplicates')\n    print(f'  {read:,} rows read, {kept:,} kept, {size:,} bytes of Parquet written')\n    there = register(days)\n    print(f'  {len(days) - there} partitions added to quitanda.orders, {there} already there')\n    with s3.open_output_stream(BOOKMARK) as f:\n        f.write(json.dumps(sorted(done | set(new)), indent=1).encode())\n\n\nif __name__ == '__main__':\n    main()\n", "note": "The run itself. Every raw key is listed and compared with the bookmark; with nothing new it says so and stops. Otherwise each day with a new file is rewritten, the days are registered, and **the bookmark is written last**, so a run that fails halfway leaves the bookmark as it was and the next run does the same days again."}]}
```

## A first night

The program needs a raw layer to read and a table to register days in. The table is lesson 16's
`orders-table.json`, which you saved there; if you did not, it is shown whole in lesson 16, "The catalog, and what a table is made of". And `lake.py --layer raw` writes October's CSV and no Parquet, so that every curated
file below is the job's:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-raw-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws glue create-database --database-input '{"Name": "quitanda"}' && aws glue create-table --database-name quitanda --table-input file://orders-table.json
ana@laptop:~/aws$ python3 lake.py --layer raw
755,511 orders in 31 days
  s3://quitanda-raw-prod/raw/orders/  31 objects    40,641,097 bytes
```

```
ana@laptop:~/aws$ python3 etl.py
31 new raw files in 31 days
  755,511 rows read, 755,511 kept, 12,703,975 bytes of Parquet written
  31 partitions added to quitanda.orders, 0 already there
```

**31 files, 755,511 rows in and the same out, 12,703,975 bytes of Parquet.** That is the size
`lake.py` printed for its own curated layer in lesson 15, to the byte, and it is not luck: the same
rows, in the same order, with the same types, written by the same library, are the same file.
Nothing was duplicated in October's export, so nothing was dropped, and the catalog gained the 31
partitions lesson 16 added by hand.

## Is it right?

The question lesson 15 asked, asked again of what the job wrote:

```
ana@laptop:~/aws$ python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 348030 │ 41382125.37 │
│ credit       │ 249543 │ 29611096.91 │
│ debit        │  97614 │ 11585221.55 │
│ meal-voucher │  60324 │  7158978.69 │
└──────────────┴────────┴─────────────┘

read from S3: 5,102,048 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ aws glue get-partitions --database-name quitanda --table-name orders --query 'length(Partitions)'
31
```

**The same four rows, to the cent, from the same 5,102,048 bytes**, and 31 partitions in the
catalog. A job that produces exactly what a known-good process produced is the cheapest test a
pipeline has, and it is worth keeping: a change to the job that moves any of these numbers has
changed what the lake says about October.

What this run cannot show is anything about Glue: how long the workers take to start, how the work
spreads across ten of them, what happens when one fails. Those are properties of a real run on AWS,
and they are described rather than shown in this course.

