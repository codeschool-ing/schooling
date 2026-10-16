---
title: A month of orders in the lake
version: 1
---

**A question about bytes needs enough of them to matter**, so this section fills the lake. Lesson
1's three CSV files of two orders each are too small for any format to make a difference. A month of
Quitanda's orders is three quarters of a million rows, and on that the difference between one way of
storing them and another is a factor you can see. Nobody has Quitanda's real orders, so a program
invents them, the same ones every time.

Copy it with the button on the block and save it as `~/aws/lake.py`, the way lesson 1 saved
`prices.py`. It needs PyArrow, which lesson 1 installed with DuckDB into the virtual environment.

```schooling-example
{"language": "python", "file": "lake.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"lake.py: Quitanda's orders for October 2026, written into the lake in S3.\n\n    python3 lake.py                 # both layers, all 31 days\n    python3 lake.py --layer raw     # only the CSV the shop exports\n    python3 lake.py --days 3        # only the first three days\n\nThe orders are invented, and they are the same on every run: the generator is\nseeded, so two runs write the same bytes. Each day goes to two places:\n\n    s3://quitanda-raw-prod/raw/orders/dt=2026-10-01/orders.csv\n    s3://quitanda-curated-prod/orders/dt=2026-10-01/orders.parquet\n\nBoth buckets must exist already. The S3 it writes to is AWS_ENDPOINT_URL when\nthat is set, which in this course is moto.\n\"\"\"\n", "note": "The docstring is the manual: how to run it, what it writes and where. **The orders are invented and seeded**, so your lake holds the same bytes as the one in this lesson, and every number below can be checked on your own machine."}, {"code": "import argparse\nimport datetime\nimport os\nimport random\nimport urllib.parse\n\nimport pyarrow as pa\nimport pyarrow.csv as csv\nimport pyarrow.fs as fs\nimport pyarrow.parquet as pq\n\n", "note": "Python's standard library, then PyArrow: its CSV writer, its Parquet writer, and `pyarrow.fs`, which speaks S3 itself."}, {"code": "RAW = 'quitanda-raw-prod/raw/orders'\nCURATED = 'quitanda-curated-prod/orders'\nSCHEMA = pa.schema([('order_id', pa.string()), ('customer_id', pa.string()),\n                    ('hour', pa.int8()), ('items', pa.int16()),\n                    ('total_cents', pa.int64()), ('payment', pa.string()),\n                    ('neighbourhood', pa.string())])\nPAYMENTS, PAYMENT_SHARE = ['pix', 'credit', 'debit', 'meal-voucher'], [46, 33, 13, 8]\nHOURS = list(range(7, 24))\nHOUR_SHARE = [1, 2, 3, 3, 4, 5, 4, 3, 3, 3, 4, 6, 8, 9, 7, 4, 2]\nNEIGHBOURHOODS = ['Pinheiros', 'Moema', 'Vila Mariana', 'Perdizes', 'Mooca', 'Lapa',\n                  'Santana', 'Itaim Bibi', 'Bela Vista', 'Liberdade', 'Ipiranga',\n                  'Brooklin', 'Vila Madalena', 'Santo Amaro', 'Penha', 'Jabaquara']\nCUSTOMERS = 40_000\n\n\n", "note": "Where the two layers live, the columns and their types, and the shapes of the invention: how payments, hours and neighbourhoods are shared out. **`SCHEMA` is written once and used for both files**, so the CSV and the Parquet hold the same seven columns."}, {"code": "def filesystem():\n    url = os.environ.get('AWS_ENDPOINT_URL')\n    region = os.environ.get('AWS_DEFAULT_REGION', 'sa-east-1')\n    if not url:\n        return fs.S3FileSystem(region=region)\n    u = urllib.parse.urlparse(url)\n    return fs.S3FileSystem(endpoint_override=u.netloc, scheme=u.scheme, region=region)\n\n\n", "note": "**PyArrow does not read `AWS_ENDPOINT_URL`**, so the program reads it and passes the address on. Without the variable it talks to the real S3, in the region the terminal names."}, {"code": "def orders(rng, day, regulars):\n    n = 20_000 + rng.randint(0, 4_000) + (8_000 if day.weekday() >= 5 else 0)\n    items = [min(40, 1 + int(rng.expovariate(1 / 8))) for _ in range(n)]\n    customers = rng.choices(range(1, CUSTOMERS + 1), cum_weights=regulars, k=n)\n    return pa.table({\n        'order_id': [f'o-{day:%m%d}-{i:05d}' for i in range(1, n + 1)],\n        'customer_id': [f'c-{c}' for c in customers],\n        'hour': sorted(rng.choices(HOURS, HOUR_SHARE, k=n)),\n        'items': items,\n        'total_cents': [990 + i * rng.randint(390, 2190) for i in items],\n        'payment': rng.choices(PAYMENTS, PAYMENT_SHARE, k=n),\n        'neighbourhood': rng.choices(NEIGHBOURHOODS, k=n),\n    }, schema=SCHEMA)\n\n\n", "note": "One day of orders as a table. Weekdays have 20,000 to 24,000 and weekends 8,000 more, the hours are sorted so that a file reads in the order the day happened, and a total is a delivery fee of 9.90 plus a price per item."}, {"code": "def main():\n    args = argparse.ArgumentParser()\n    args.add_argument('--layer', choices=['raw', 'curated', 'both'], default='both')\n    args.add_argument('--days', type=int, default=31)\n    args = args.parse_args()\n    s3, rng = filesystem(), random.Random(2026)\n    regulars, weight = [], 0.0\n    for rank in range(1, CUSTOMERS + 1):\n        weight += rank ** -0.7\n        regulars.append(weight)\n", "note": "The arguments, the seeded generator, and `regulars`: cumulative weights that make a few customers order far more often than the rest, the way a real shop's customers do."}, {"code": "    count, size = 0, {RAW: 0, CURATED: 0}\n    for d in range(args.days):\n        day = datetime.date(2026, 10, 1) + datetime.timedelta(days=d)\n        table = orders(rng, day, regulars)\n        count += table.num_rows\n        if args.layer in ('raw', 'both'):\n            path = f'{RAW}/dt={day}/orders.csv'\n            with s3.open_output_stream(path) as out:\n                csv.write_csv(table, out, csv.WriteOptions(quoting_style='needed'))\n            size[RAW] += s3.get_file_info(path).size\n        if args.layer in ('curated', 'both'):\n            path = f'{CURATED}/dt={day}/orders.parquet'\n            pq.write_table(table, path, filesystem=s3)\n            size[CURATED] += s3.get_file_info(path).size\n    print(f'{count:,} orders in {args.days} days')\n    for prefix, total in size.items():\n        if total:\n            print(f'  s3://{prefix}/  {args.days} objects  {total:>12,} bytes')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "**Each day is written twice**: as the CSV the shop exports, under the raw bucket, and as Parquet under the curated one, in a key that names the day as `dt=2026-10-01`. Then the totals: orders, objects and bytes per layer."}]}
```


## Two layers, the same rows

**The raw layer is what arrives and the curated layer is what is read.** The shop exports CSV,
because every program can write it and a person can open it; it lands in `quitanda-raw-prod` exactly
as it came. The curated layer holds the same orders as Parquet, a columnar format the next sections
take apart, in `quitanda-curated-prod`. Lesson 17 is the job that turns one into the other on AWS;
here `lake.py` writes both at once, so that the two hold the same rows and only the format differs.

The terminal is the one from lesson 1: moto running in its own terminal and the four lines of
lesson 1's "Your lab, in brief" typed in this one. moto starts empty, so the buckets come first:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-raw-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ python3 lake.py
755,511 orders in 31 days
  s3://quitanda-raw-prod/raw/orders/  31 objects    40,641,097 bytes
  s3://quitanda-curated-prod/orders/  31 objects    12,703,975 bytes
```

**755,511 orders, and the same orders take 40,641,097 bytes as CSV and 12,703,975 as Parquet**,
about a third. Nothing was lost on the way: the Parquet files hold every value the CSV files hold,
with their types, and the next section counts them in both and gets the same answer. The saving comes
from storing each column apart, where a day's column of hours, each a number between 7 and 23, is a run
of small values that compresses to almost nothing, and from Snappy, the compression PyArrow applies to
Parquet unless told otherwise. Lesson 19 measures the formats and the codecs against each other.

## What it looks like from S3

```
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod/orders/ | head -3
                           PRE dt=2026-10-01/
                           PRE dt=2026-10-02/
                           PRE dt=2026-10-03/
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod/orders/dt=2026-10-01/
2026-10-16 12:55:19     351356 orders.parquet
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders/dt=2026-10-01/
2026-10-16 12:55:18    1101292 orders.csv
ana@laptop:~/aws$ aws s3 cp s3://quitanda-raw-prod/raw/orders/dt=2026-10-01/orders.csv day.csv && head -4 day.csv
download: s3://quitanda-raw-prod/raw/orders/dt=2026-10-01/orders.csv to ./day.csv
"order_id","customer_id","hour","items","total_cents","payment","neighbourhood"
"o-1001-00001","c-151",7,4,8958,"pix","Ipiranga"
"o-1001-00002","c-22",7,25,44390,"pix","Santana"
"o-1001-00003","c-337",7,9,16407,"pix","Itaim Bibi"
```

**Each day is one prefix, and each prefix holds one object.** `aws s3 ls` groups the keys at the
slash after `dt=…`, which is lesson 1's folder that is not there, and inside `dt=2026-10-01/` there is
one file per layer: 351,356 bytes of Parquet against 1,101,292 of CSV for the same 1 October. The
CSV is text, as the shop wrote it. The Parquet is not readable with `head`, and that is the price of
it: a person can no longer look at the file, and a program has to know the format to read a single
value.

The names are the scheme lesson 1 drew up, `raw/orders/dt=2026-10-01/orders.csv`, with the date
written year first so that listing order is time order. They are also the names Athena's table
reads: the `LOCATION` in `orders.sql` is the curated prefix, and `PARTITIONED BY (dt string)` is
the `dt=` in every key.

