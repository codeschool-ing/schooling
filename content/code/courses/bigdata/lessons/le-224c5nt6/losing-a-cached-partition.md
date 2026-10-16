---
title: Losing a cached partition
version: 1
---

**A cached partition lives in one executor's memory, and goes when the executor goes.** Lesson 2
said so and left the demonstration for here. Nothing is lost for good: the partition's lineage, the
steps that made it, is still known to the driver, and the next action that needs it runs those steps
again. Save this as `~/big/lost.py`:

```schooling-example
{
  "language": "python",
  "file": "lost.py",
  "parts": [
    {
      "code": "\"\"\"A cached DataFrame loses an executor, and the next action rebuilds what was lost.\"\"\"\nimport getpass\nimport json\nimport subprocess\nimport time\nimport urllib.request\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"lost\").getOrCreate()\nsc = spark.sparkContext\n\n\ndef cached():\n    url = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/storage/rdd\"\n    r = json.load(urllib.request.urlopen(url))[0]\n    return f\"{r['numCachedPartitions']} of {r['numPartitions']} partitions cached\"\n\n\ndef timed_count(df):\n    start = time.time()\n    df.count()\n    return f\"count in {time.time() - start:4.1f} s\"\n\n\nclicks = spark.read.parquet(\"data/silver/clicks\").cache()\nprint(\"first count: \", timed_count(clicks), \"|\", cached())\nprint(\"second count:\", timed_count(clicks), \"|\", cached())\n"
    },
    {
      "code": "subprocess.run([\"pkill\", \"-9\", \"-o\", \"-u\", getpass.getuser(), \"-f\", \"CoarseGrainedExecutorBackend\"],\n               check=True)\ntime.sleep(10)\nprint(\"after the kill:              |\", cached())\n",
      "note": "**One executor is killed**, the oldest of the three: `pkill -o` picks the process that started first, and `-u` keeps it to your own processes. Its cached partitions were in its memory and go with it."
    },
    {
      "code": "print(\"third count: \", timed_count(clicks), \"|\", cached())\nprint(\"fourth count:\", timed_count(clicks), \"|\", cached())\n",
      "note": "**The next action finds partitions missing from the cache** and recomputes them from their lineage, which here is a read of the Parquet files, then caches them again."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit lost.py
WARNING: Using incubator modules: jdk.incubator.vector
first count:  count in 37.6 s | 15 of 15 partitions cached
second count: count in  0.6 s | 15 of 15 partitions cached
02:27:54 ERROR TaskSchedulerImpl: Lost executor 0 on 127.0.0.1: Command exited with code 137
02:27:54 WARN BlockManagerMasterEndpoint: No more replicas available for rdd_8_8!
02:27:54 WARN BlockManagerMasterEndpoint: No more replicas available for rdd_8_13!
02:27:54 WARN BlockManagerMasterEndpoint: No more replicas available for rdd_8_2!
02:27:54 WARN BlockManagerMasterEndpoint: No more replicas available for rdd_8_5!
02:27:54 WARN BlockManagerMasterEndpoint: No more replicas available for rdd_8_11!
after the kill:              | 10 of 15 partitions cached
third count:  count in 14.6 s | 15 of 15 partitions cached
fourth count: count in  0.5 s | 15 of 15 partitions cached
```

**The killed executor held five of the fifteen partitions**, and the driver named each one as it
noticed: `rdd_8_2` is partition 2 of the cached dataset, and `No more replicas available` says no
other executor had a copy. The worker started a new executor in its place, as lesson 2 showed.

**The third count found ten partitions in the cache and five missing**, read those five from the
Parquet files, cached them again, and took 14.6 seconds, well under half of the first fill, because a
third of the data was missing. The fourth was back to half a second. The answer was right every time; what
the lost executor cost was time, once.

That is the trade a cache makes, and it is usually the right one. **When recomputing is expensive
enough to matter**, an hour-long join behind the cache, the `_2` levels keep each partition on two
executors, at twice the memory, so that losing one costs nothing but a lookup. And when the lineage
itself is the problem, the next two sections apply.
