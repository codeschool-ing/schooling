---
title: Two jobs, and the disk between them
version: 1
---

**A question that needs two groupings needs two MapReduce jobs**, because a job has exactly one
shuffle. Ana's next question has two: how many events does each visitor have, and then, how many
visitors have each number of events? The second groups the result of the first.

Job 1 needs a mapper keyed by visitor, `~/big/per_visitor.py`:

```schooling-example
{
  "language": "python",
  "file": "per_visitor.py",
  "parts": [
    {
      "code": "\"\"\"Map for job 1: for every event, emit its visitor and a 1.\"\"\"\nimport sys\n\n"
    },
    {
      "code": "for line in sys.stdin:\n    print(f\"{line.split(',')[2]}\\t1\")\n",
      "note": "The same shape as `mapper.py`, keyed by the visitor instead of the kind. `reducer.py` then counts each visitor's events, unchanged."
    }
  ]
}
```

Job 2 reads job 1's output and keys it by the count, `~/big/histogram.py`:

```schooling-example
{
  "language": "python",
  "file": "histogram.py",
  "parts": [
    {
      "code": "\"\"\"Map for job 2: read job 1's 'visitor<TAB>events' and emit the events and a 1.\"\"\"\nimport sys\n\n"
    },
    {
      "code": "for line in sys.stdin:\n    visitor, events = line.rstrip(\"\\n\").split(\"\\t\")\n    print(f\"{events}\\t1\")\n",
      "note": "Job 2's input is job 1's output, read back from HDFS: one line per visitor. The key is now the number of events, so `reducer.py` counts how many visitors had each number."
    }
  ]
}
```

Both reduce with `reducer.py`, and job 1 combines with it too. Run them one after the other, with
job 1's output directory as job 2's input:

```
ana@lab:~/big$ time hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.local.map.tasks.maximum=3 -files per_visitor.py,reducer.py -mapper 'python3 per_visitor.py' -combiner 'python3 reducer.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/per-visitor 2> job1.log

real	0m51.183s
user	2m13.911s
sys	0m7.766s
ana@lab:~/big$ time hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.local.map.tasks.maximum=3 -files histogram.py,reducer.py -mapper 'python3 histogram.py' -reducer 'python3 reducer.py' -input /out/per-visitor -output /out/histogram 2> job2.log

real	0m8.949s
user	0m16.357s
sys	0m1.017s
ana@lab:~/big$ sed -n '/mapreduce.Job: Counters/,$p' job1.log | grep -E 'Reduce output records'
		Reduce output records=1729141
ana@lab:~/big$ hdfs dfs -du -s -h /out/per-visitor
19.3 M  57.8 M  /out/per-visitor
ana@lab:~/big$ hdfs dfs -cat /out/histogram/part-00000 | sort -n | head -n 3
2	15
3	623
4	11098
ana@lab:~/big$ hdfs dfs -cat /out/histogram/part-00000 | sort -n | tail -n 2
69	1
960905	1
ana@lab:~/big$ hdfs dfs -cat /out/histogram/part-00000 | wc -l
65
```

**About a minute for the two jobs together, 51 seconds and 9. Job 1 wrote 1,729,141 lines, one per
visitor, to HDFS: 19.3 MB, stored three times, 57.8 MB on disk. Job 2 read them back.** That file
exists only to carry the answer from one job to the next, and it was written with all the care HDFS
gives anything: three copies, checksums, a commit. The histogram itself is 65 lines. Most visitors
have a handful of events, and at the far end sits one visitor with 960,905: the crawler, again.

The same two groupings as one Spark program, `~/big/two_steps.py`:

```schooling-example
{
  "language": "python",
  "file": "two_steps.py",
  "parts": [
    {
      "code": "\"\"\"Both jobs as one Spark program.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"two steps\").getOrCreate()\nclicks = (spark.read.csv(\"hdfs://localhost:9000/raw/clicks-2025.csv\")\n          .toDF(\"event_id\", \"ts\", \"visitor_id\", \"kind\", \"book_id\", \"device\"))\n"
    },
    {
      "code": "per_visitor = clicks.groupBy(\"visitor_id\").agg(F.count(\"*\").alias(\"events\"))\nhistogram = per_visitor.groupBy(\"events\").agg(F.count(\"*\").alias(\"visitors\"))\nhistogram.orderBy(\"events\").show(5)\nhistogram.orderBy(F.desc(\"events\")).show(2)\n",
      "note": "**Two groupings, written one after the other, run as one application.** The first result is never written to HDFS: Spark passes it from one stage to the next through the shuffle files of lesson 7."
    }
  ]
}
```

```
ana@lab:~/big$ time spark-submit two_steps.py
WARNING: Using incubator modules: jdk.incubator.vector
+------+--------+
|events|visitors|
+------+--------+
|     2|      15|
|     3|     623|
|     4|   11098|
|     5|  106136|
|     6|  423168|
+------+--------+
only showing top 5 rows
+------+--------+
|events|visitors|
+------+--------+
|960905|       1|
|    69|       1|
+------+--------+
only showing top 2 rows

real	1m4.424s
user	0m31.948s
sys	0m2.228s
```

**The same histogram, in 64 seconds, and no faster.** That deserves the same honesty as lesson 1's
measurement. On one machine, on 1.2 GB, two MapReduce jobs on the local runner took about the same
time as Spark, and Spark spent much of its minute starting an application and parsing CSV on three
cores.

What the measurement does not show is how the gap grows. On a real cluster each MapReduce job also
waits for YARN to start a container for every task, a few seconds each time. And a job with ten
steps is ten jobs, each reading its input from HDFS and writing its output three times. Machine
learning algorithms and graph algorithms repeat the same step dozens of times over the same data, so
they pay the round trip through HDFS dozens of times. Lesson 9 runs one such loop in Spark, with the
data kept in memory between steps, which is the case Spark was built for.
