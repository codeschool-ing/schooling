---
title: Partitions, statistics and the files a question opens
version: 1
---

**A partition column turns a filter into a list of folders.** Written with `partition_by=["dt"]`,
the table becomes one folder per day, `dt=2026-10-15/` and its neighbours, and the log records each
file's day beside its path. A question about one day opens one folder and never lists the others.
That is the first of two ways a Delta table avoids reading what a question does not need; the
second is the statistics in each `add`, which work without any folders at all.

This section writes October four ways and asks each one the same two questions. Save the program in
`~/azure`, beside `orders.py` and `table.py`:

`layouts.py`:

```python
"""layouts.py: the same October written four ways, to compare what each costs to read."""
import pyarrow.compute as pc
from deltalake import write_deltalake

from orders import october

month = october()
days = sorted(set(month["dt"].to_pylist()))

write_deltalake("lake/one", month)
write_deltalake("lake/by_day", month, partition_by=["dt"])

for day in days:
    write_deltalake("lake/daily", month.filter(pc.equal(month["dt"], day)), mode="append")

for day in days:
    one = month.filter(pc.equal(month["dt"], day))
    for hour in range(7, 24):
        write_deltalake("lake/hourly", one.filter(pc.equal(one["hour"], hour)),
                        partition_by=["dt"], mode="append")
```

**`one` is the month in one write**, as in the previous section. **`by_day`** is partitioned by
day, in one write. **`daily`** is not partitioned, and is written one day at a time, as a nightly
job would. **`hourly`** is partitioned by day and written one hour at a time, as a job that runs
every hour would, which is 527 commits:

```
ana@laptop:~/azure$ time python layouts.py

real	0m28.724s
user	0m19.605s
sys	0m8.122s
ana@laptop:~/azure$ for t in one by_day daily hourly; do python table.py lake/$t files; done
version 0: 1 files, 1,205,188 bytes, 98,727 rows in the log
version 0: 31 files, 1,879,174 bytes, 98,727 rows in the log
version 30: 31 files, 1,888,288 bytes, 98,727 rows in the log
version 526: 527 files, 3,040,868 bytes, 98,727 rows in the log
ana@laptop:~/azure$ ls lake/by_day | head -4
_delta_log
dt=2026-10-01
dt=2026-10-02
dt=2026-10-03
ana@laptop:~/azure$ python -c "import glob, pyarrow.parquet as pq; print(pq.read_schema(glob.glob('lake/by_day/dt=2026-10-15/*.parquet')[0]).names)"
['order_id', 'hour', 'customer_id', 'neighbourhood', 'payment', 'total_cents']
```

**The same 98,727 orders take 1,205,188 bytes in one file and 3,040,868 in 527.** Every Parquet file
carries a footer, a schema and a dictionary per column, and small files carry them more often per
row. The partitioned files have no `dt` column inside them at all: the day is in the folder's name
and in the log, and a reader puts it back.

## Counting what a question reads

**Serverless engines bill by the bytes a query reads**: Synapse's serverless SQL pool of lesson 16
per terabyte processed, and Fabric in capacity units that grow with the work. So the useful
measurement of a layout is what a question reads from it, and this program counts it. It hands
DuckDB the table through a file system that counts every file opened and every byte read:

```schooling-example
{"language": "python", "file": "measure.py", "parts": [
{"code": "\"\"\"measure.py: ask a Delta table a question and count the bytes read from disk.\n\n    python measure.py PATH \"SQL over a table called orders\"\n\"\"\"\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.fs as fs\nfrom deltalake import DeltaTable\n\n\n", "note": "**DuckDB answers, and the program counts what it had to read.** Serverless SQL engines bill by the data a query reads, so the count is the number that would be on the bill."},
{"code": "class Counting(fs.FileSystemHandler):\n    \"\"\"The local disk, seen through a tap that counts files opened and bytes read.\"\"\"\n\n    def __init__(self, root):\n        self.disk = fs.SubTreeFileSystem(root, fs.LocalFileSystem())\n        self.opened, self.bytes = set(), 0\n\n", "note": "A PyArrow file system written in Python. It hands every request to the real disk, rooted at the table's folder, and keeps two counts on the way."},
{"code": "    def open_input_file(self, path):\n        self.opened.add(path)\n        inner, tap = self.disk.open_input_file(path), self\n\n        class Tap:\n            closed = False\n\n            def read(self, n=-1):\n                data = inner.read(n)\n                tap.bytes += len(data)\n                return data\n\n            def seek(self, offset, whence=0): return inner.seek(offset, whence)\n            def tell(self): return inner.tell()\n            def size(self): return inner.size()\n            def close(self): inner.close()\n            def readable(self): return True\n            def seekable(self): return True\n            def writable(self): return False\n\n        return pa.PythonFile(Tap(), mode=\"r\")\n\n", "note": "**The tap.** Opening a file records its name, and every `read` adds what it returned to the byte count. A Parquet reader jumps around a file, to the footer at the end and then to the column chunks it needs, so `seek` and `tell` are passed straight through."},
{"code": "    def open_input_stream(self, path): return self.open_input_file(path)\n    def get_file_info(self, paths): return self.disk.get_file_info(paths)\n    def get_file_info_selector(self, selector): return self.disk.get_file_info(selector)\n    def get_type_name(self): return \"counting\"\n    def normalize_path(self, path): return path\n    def __eq__(self, other): return self is other\n    def __ne__(self, other): return self is not other\n\n    def _refuse(self, *args): raise NotImplementedError(\"read-only\")\n    create_dir = delete_dir = delete_dir_contents = delete_root_dir_contents = _refuse\n    delete_file = move = copy_file = open_output_stream = open_append_stream = _refuse\n\n\n", "note": "The rest of the interface a file system must have. Reading asks only for the first five; the writing half refuses, because measuring a question must never change the table."},
{"code": "path, question = sys.argv[1], sys.argv[2]\ntap = Counting(path)\ntable = DeltaTable(path)\norders = table.to_pyarrow_dataset(filesystem=fs.PyFileSystem(tap))\nduckdb.sql(question).show()\nprint(f\"read {tap.bytes:,} bytes from {len(tap.opened)} of {len(table.file_uris())} files\")\n", "note": "**`deltalake` reads the log and builds the dataset; DuckDB reads the files through the tap.** DuckDB finds `orders` in the program by its name, pushes the question's columns and filters down to the dataset, and the dataset skips any file whose partition or statistics rule it out. What is printed last is what crossed the tap."}
]}
```

The question about the month, October's sales by payment, asked of the one big file and of the
31 days:

```
ana@laptop:~/azure$ python measure.py lake/one "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │  42487 │ 6989795.82 │
│ credit       │  32725 │ 5364244.14 │
│ debit        │  14202 │  2317012.7 │
│ meal-voucher │   9313 │ 1538313.03 │
└──────────────┴────────┴────────────┘

read 396,833 bytes from 1 of 1 files
ana@laptop:~/azure$ python measure.py lake/by_day "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC" | tail -1
read 2,442,170 bytes from 31 of 31 files
```

**The one file was read in part, 396,833 of its 1,205,188 bytes**: two columns of seven, which is the
column format doing its work. **The 31 days were read whole and then some, 2,442,170 bytes from
1,879,174 on disk.** Each daily file is about 60 KB, smaller than the first piece PyArrow reads from
the end of a file to find its footer, so that first read fetched every file whole, and the column
chunks were then fetched again. Partitioning gave this question nothing to skip and only more files
to open.

Now the question about one day:

```
ana@laptop:~/azure$ python measure.py lake/one "SELECT count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15'"
┌────────┬──────────┐
│ orders │  reais   │
│ int64  │  double  │
├────────┼──────────┤
│   2999 │ 493412.7 │
└────────┴──────────┘

read 372,157 bytes from 1 of 1 files
ana@laptop:~/azure$ python measure.py lake/by_day "SELECT count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15'" | tail -1
read 73,813 bytes from 1 of 31 files
ana@laptop:~/azure$ python measure.py lake/daily "SELECT count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15'" | tail -1
read 74,167 bytes from 1 of 31 files
```

**The partitioned table opened one folder of 31 and read 73,813 bytes, a fifth of what the one file
cost.** The one file had to be read through its `dt` column to find the 2,999 orders of the
fifteenth, because a single file holds every day and its statistics say only "1 to 31".

**`daily` did as well with no partitions at all, 74,167 bytes from 1 file of 31.** Each of its files
was written by one night's append, so each file's statistics in the log say its smallest and largest
`dt` are the same day, and the reader skipped the other thirty files on that alone. This is called
data skipping, and it is why a table that is written in the order it is queried needs fewer
partitions than people expect. Databricks' documentation goes further and advises against
partitioning tables under a terabyte at all, leaving the skipping to the statistics.

## A delete in a partitioned table

```
ana@laptop:~/azure$ python table.py lake/by_day delete "order_id = '1015-00042'"
1 deleted, 2,998 copied into 1 new file(s); now version 1
```

**The same order, deleted from the partitioned table, copied 2,998 rows instead of 98,726.** The
order's day was the only file that could hold it, so only that day was rewritten. A table whose
rows are corrected, cancelled or erased for privacy reasons pays for every delete in rows copied,
and the partitioning, or the sorting, decides how many.

## Choosing the column

**A partition column should be one that most questions filter on and that has few values.** For
Quitanda that is `dt`: nearly every question names a period, and a month has 31 values. A
`customer_id` partition would be one folder per customer, thousands of them, each holding a file of
a few kilobytes, and every question about a day would open all of them. **The next section
measures what too many files cost**, with the `hourly` layout, which is the same failure produced
by writing too often rather than by cutting too finely.
