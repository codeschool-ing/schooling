---
title: Two actions, two jobs
version: 1
---

**Spark keeps nothing between actions unless it is told to.** Lesson 5 showed it with one
DataFrame counted twice: each `count` read the files again. That is the right default, because most
programs use each intermediate result once, and memory spent keeping it would be taken from the work.
It is the wrong default for a result used again and again, and this lesson is about telling the two
apart.

This program asks two questions of the same purchases, first as it is and then after `cache()`. It
uses `stages.py` from lesson 7 to show where each job's rows came from. Save it as `~/big/twice.py`:

```schooling-example
{
  "language": "python",
  "file": "twice.py",
  "parts": [
    {
      "code": "\"\"\"Two actions on the same filtered clicks, without and with a cache.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nfrom stages import report\n\nspark = SparkSession.builder.appName(\"twice\").getOrCreate()\n\n\n"
    },
    {
      "code": "def two_actions(purchases):\n    for label, action in [(\"count\", lambda: purchases.count()),\n                          (\"per device\", lambda: purchases.groupBy(\"device\").count().collect())]:\n        start = time.time()\n        action()\n        print(f\"{label:12} {time.time() - start:5.1f} s\")\n        report(spark)\n\n\nclicks = spark.read.parquet(\"data/silver/clicks\")\npurchases = clicks.where(F.col(\"kind\") == \"purchase\")\nprint(\"without a cache\")\ntwo_actions(purchases)\n\n",
      "note": "**The same two actions, timed**: how many purchases, and how many per device. Both start from the same filtered DataFrame."
    },
    {
      "code": "purchases.cache()\nprint(\"with a cache\")\ntwo_actions(purchases)\n",
      "note": "**`cache()` marks the DataFrame to be kept**, and keeps nothing yet: the first action that computes it fills the cache as a side effect."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit twice.py
WARNING: Using incubator modules: jdk.incubator.vector
without a cache
count          8.0 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    2     15     24.0          0.0           0.0        0.0     15.2
    4      1      0.0          0.0           0.0        0.0      0.1
per device     4.8 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    5     15     24.0          0.0           0.0        0.0     11.2
    7      1      0.0          0.0           0.0        0.0      0.1
with a cache
count          7.9 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    8     15     24.0          0.0           0.0        0.0     20.0
    9     15      0.0          0.0           0.0        0.0      0.7
   11      1      0.0          0.0           0.0        0.0      0.1
per device     1.2 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
   12     15      0.0          0.0           0.0        0.0      1.9
   14      1      0.0          0.0           0.0        0.0      0.1
```

**Without a cache, both actions read all 24 million rows from the Parquet files**, the `24.0` in the
first line of each report, and each paid the full read: 8.0 and 4.8 seconds.

**With a cache, the first action ran an extra stage, and its tasks worked longer**: 20.0
task-seconds against 15.2. It read the files, kept the purchases in the executors' memory as it went,
then counted what it had kept. That is the price of a cache: the first use pays for the copy. Here the
three executors absorbed it and the action took 7.9 seconds, about what it took without the cache;
on a busier cluster the extra work shows on the clock. **The second action read
nothing from the files**, `0.0` million rows in, because its rows came from memory, and took 1.2
seconds.

Two actions were already enough to win: 7.9 + 1.2 seconds against 8.0 + 4.8. Each further action
on the cached purchases would cost about a second instead of five or more.
