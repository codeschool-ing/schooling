---
title: Storage levels
version: 1
---

**`cache()` is `persist()` with the default storage level, and the level says where the copy is
kept and in what form.** The ones worth knowing:

| level | where | when a partition does not fit in memory |
|---|---|---|
| `MEMORY_AND_DISK` | memory, then the executor's local disk | it goes to disk; the default for a DataFrame |
| `MEMORY_ONLY` | memory | it is not kept, and is recomputed every time it is needed |
| `DISK_ONLY` | the executor's local disk | does not apply |
| `MEMORY_AND_DISK_2` and the other `_2` levels | as above, on two executors | as above |
| `OFF_HEAP` | memory outside the Java heap | needs `spark.memory.offHeap.enabled` and a size |

For a DataFrame, the copy is not a list of Python objects. Spark stores cached rows in its own
compressed columnar format, so a cached DataFrame is often smaller than the same rows as objects,
and it is read column by column like a Parquet file. The driver's REST interface reports what each
cache takes, at `storage/rdd`. Save this as `~/big/storage.py`:

```schooling-example
{
  "language": "python",
  "file": "storage.py",
  "parts": [
    {
      "code": "\"\"\"What a cache holds, at three storage levels and with fewer columns.\"\"\"\nimport json\nimport time\nimport urllib.request\n\nfrom pyspark import StorageLevel\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"storage\").getOrCreate()\nsc = spark.sparkContext\n\n\n"
    },
    {
      "code": "def stored(label, df, level):\n    df.persist(level)\n    start = time.time()\n    df.count()\n    took = time.time() - start\n    time.sleep(1)\n    url = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/storage/rdd\"\n    for r in json.load(urllib.request.urlopen(url)):\n        print(f\"{label:22} {r['numCachedPartitions']:3} of {r['numPartitions']:2}\"\n              f\" {r['memoryUsed'] / 2**20:8.1f} {r['diskUsed'] / 2**20:8.1f} {took:7.1f}\")\n    start = time.time()\n    df.count()\n    print(f\"{'':22} counted again in {time.time() - start:.1f} s\")\n    df.unpersist(blocking=True)\n\n\nclicks = spark.read.parquet(\"data/silver/clicks\")\nprint(\"                       partitions   memory     disk   filled\")\nprint(\"                           cached      MiB      MiB  seconds\")\n",
      "note": "**The driver's `storage/rdd` page lists every cached dataset**: how many of its partitions are cached, and the bytes they take in memory and on disk, summed over the executors."
    },
    {
      "code": "stored(\"all 7 columns\", clicks, StorageLevel.MEMORY_AND_DISK)\n",
      "note": "**The default for a DataFrame**: memory first, and the partitions that do not fit go to the executors' local disks."
    },
    {
      "code": "stored(\"3 columns\", clicks.select(\"visitor_id\", \"kind\", \"day\"), StorageLevel.MEMORY_AND_DISK)\n",
      "note": "**The same, for the three columns a report needs** instead of all seven."
    },
    {
      "code": "tripled = clicks.unionByName(clicks).unionByName(clicks)\nstored(\"3 copies, memory+disk\", tripled, StorageLevel.MEMORY_AND_DISK)\nstored(\"3 copies, memory only\", tripled, StorageLevel.MEMORY_ONLY)\n",
      "note": "**Three copies of the clicks, 72 million rows**, more than the three executors' storage memory can hold, at the default level and then in memory only. A partition that does not fit in memory only is not kept at all, and is read from the files again every time it is needed."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit storage.py
WARNING: Using incubator modules: jdk.incubator.vector
                       partitions   memory     disk   filled
                           cached      MiB      MiB  seconds
all 7 columns           15 of 15    284.7      0.0    41.9
                       counted again in 1.1 s
3 columns               15 of 15     51.4      0.0    13.3
                       counted again in 0.7 s
3 copies, memory+disk   45 of 45    793.3     60.9    87.8
                       counted again in 1.6 s
3 copies, memory only   42 of 45    793.4      0.0    90.1
                       counted again in 8.7 s
```

**All seven columns of the clicks took 284.7 MiB of memory**, less than the 396 MB of Parquet files
they came from. The three executors offer about 840 MiB of storage between them, lesson 7's 280.8
MiB each, so the whole table fit, and counting it again took about a second where reading it had
taken about forty.

**Three columns took 51.4 MiB**, a fifth of the space, because the columns left out include
`event_id` and `ts`, which are different in nearly every row and leave compression little to work
with. Section 03
comes back to this.

**Three copies of the clicks did not fit, and the last two lines are the difference between the two
levels.** At `MEMORY_AND_DISK`, 793.3 MiB stayed in memory and 60.9 MiB went to the executors' disks:
every partition cached, and counting again took 1.6 seconds. At `MEMORY_ONLY`, three of the 45
partitions found no room and were not kept. Counting again had to read those three from the Parquet
files, and took 8.7 seconds: a cache that does not fit costs a recomputation of the part that is
missing, every time.
