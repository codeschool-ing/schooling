---
title: Jobs, stages and tasks
version: 1
---

**An action becomes a job, a job is cut into stages at every shuffle, and a stage is a set of
tasks, one per partition.** Lessons 2 and 6 used each of the three words; this lesson measures
them, and it needs a way to see a stage's numbers after it ran.

The driver's REST interface has them, per stage. A module of this course's own prints the stages of
the last query, one line each. Save it as `~/big/stages.py`; this lesson and lessons 9 and 14 use
it:

```schooling-example
{
  "language": "python",
  "file": "stages.py",
  "parts": [
    {
      "code": "\"\"\"The stages of the last query: tasks, data in and out, spill and time.\"\"\"\nimport json\nimport time\nimport urllib.request\n\n\ndef get(spark, path):\n    sc = spark.sparkContext\n    url = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/{path}\"\n    return json.load(urllib.request.urlopen(url))\n\n\ndef mb(n):\n    return f\"{n / 2**20:8.1f}\"\n\n\ndef millions(n):\n    return f\"{n / 1e6:8.1f}\"\n\n\n"
    },
    {
      "code": "def report(spark):\n    time.sleep(1)\n    last = max(get(spark, \"sql?details=false\"), key=lambda q: q[\"id\"])\n    ids = []\n    for job in last[\"successJobIds\"] + last[\"failedJobIds\"]:\n        ids += get(spark, f\"jobs/{job}\")[\"stageIds\"]\n",
      "note": "**The newest SQL query, and every job it ran.** A query can run more than one job, and adaptive execution often adds one per shuffle."
    },
    {
      "code": "    print(\"stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task\")\n    print(\"                            MiB            MiB      MiB  seconds\")\n    for sid in sorted(set(ids)):\n        for s in get(spark, f\"stages/{sid}\"):\n            if s[\"status\"] == \"SKIPPED\" or s[\"numCompleteTasks\"] == 0:\n                continue\n            took = s[\"executorRunTime\"] / 1000\n            print(f\"{sid:5} {s['numTasks']:6} {millions(s['inputRecords'])}     \"\n                  f\"{mb(s['shuffleWriteBytes'])}      {mb(s['shuffleReadBytes'])}   \"\n                  f\"{mb(s['diskBytesSpilled'])}   {took:6.1f}\")\n",
      "note": "One line per stage that ran: its tasks, the rows it read from files, the bytes it wrote to and read from shuffles, the bytes it spilled to disk, and the time its tasks took, added together. A stage the job could skip, because its output already existed, is left out."
    }
  ]
}
```

Then two groupings of the silver clicks, one by kind and one by visitor. Save this as
`~/big/jobs_stages.py`:

```schooling-example
{
  "language": "python",
  "file": "jobs_stages.py",
  "parts": [
    {
      "code": "\"\"\"Two groupings of the clicks, and the stages each one ran.\"\"\"\nfrom pyspark.sql import SparkSession\n\nfrom stages import report\n\nspark = SparkSession.builder.appName(\"jobs and stages\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\n"
    },
    {
      "code": "print(\"partitions:\", clicks.rdd.getNumPartitions())\n\n",
      "note": "How many partitions the read makes: the number of tasks of the first stage."
    },
    {
      "code": "print(\"kinds:\", len(clicks.groupBy(\"kind\").count().collect()))\nreport(spark)\n",
      "note": "**Four kinds**: the partial counts make the shuffle tiny."
    },
    {
      "code": "print(\"visitors:\", len(clicks.groupBy(\"visitor_id\").count().collect()))\nreport(spark)\n",
      "note": "**1.7 million visitors**: partial counts cannot shrink a key that has so many values."
    },
    {
      "code": "spark.conf.set(\"spark.sql.adaptive.enabled\", False)\nprint(\"visitors:\", len(clicks.groupBy(\"visitor_id\").count().collect()))\nreport(spark)\n",
      "note": "**The same grouping with adaptive execution switched off**, for section 07."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit jobs_stages.py
WARNING: Using incubator modules: jdk.incubator.vector
partitions: 15
kinds: 4
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    2     15     24.0          0.0           0.0        0.0     18.5
    4      1      0.0          0.0           0.0        0.0      0.2
visitors: 1729141
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    5     15     24.0         34.6           0.0        0.0     20.8
    7      3      0.0          0.0          34.6        0.0      5.6
visitors: 1729141
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    8     15     24.0         34.6           0.0        0.0     14.4
    9    200      0.0          0.0          34.6        0.0      8.2
```

**Each grouping ran two stages, on either side of its shuffle.** The first stage of each read the
files: 15 tasks, one per partition of the input, 24 million rows in. The second read the shuffle and
did the final count. The by-kind grouping's second stage was one task and the by-visitor one three,
far fewer than the 200 the planner asked for, because adaptive execution coalesced them, as lesson
6 showed it doing.

**The two first stages did the same reading and took about the same time; what they wrote to the
shuffle is the whole difference.** Four kinds compress, by partial counting, into a few bytes per
task. 1.7 million visitors do not: 34.6 MiB went through the shuffle, a line per visitor per task
that saw them.

**The last column is the sum of the stage's task times**, not the time the stage took. Fifteen tasks
of a second or so each add up to around twenty task-seconds, and with three running at a time the
stage takes about a third of that on the clock.
