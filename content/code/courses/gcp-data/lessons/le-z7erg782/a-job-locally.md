---
title: The nightly job, run for real on your own Spark
version: 1
---

**A Dataproc cluster runs Apache Spark, and Apache Spark runs on a laptop.** No emulator imitates
Dataproc, and none is needed for the part that does the work: the program a cluster runs is an
ordinary PySpark program, and Spark's **local mode** runs it in one process on your own machine,
with a thread per processor standing in for the executors of the worker nodes. What follows is the
engine, not the service. No cluster is created here, nobody bills it, and the commands that would
hand the program to Dataproc are shown at the end of the section and were not run.

## Spark, from PyPI

**PySpark on PyPI carries all of Spark**, the Java and Scala libraries included, so one `pip
install` gives you `spark-submit` and everything it starts. It needs Java 17 or 21 to run, and the
`openjdk-21-jre-headless` package lesson 1 installed for the emulators is enough. In the terminal
you type into, with the virtual environment active:

```sh
pip install -q pyspark==4.2.0
```

The download is over 400 MB, and pip builds it into a wheel on your machine before installing,
which takes a minute. Then check what you have:

```
ana@laptop:~/gcp$ pip install -q pyspark==4.2.0
ana@laptop:~/gcp$ java -version 2>&1 | head -1
openjdk version "21.0.12.1" 2026-08-18
ana@laptop:~/gcp$ spark-submit --version 2>&1 | grep -E 'version [0-9]|Using Scala'
   /___/ .__/\_,_/_/ /_/\_\   version 4.2.0
Using Scala version 2.13.18, OpenJDK 64-Bit Server VM, 21.0.12.1
```

**Spark 4.2.0 on Java 21.** A Dataproc image fixes a Spark version of its own, which may be older
than this one; the program below uses nothing that changed between the two.

## A night of orders, generated

The orders are made up, by a generator short enough to read whole. It writes one day of Quitanda's
orders as CSV, under the same key layout the raw bucket uses, and seeding the random generator with
the date means the same day always gives the same orders. Save it as `make_orders.py`:

`make_orders.py`:

```python
import csv
import random
import sys
from pathlib import Path

dt = sys.argv[1]                       # the day, written 2026-10-29
rng = random.Random(dt)                # the same day always gives the same orders
out = Path(f'raw/orders/dt={dt}/orders.csv')
out.parent.mkdir(parents=True, exist_ok=True)

with out.open('w', newline='') as f:
    w = csv.writer(f, lineterminator='\n')
    w.writerow(['order_id', 'customer_id', 'placed_at', 'total_cents'])
    for n in range(1, 20001):
        minute = rng.randrange(24 * 60)
        w.writerow([f'ord-{dt.replace("-", "")}-{n:05d}',
                    f'c-{rng.randrange(1, 501):03d}',
                    f'{dt}T{minute // 60:02d}:{minute % 60:02d}:00-03:00',
                    rng.randrange(1500, 40000)])
print(out, out.stat().st_size, 'bytes')
```

```
ana@laptop:~/gcp$ python3 make_orders.py 2026-10-29
raw/orders/dt=2026-10-29/orders.csv 1135614 bytes
ana@laptop:~/gcp$ head -4 raw/orders/dt=2026-10-29/orders.csv
order_id,customer_id,placed_at,total_cents
ord-20261029-00001,c-334,2026-10-29T06:30:00-03:00,27139
ord-20261029-00002,c-238,2026-10-29T22:46:00-03:00,2140
ord-20261029-00003,c-460,2026-10-29T06:04:00-03:00,32246
```

**Twenty thousand orders from five hundred customers, in one file.** Each order has its own id, the
customer who placed it, the minute it was placed in São Paulo's time, and a total in cents, which
keeps money out of floating point as every lesson of this course does.

## The job

This is the nightly job: read one day of orders, count and add up per customer, and write the
result as Parquet. Save it as `daily_orders.py`:

```schooling-example
{"language": "python", "file": "daily_orders.py", "parts": [{"code": "import argparse\n\nfrom pyspark.sql import SparkSession, functions as F\n\nargs = argparse.ArgumentParser()\nargs.add_argument('--dt', required=True)\nargs.add_argument('--src', default='raw')\nargs.add_argument('--dst', default='curated')\na = args.parse_args()\n\n", "note": "**Where to read and where to write are arguments**, and they are the only thing that changes between this laptop and a cluster. Here they default to two directories under `~/gcp`; on Dataproc they are `gs://quitanda-raw-prod/raw` and `gs://quitanda-curated-prod`, read through the Cloud Storage connector every cluster comes with."}, {"code": "spark = SparkSession.builder.appName(f'daily-orders-{a.dt}').getOrCreate()\nspark.sparkContext.setLogLevel('ERROR')\n\n", "note": "The session is the program's handle on Spark. Nothing in it names a master or a number of machines: `spark-submit` decides that from outside, which is why the same file runs on two processors here and on forty on a cluster."}, {"code": "orders = (spark.read.option('header', True)\n          .schema('order_id STRING, customer_id STRING, placed_at TIMESTAMP, total_cents LONG')\n          .csv(f'{a.src}/orders/dt={a.dt}/'))\n\n", "note": "**The schema is written down rather than guessed.** Without it Spark reads every CSV column as text, or makes a second pass over the file to infer types, and a total in cents read as text sums as nothing at all."}, {"code": "daily = (orders.groupBy('customer_id')\n               .agg(F.count('*').alias('orders'),\n                    F.sum('total_cents').alias('total_cents')))\ndaily.write.mode('overwrite').parquet(f'{a.dst}/daily_orders/dt={a.dt}/')\n\n", "note": "One line of work: group by customer, count and add up. `groupBy` is where Spark shuffles, moving every order of a customer to the same task. `overwrite` makes the job safe to run twice for the same day, which a scheduler will one day do."}, {"code": "print(orders.count(), 'orders read,', daily.count(), 'customers written')\nspark.stop()\n", "note": "Two counts for the log. Each one is a second, small job over the same input: a Spark DataFrame is a plan, and nothing is computed until something asks for a result."}]}
```

**`spark-submit` is how a Spark program is started**, on a laptop and on a cluster alike: it starts
a driver, the process that plans the work, and asks the master it is given for executors to do it.
Here the master is `local[2]`, two threads in the driver's own process. Spark writes its progress to
standard error, so that goes to a file, and `time` says how long the whole thing took:

```
ana@laptop:~/gcp$ time spark-submit --master 'local[2]' daily_orders.py --dt 2026-10-29 2> spark.log
20000 orders read, 500 customers written

real	0m19.286s
user	0m22.798s
sys	0m2.458s
ana@laptop:~/gcp$ ls -a curated/daily_orders/dt=2026-10-29/
.
..
._SUCCESS.crc
.part-00000-fe268669-4205-4afd-90f8-0e02a2940427-c000.snappy.parquet.crc
_SUCCESS
part-00000-fe268669-4205-4afd-90f8-0e02a2940427-c000.snappy.parquet
ana@laptop:~/gcp$ grep -c . spark.log
50
```

**Most of those seconds are Spark starting, not Spark working.** Twenty thousand rows are nothing to
it; the Java virtual machine, the session and the two counts at the end are what the clock measured,
and the fifty lines Spark wrote about doing so are in `spark.log`. That fixed cost is paid by every
job on every cluster, and it is one reason to batch work into one nightly run rather than many
small ones.

**The output is a directory, not a file.** Each task that wrote a share of the result writes its
own `part-` file, and here there is one, because Spark's adaptive execution saw that five hundred
rows did not need the two hundred shuffle partitions it starts with and merged them before writing.
`_SUCCESS` is the empty marker Spark leaves when every task has finished. A reader that lists the
directory before `_SUCCESS` appears may find half a result, which is why whatever follows this job
waits for the marker, or for the job, rather than for the first file. The two files whose names
start with a dot are checksums that Hadoop's local file system writes beside every file; they are
an artefact of writing to a disk, and a job writing to `gs://` through the connector does not make
them.

## Check it with a second engine

**A result is believed when something else agrees with it.** DuckDB, the engine this course uses
for BigQuery's SQL, can read both the CSV that went in and the Parquet that came out. Save this as
`check_daily.py`:

`check_daily.py`:

```python
import sys

import duckdb

dt = sys.argv[1]
print(duckdb.sql(f"SELECT count(*) AS orders, sum(total_cents) AS total_cents "
                 f"FROM 'raw/orders/dt={dt}/orders.csv'"))
print(duckdb.sql(f"SELECT count(*) AS customers, sum(orders) AS orders, sum(total_cents) AS total_cents "
                 f"FROM 'curated/daily_orders/dt={dt}/*.parquet'"))
```

```
ana@laptop:~/gcp$ python3 check_daily.py 2026-10-29
┌────────┬─────────────┐
│ orders │ total_cents │
│ int64  │   int128    │
├────────┼─────────────┤
│  20000 │   412139132 │
└────────┴─────────────┘

┌───────────┬────────┬─────────────┐
│ customers │ orders │ total_cents │
│   int64   │ int128 │   int128    │
├───────────┼────────┼─────────────┤
│       500 │  20000 │   412139132 │
└───────────┴────────┴─────────────┘
```

**The two engines agree to the cent.** The orders counted in the Parquet add up to the rows of the
CSV, and so do the totals, which is the check a pipeline should make on every night it runs: rows
in, rows out, money in, money out.

## Where the files live on Dataproc

**On a cluster, the input and the output are objects in Cloud Storage.** Put them where the cluster
would find them, in the emulator from lesson 1, running in its own terminal:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-raw-prod/...
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ gcloud storage cp raw/orders/dt=2026-10-29/orders.csv gs://quitanda-raw-prod/raw/orders/dt=2026-10-29/orders.csv
Copying file://raw/orders/dt=2026-10-29/orders.csv to gs://quitanda-raw-prod/raw/orders/dt=2026-10-29/orders.csv
  

ana@laptop:~/gcp$ gcloud storage cp daily_orders.py gs://quitanda-raw-prod/jobs/daily_orders.py
Copying file://daily_orders.py to gs://quitanda-raw-prod/jobs/daily_orders.py
  

ana@laptop:~/gcp$ gcloud storage cp curated/daily_orders/dt=2026-10-29/* gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/
Copying file://curated/daily_orders/dt=2026-10-29/_SUCCESS to gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/_SUCCESS
Copying file://curated/daily_orders/dt=2026-10-29/part-00000-fe268669-4205-4afd-90f8-0e02a2940427-c000.snappy.parquet to gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/part-00000-fe268669-4205-4afd-90f8-0e02a2940427-c000.snappy.parquet
  
.

Average throughput: 65.8kiB/s
ana@laptop:~/gcp$ gcloud storage ls -r gs://quitanda-curated-prod/
gs://quitanda-curated-prod/:

gs://quitanda-curated-prod/daily_orders/:

gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/:
gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/_SUCCESS
gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/part-00000-fe268669-4205-4afd-90f8-0e02a2940427-c000.snappy.parquet
```

**The same `dt=` layout, in a bucket instead of a directory**, and the program as an object beside
the raw data, where a job can name it. The shell's `*` does not match names that start with a dot,
so the two checksum files stayed on the laptop. This is the whole of what changes on Dataproc: the program
is given `gs://` paths instead of directories, and the cluster's Cloud Storage connector reads and
writes them.

Handing the program to a cluster is one command. **It was not run here**, because there is no
Dataproc to receive it, and on a real project it needs the cluster of the previous sections to
exist:

```sh
gcloud dataproc jobs submit pyspark gs://quitanda-raw-prod/jobs/daily_orders.py \
  --cluster=quitanda-spark --region=southamerica-east1 \
  -- --dt 2026-10-29 --src gs://quitanda-raw-prod/raw --dst gs://quitanda-curated-prod
```

**Everything after the lone `--` goes to the program**, not to `gcloud`, which is how the three
arguments of `daily_orders.py` reach it. Dataproc runs `spark-submit` on the master with the
cluster's own YARN as the master URL, streams the driver's output back to the terminal, and keeps
a copy of it in the cluster's staging bucket. The job then has an id and a state, `DONE` or
`ERROR`, that `gcloud dataproc jobs describe` reads back. None of that appears here; what this
section showed is the part that does not depend on Google, the program and its result.
