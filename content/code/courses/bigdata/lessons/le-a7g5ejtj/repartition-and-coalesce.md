---
title: Repartition and coalesce
version: 1
---

**A program can set the number of partitions itself, in two ways that cost very different
amounts.** `repartition(n)` shuffles every row into n new partitions. `coalesce(n)` merges the
existing partitions into n without a shuffle: each executor combines what it already holds, and no
row crosses the network. Lesson 7 named both; this section measures what each produces. Save this as
`~/big/repartition.py`:

```schooling-example
{
  "language": "python",
  "file": "repartition.py",
  "parts": [
    {
      "code": "\"\"\"Four ways the same clicks can be cut into partitions, and what each one costs.\"\"\"\nimport contextlib\nimport io\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"repartition\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\n\n\n"
    },
    {
      "code": "def sizes(label, df):\n    rows = [r[\"count\"] for r in df.groupBy(F.spark_partition_id()).count().collect()]\n    plan = io.StringIO()\n    with contextlib.redirect_stdout(plan):\n        df.explain()\n    moved = \"shuffle\" if \"Exchange\" in plan.getvalue() else \"no shuffle\"\n    print(f\"{label:24} {df.rdd.getNumPartitions():4} {len(rows):10}\"\n          f\" {min(rows):12,} {max(rows):12,}   {moved}\")\n\n\nprint(\"                   partitions  non-empty     min rows     max rows\")\nsizes(\"as read\", clicks)\n",
      "note": "**How many rows each partition holds**: `spark_partition_id()` is the number of the partition a row is in, so grouping by it counts the rows of every non-empty partition."
    },
    {
      "code": "sizes(\"coalesce(4)\", clicks.coalesce(4))\n",
      "note": "**`coalesce(4)` merges neighbouring partitions without moving a row between executors**, so it costs nothing and the pieces are as uneven as what was merged."
    },
    {
      "code": "sizes(\"repartition(4)\", clicks.repartition(4))\n",
      "note": "**`repartition(4)` shuffles every row**, dealing them out in turn, so the four pieces come out equal."
    },
    {
      "code": "sizes('repartition(\"device\")', clicks.repartition(\"device\"))\n",
      "note": "**`repartition(\"device\")` shuffles by the hash of a column**: every row of a device lands in the same partition, and there are only three devices."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit repartition.py
WARNING: Using incubator modules: jdk.incubator.vector
                   partitions  non-empty     min rows     max rows
as read                    15         15       65,753    1,709,594   no shuffle
coalesce(4)                 4          4    5,128,766    6,838,355   no shuffle
repartition(4)              4          4    5,999,997    6,000,002   shuffle
repartition("device")       3          2    7,921,900   16,078,100   shuffle
```

**As read, the partitions are uneven**, from 65,753 rows to 1.7 million. The reader packs files into
partitions of up to 128 MB, and the last one gets whatever is left over.

**`coalesce(4)` cost nothing and kept the unevenness**: four partitions of 5.1 to 6.8 million rows,
made by gluing neighbours together. **`repartition(4)` cost a shuffle of all 24 million rows and
produced four partitions within five rows of each other**, because rows without a key are dealt out
in turn.

**`repartition("device")` is the one to be careful with.** Partitioning by a column puts every row of
a value in the same partition, so the number of partitions that can hold anything is at most the
number of values: three devices, three busy tasks, whatever the cluster's size. Here it was worse.
Adaptive execution merged the 200 shuffle partitions into 3, and two of the three devices hashed into
the same one, so one partition stayed empty and another held 16 million rows. Partitioning by a key is
right when the next step needs each key's rows together, and only then.

Which one to use follows from what the next step needs:

- **Fewer, larger partitions before a write, with no need for balance:** `coalesce`. It is free.
  But `coalesce(1)` makes the whole stage before it run as one task, because there is no shuffle to
  separate them; when one file is truly wanted, `repartition(1)` keeps the work before it parallel.
- **Even partitions, or more of them:** `repartition(n)`. `coalesce` can only reduce the number.
- **Rows of a key together, for a write partitioned by that key or a repeated join on it:**
  `repartition(column)`. Next section.
