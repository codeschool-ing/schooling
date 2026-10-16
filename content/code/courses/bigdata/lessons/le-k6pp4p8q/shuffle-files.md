---
title: Where a shuffle lives
version: 1
---

**A shuffle's data is files on the executors' local disks**, not in HDFS and not in memory. Each map
task writes one data file holding all its rows, sorted by destination partition, and an index file
saying where each partition starts; the reduce tasks read their ranges out of every map task's file.
On one machine, the driver can see all three executors' disks, so a program can list them. Save
this as `~/big/shuffle_files.py`:

```schooling-example
{
  "language": "python",
  "file": "shuffle_files.py",
  "parts": [
    {
      "code": "\"\"\"Where a shuffle's files are, while the application that wrote them is alive.\"\"\"\nimport glob\nimport os\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"shuffle files\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nclicks.groupBy(\"visitor_id\").count().collect()\n\n"
    },
    {
      "code": "files = sorted(glob.glob(\"/tmp/spark-*/executor-*/blockmgr-*/*/shuffle_*\"))\ndata = [f for f in files if f.endswith(\".data\")]\nprint(len(files), \"files,\", len(data), \"of them data\")\nfor f in data[:3]:\n    print(os.path.getsize(f), \"bytes\", f.split(\"/\")[-1])\nprint(sum(os.path.getsize(f) for f in data), \"bytes of shuffle data in all\")\n",
      "note": "**Each executor keeps its shuffle files under `/tmp`**, in a directory named after it, until its application ends. On a real cluster each executor's are on its own machine; here all three are on this one, so the driver can list them."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit shuffle_files.py
WARNING: Using incubator modules: jdk.incubator.vector
45 files, 15 of them data
2581806 bytes shuffle_0_379_0.data
2581506 bytes shuffle_0_377_0.data
2584079 bytes shuffle_0_371_0.data
36268702 bytes of shuffle data in all
```

**Forty-five files for one shuffle of 15 map tasks: for each task a `.data` file, an `.index` file and
a checksum.** The data files add up to the 34.6 MiB the stage reported, about 2.5 MB for each of the
first three listed.

Three consequences of the files living where they do:

- **They outlive the stage, and that is useful.** A later job that needs the same shuffle reads the
  files again instead of rerunning the stages before it. Lesson 6's `pruning.py` had to build each
  query afresh to time it for exactly this reason.
- **They die with the executor.** When lesson 2 killed a worker, any shuffle files it held were gone,
  and the map tasks that wrote them had to run again before the next stage could read. On a cluster
  that is a machine's share of the map side, recomputed from its lineage.
- **They need disk space.** A shuffle of 35 GB needs 35 GB free on the executors' disks, spread over
  however many there are, and a job that runs out fails with `No space left on device` in the middle
  of a stage. `spark.local.dir` says where they go; the default, `/tmp`, is often the smallest disk on
  a machine.

The files are deleted when the application ends. Clusters that add and remove executors while a job
runs, lesson 13's subject, need them to survive an executor's departure, which is what an external
*shuffle service* is for.
