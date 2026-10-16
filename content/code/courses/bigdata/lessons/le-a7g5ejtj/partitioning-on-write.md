---
title: Partitioning on write
version: 1
---

**Every task of the stage that writes produces its own file, and with `partitionBy`, its own file
in every directory it has rows for.** So the number of files a job writes is decided by how its last
stage is partitioned, which is easy to forget because the program never mentions it. Save this as
`~/big/write_files.py`, which writes January's clicks three ways:

```schooling-example
{
  "language": "python",
  "file": "write_files.py",
  "parts": [
    {
      "code": "\"\"\"January's clicks written three ways, and the files each way left on disk.\"\"\"\nimport os\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"write files\").getOrCreate()\njanuary = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"day\") < \"2025-02-01\")\nprint(f\"{january.count():,} rows in January\")\n\n\n"
    },
    {
      "code": "def files(path):\n    sizes = [os.path.getsize(os.path.join(d, f))\n             for d, _, names in os.walk(path) for f in names\n             if f.startswith(\"part-\")]\n    return len(sizes), sum(sizes) / len(sizes) / 2**10\n\n\ndef written(label, df, partition_by=None):\n    path = f\"data/tmp/{label.split()[0]}\"\n    start = time.time()\n    writer = df.write.mode(\"overwrite\")\n    if partition_by:\n        writer = writer.partitionBy(partition_by)\n    writer.parquet(path)\n    n, kib = files(path)\n    print(f\"{label:34} {n:6} files of {kib:7.1f} KiB on average, {time.time() - start:5.1f} s\")\n\n\n",
      "note": "**Every file under a directory, counted and sized.** Spark's own `_SUCCESS` marker and the checksum files beside each part are left out."
    },
    {
      "code": "spark.conf.set(\"spark.sql.adaptive.enabled\", False)\nwritten(\"grouped, 200 partitions\", january.groupBy(\"visitor_id\").count())\nspark.conf.set(\"spark.sql.adaptive.enabled\", True)\n",
      "note": "**A grouping with adaptive execution off**: 200 shuffle partitions, so 200 tasks, so 200 files, however little each holds."
    },
    {
      "code": "written(\"scattered by day\", january.repartition(50), \"day\")\n",
      "note": "**Partitioned by day, after `repartition(50)`**: each of the 50 tasks holds rows of every day, and writes a file into every day's directory."
    },
    {
      "code": "written(\"gathered by day\", january.repartition(\"day\"), \"day\")\n",
      "note": "**Partitioned by day, after `repartition(\"day\")`**: all of a day's rows are in one task, so each day gets one file."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit write_files.py
WARNING: Using incubator modules: jdk.incubator.vector
2,038,357 rows in January
grouped, 200 partitions               200 files of    12.1 KiB on average,  14.8 s
scattered by day                     1550 files of    32.6 KiB on average,  24.4 s
gathered by day                        31 files of  1090.2 KiB on average,   5.2 s
```

**The first line is the job lesson 3 promised: two hundred files**, because a grouping with adaptive
execution off ends in 200 shuffle partitions, and each wrote 12 KiB. With adaptive execution on, the
same grouping would have been coalesced into a few partitions and written a few files; it is on by
default, and this is one of the reasons.

**The second is the one that fills a namenode.** `repartition(50)` deals each day's rows across all
50 tasks, and each task writes a file in each of the 31 day directories: 1,550 files of 33 KiB, where
31 would do. Read back, each of those files costs an open and a footer read, lesson 7's 4 MB open
cost, for 33 KiB of data. It was also the slowest write, at 24.4 seconds.

**The third gathers each day into one task first**, with `repartition("day")`, and writes 31 files of
1.1 MB in 5.2 seconds. That is the pattern to remember for a partitioned write: repartition by the
partition column, then `partitionBy` the same column.

It has the skew of this lesson built in, though. A day with ten times the traffic is a task with ten
times the rows and a file ten times larger. Two settings deal with that.
`spark.sql.files.maxRecordsPerFile` caps the rows in one file, so a large task writes several files
instead of one huge one. And a repartition by the partition column plus a salt,
`repartition("day", F.pmod(F.xxhash64("event_id"), F.lit(4)))`, spreads each day over four tasks and
four files, which is section 07's trick applied to a write.
