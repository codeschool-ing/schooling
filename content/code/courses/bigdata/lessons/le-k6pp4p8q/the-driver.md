---
title: Running the driver out of memory
version: 1
---

**Executors spill; the driver does not.** Anything a program brings back to the driver, with
`collect`, `toPandas` or a `show` of many rows, has to fit in the driver's memory at once, and there
is no disk to fall back on. The most common way to kill a Spark program is to ask for the whole result
in a variable. Save this as `~/big/collect_all.py`:

```schooling-example
{
  "language": "python",
  "file": "collect_all.py",
  "parts": [
    {
      "code": "\"\"\"Bring every event to the driver.\"\"\"\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"collect all\").getOrCreate()\n"
    },
    {
      "code": "rows = spark.read.parquet(\"data/silver/clicks\").collect()\nprint(len(rows), \"rows\")\n",
      "note": "**`collect` sends every row of the result to the driver**, which has to hold them all at once."
    }
  ]
}
```

Spark has a guard for this, `spark.driver.maxResultSize`, the most the tasks' results may add up to,
1 GB by default. Run with the guard lowered to 100 MB, so that it trips quickly and cleanly, and with
`grep` keeping the first error line of a long stack trace:

```
ana@lab:~/big$ spark-submit --conf spark.driver.maxResultSize=100m collect_all.py 2>&1 | grep -m 1 ERROR
01:13:24 ERROR TaskSetManager: Total size of serialized results of 3 tasks (128.2 MiB) is bigger than spark.driver.maxResultSize (100.0 MiB)
```

**Three tasks' results had already reached 128.2 MiB when the job was stopped**, out of 15, so all of
them would have been about 640 MiB of serialised rows, more in Python objects once unpacked, into a
driver whose Spark share is 434 MiB. The guard turned a crash into an error message. Without it, or
with it set higher than the driver can hold, the driver runs out of memory and the whole application
dies, which is lesson 2's one unrecoverable failure.

**The fix is not more driver memory.** It is not to bring the data to the driver: write it with
`write.parquet`, which each executor does for its own partitions, or aggregate on the cluster and
collect the small result. `show(20)`, `take(20)` and `limit(20).collect()` bring back only what they
show. A result too large for the driver is a result that should go to a file.
