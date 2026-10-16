---
title: Seven layouts of one month
version: 1
---

**Two decisions are made when a file is written, and every query pays for them afterwards**: the
format, which arranges the bytes inside each file, and the partitioning, which arranges the files
across the keys. Lesson 15 met both with one layout of each. This lesson takes the same 755,511
orders, writes them seven more ways, and asks each layout the same questions, so that the only
thing that changes between two numbers is the arrangement.

## A row layout and a column layout

**A CSV file is written a row at a time, and so it can only be read a row at a time.** To find the
payment of every order, a reader goes through every line, because nothing says where the fifth field
of the next line starts. That is what made lesson 15's CSV question read 40,641,097 bytes for two
columns.

**Parquet and ORC are written a column at a time, in blocks.** Parquet cuts a file into *row groups*,
each holding some thousands or millions of rows, and inside each group stores every column as a
*column chunk* of its own, compressed on its own. ORC does the same with different names: *stripes*
instead of row groups, *streams* instead of chunks. Both end with a footer that says where every
block starts and what range of values it holds, which is how a reader reads two columns of seven, and
both carry their schema and their types in the file. Lesson 15's `footer.py` printed one such footer;
this lesson reads more of them.

## The program

Save it as `~/aws/layouts.py`. It reads the curated layer that `lake.py` writes and needs nothing
else:

```schooling-example
{"language": "python", "file": "layouts.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"layouts.py: the curated month written seven more ways, to compare their bills.\n\n    python3 layouts.py\n\nReads s3://quitanda-curated-prod/orders/, which lake.py wrote, and writes each\nlayout under s3://quitanda-curated-prod/layouts/NAME/dt=2026-10-01/... with the\nsame rows. Then it prints how many objects and bytes each layout came to.\n\"\"\"\n", "note": "Seven layouts of the same 755,511 orders, all derived from the curated layer, so the only thing that differs between them is how the bytes are arranged."}, {"code": "import random\n\nimport pyarrow.csv as csv\nimport pyarrow.fs as fs\nimport pyarrow.orc as orc\nimport pyarrow.parquet as pq\n\nfrom lake import CURATED, filesystem\n\n", "note": "PyArrow writes all four formats here: CSV, Parquet, and ORC through `pyarrow.orc`."}, {"code": "OUT = 'quitanda-curated-prod/layouts'\n\n\n", "note": "Every layout lives under its own name in `layouts/`, partitioned by `dt` like the original, so `ask.py -t` can point at any of them."}, {"code": "def write_day(s3, day, table):\n    base = f'dt={day}'\n    with s3.open_output_stream(f'{OUT}/csv-gzip/{base}/orders.csv.gz', compression='gzip') as f:\n        csv.write_csv(table, f, csv.WriteOptions(quoting_style='needed'))\n    pq.write_table(table, f'{OUT}/parquet-none/{base}/orders.parquet', filesystem=s3,\n                   compression='none')\n    pq.write_table(table, f'{OUT}/parquet-zstd/{base}/orders.parquet', filesystem=s3,\n                   compression='zstd')\n    with s3.open_output_stream(f'{OUT}/orc-zstd/{base}/orders.orc') as f:\n        orc.write_table(table, f, compression='zstd')\n", "note": "**The format and the codec, one day at a time.** The CSV is the raw layer's, compressed with gzip on its way to S3. Parquet is written with no compression and with zstd, beside the curated layer's Snappy. ORC is the other columnar format, compressed with zstd."}, {"code": "    pq.write_table(table, f'{OUT}/groups/{base}/orders.parquet', filesystem=s3,\n                   row_group_size=2_000)\n    shuffled = list(range(table.num_rows))\n    random.Random(day).shuffle(shuffled)\n    pq.write_table(table.take(shuffled), f'{OUT}/groups-shuffled/{base}/orders.parquet',\n                   filesystem=s3, row_group_size=2_000)\n", "note": "**Row groups of 2,000 rows**, twice: once in the order of the day, sorted by hour, and once shuffled, with the same rows. The difference is only the order, and it decides what each group's minimum and maximum say."}, {"code": "    step = -(-table.num_rows // 96)\n    for k in range(96):\n        pq.write_table(table.slice(k * step, step), f'{OUT}/small-files/{base}/part-{k:02d}.parquet',\n                       filesystem=s3)\n\n\n", "note": "**Small files**: each day cut into 96 Parquet files of equal size, about what a writer that flushes every quarter of an hour leaves behind."}, {"code": "def main():\n    s3 = filesystem()\n    for d in range(1, 32):\n        day = f'2026-10-{d:02d}'\n        write_day(s3, day, pq.read_table(f'{CURATED}/dt={day}/orders.parquet', filesystem=s3))\n    totals = {}\n    for f in s3.get_file_info(fs.FileSelector(OUT, recursive=True)):\n        if f.is_file:\n            name = f.path.split('/')[2]\n            objects, size = totals.get(name, (0, 0))\n            totals[name] = (objects + 1, size + f.size)\n    for name, (objects, size) in totals.items():\n        print(f'  {name:<16}{objects:>6} objects {size:>13,} bytes')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "The 31 days, then a listing of `layouts/` added up per layout: how many objects, how many bytes."}]}
```

The terminal is the one from lesson 1: moto running in its own terminal and the four lines of
lesson 1's "Your lab, in brief" typed in this one. moto starts empty, so the lake comes first. Then come the seven layouts, the slowest command in this course, because the last layout alone is 2,976 objects:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-raw-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ python3 lake.py
755,511 orders in 31 days
  s3://quitanda-raw-prod/raw/orders/  31 objects    40,641,097 bytes
  s3://quitanda-curated-prod/orders/  31 objects    12,703,975 bytes
```

```
ana@laptop:~/aws$ python3 layouts.py
  csv-gzip            31 objects     8,421,323 bytes
  groups-shuffled     31 objects    16,278,695 bytes
  groups              31 objects    15,063,805 bytes
  orc-zstd            31 objects     6,871,300 bytes
  parquet-none        31 objects    24,667,617 bytes
  parquet-zstd        31 objects     7,433,857 bytes
  small-files       2976 objects    22,068,273 bytes
```

**The same orders take anything from 40,641,097 bytes to 6,871,300.** Three things set the size, and
the list above separates them:

- **the arrangement**: Parquet with no compression at all, 24,667,617 bytes, is already smaller than
  the CSV, because a number is stored as a number and not as its digits, and a column of four payment
  methods is stored as a dictionary of four words and a small code per row;
- **the codec**: the same Parquet is 12,703,975 bytes with Snappy, the curated layer's, and 7,433,857
  with zstd. Gzip takes the CSV down to 8,421,323, which is the next section's subject;
- **the cutting**: the row groups and the 96 small files a day add footers, dictionaries and
  statistics to every piece, and 2,976 small files come to 22,068,273 bytes, 1.74 times the one file
  a day they hold.

**ORC came out smallest, 6,871,300 bytes against Parquet's 7,433,857 with the same codec.** That is a
difference between two good formats on this data, and not a reason to choose either. Athena, Spark,
Glue and Redshift Spectrum read both; PyArrow, DuckDB and most tools outside the Hadoop world default
to Parquet, and ORC is strongest where Hive is. A lake picks one and stays with it, because the
decision that matters was the one before: columns rather than rows.

