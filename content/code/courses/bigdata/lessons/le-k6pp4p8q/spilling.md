---
title: Spilling, and when it does not matter
version: 1
---

**When a task's data does not fit in its execution memory, it writes some of it to disk and carries
on.** That is a *spill*, and it is how Spark survives tasks larger than memory without failing:
a sort sorts what fits, writes the sorted run to disk, sorts the next, and merges the runs at the end.
Lesson 4's `Spilled Records` were MapReduce doing the same.

A sort of every event is the clearest way to cause one. Save this as `~/big/spill.py`:

```schooling-example
{
  "language": "python",
  "file": "spill.py",
  "parts": [
    {
      "code": "\"\"\"Sort every event by visitor and time, with 200 shuffle partitions and with 3.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\n\nfrom stages import report\n\nspark = SparkSession.builder.appName(\"spill\").getOrCreate()\n"
    },
    {
      "code": "spark.conf.set(\"spark.sql.adaptive.enabled\", False)\nclicks = spark.read.parquet(\"data/silver/clicks\")\n\n",
      "note": "Adaptive execution off, so that the number of partitions asked for is the number used."
    },
    {
      "code": "for n in (200, 3):\n    spark.conf.set(\"spark.sql.shuffle.partitions\", n)\n    start = time.time()\n    clicks.orderBy(\"visitor_id\", \"ts\").write.mode(\"overwrite\").parquet(\"data/tmp/sorted\")\n    print(f\"{n} partitions: {time.time() - start:.0f} s\")\n    report(spark)\n",
      "note": "**The same sort twice.** With 3 partitions, each of the three reduce tasks has to sort a third of 24 million rows inside about 280 MB of memory."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit spill.py
WARNING: Using incubator modules: jdk.incubator.vector
200 partitions: 61 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    2     15     24.0          0.0           0.0        0.0     32.5
    3     15     24.0        592.8           0.0        0.0     35.6
    4    200      0.0          0.0         592.8        0.0     90.8
3 partitions: 41 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    5     15     24.0          0.0           0.0        0.0     17.4
    6     15     24.0        593.8           0.0        0.0     24.1
    7      3      0.0          0.0         593.8      557.2     69.2
```

**With 200 partitions, nothing spilled. With 3, the reduce stage spilled 557.2 MiB of its
593.8 MiB.** Each of the three tasks had a third of 24 million rows to sort and about 280 MiB to do it
in, so most of what it read went to disk and came back.

**And yet the run with 3 partitions finished first.** 41 seconds against 61, and its reduce
stage took fewer task-seconds than the 200-task one, 69.2 against 90.8. On this machine, spilling went to a fast
local disk the operating system could cache, while 200 tasks each paid their fixed cost and each
wrote its own Parquet file. Spilling is a cost, not a failure, and here it was the smaller cost.

That is the honest version of the usual advice, which says spilling is always bad. **Spilling is
bad when the disk is slow or full, when it repeats** (a task that spills, merges, and spills again),
**or when it is the symptom of one task far larger than the rest**, lesson 8's subject. It is
harmless when a few tasks spill a little to fast local disks. The stage's `spill` number is the
thing to watch, and a large number next to a long task time is the thing to fix.

The fixes, in the order to try them: more partitions, so each task has less; less data in each row,
by selecting columns before a wide operation; and more memory per task, by giving executors more
memory or fewer cores. Lesson 14 prices the last one.
