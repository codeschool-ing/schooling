---
title: Spark reading from HDFS, and the tasks going to the data
version: 1
---

**A Spark program reads HDFS by giving it an address that starts with `hdfs://`.** Nothing else
changes. What changes underneath is that Spark now knows where each piece of the file lives, and
can send each task to it. Save this as `~/big/hdfs_count.py`:

```schooling-example
{
  "language": "python",
  "file": "hdfs_count.py",
  "parts": [
    {
      "code": "\"\"\"Count the events of each kind in the year's file on HDFS, then ask the\ndriver's own REST interface where the reading tasks ran.\"\"\"\nimport collections\nimport json\nimport urllib.request\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"hdfs count\").getOrCreate()\n"
    },
    {
      "code": "clicks = (spark.read.csv(\"hdfs://localhost:9000/raw/clicks-2025.csv\")\n          .toDF(\"event_id\", \"ts\", \"visitor_id\", \"kind\", \"book_id\", \"device\"))\n",
      "note": "**The only change from a local file is the address.** `hdfs://localhost:9000` is the namenode `core-site.xml` named. The file has no header, so the columns are named here."
    },
    {
      "code": "print(\"partitions:\", clicks.rdd.getNumPartitions())\nclicks.groupBy(\"kind\").count().orderBy(\"kind\").show()\n\n",
      "note": "One partition per HDFS block: Spark asked the namenode where the blocks are and made a task for each."
    },
    {
      "code": "sc = spark.sparkContext\nbase = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/stages\"\nfor stage in json.load(urllib.request.urlopen(base)):\n    tasks = json.load(urllib.request.urlopen(\n        f\"{base}/{stage['stageId']}/{stage['attemptId']}/taskList?length=1000\"))\n    where = collections.Counter(t[\"taskLocality\"] for t in tasks)\n    print(f\"stage {stage['stageId']}: {stage['numTasks']} tasks\", dict(where))\n",
      "note": "The driver's page, the one lesson 2 read with `curl`, asked from inside the program before it ends: for every stage, how many tasks ran at each *locality*. Section 08 reads the answer."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit hdfs_count.py
WARNING: Using incubator modules: jdk.incubator.vector
partitions: 10
+--------+--------+
|    kind|   count|
+--------+--------+
|    cart| 1920654|
|purchase|  959814|
|  search| 1920318|
|    view|19199214|
+--------+--------+

stage 3: 1 tasks {'NODE_LOCAL': 1}
stage 2: 10 tasks {}
stage 1: 10 tasks {'NODE_LOCAL': 10}
stage 0: 1 tasks {'NODE_LOCAL': 1}
```

**Ten partitions, one per block**, and the counts of each kind of event: 24 million in total, four
in five of them views, as `generate.py` drew them. The lines at the bottom are the program asking
its own driver where its tasks ran:

- **Stage 1 read the file: ten tasks, all `NODE_LOCAL`.** Each ran on a machine that held a copy of
  its block, so it read from a local disk rather than over the network.
- **Stage 0 read one line to learn how many columns there are**, and stage 3 read the small
  intermediate result of stage 1. Stage 2 has no tasks listed: Spark planned it and then found it
  did not need it, which lesson 6 explains.

The levels Spark uses, from best to worst, are `PROCESS_LOCAL` (the data is already in the
executor's memory, lesson 9), `NODE_LOCAL` (on the same machine), `RACK_LOCAL` (in the same rack)
and `ANY`. On a large cluster the difference between `NODE_LOCAL` and `ANY` is the difference between
reading a block from a disk inside the machine and pulling it across the network, for every block.

**This lab first recorded every one of these tasks as `ANY`**, and the fix is the last line of
`hdfs.sh`'s datanode settings. Without it, each datanode registers under the name `localhost`, while
Spark's executors are known as `127.0.0.1`: the same machine, under two names. Spark compares names,
found no executor called `localhost`, and sent every task to `ANY`. Nothing failed and nothing
warned; the job simply read everything as if from far away. **Locality works by matching names**, and
on a real cluster a mismatch between the names HDFS and the cluster manager use for a machine turns
it off just as quietly. The task list is where to check.

Note what is still missing: data locality saves the network only where the data and the compute are
the same machines. With an object store, the next section's subject, they never are.
