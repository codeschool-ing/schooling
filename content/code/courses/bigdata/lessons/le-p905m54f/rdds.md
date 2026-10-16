---
title: RDDs, and the lineage behind every result
version: 1
---

**The *Resilient Distributed Dataset* is Spark's original abstraction, and everything newer is
built on it.** An RDD is a collection of elements cut into partitions, one per task, that Spark
can compute on the executors. You make one from data, and every operation on it makes a new one.
Save this as `~/big/rdd_kinds.py`:

```schooling-example
{
  "language": "python",
  "file": "rdd_kinds.py",
  "parts": [
    {
      "code": "\"\"\"Count the events of each kind with the RDD API, and print its lineage.\"\"\"\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"rdd kinds\").getOrCreate()\nsc = spark.sparkContext\n\n"
    },
    {
      "code": "lines = sc.textFile(\"data/raw/clicks/*/*.csv.gz\")\n",
      "note": "**An RDD is a collection cut into partitions, spread over the executors.** `textFile` makes one whose elements are lines; a glob is needed because it does not read the `day=` directories by itself. Nothing is read yet."
    },
    {
      "code": "events = lines.filter(lambda line: not line.startswith(\"event_id\"))\npairs = events.map(lambda line: (line.split(\",\")[3], 1))\ncounts = pairs.reduceByKey(lambda a, b: a + b)\n\n",
      "note": "Each transformation returns a new RDD and leaves the old one alone. `filter` drops the header lines, `map` turns a line into a pair, and `reduceByKey` adds the 1s of each kind: lesson 4's map, combine and reduce, in three lines."
    },
    {
      "code": "print(counts.toDebugString().decode())\n",
      "note": "`toDebugString` prints the *lineage*: how `counts` would be computed from the files, step by step. Spark keeps it for every RDD."
    },
    {
      "code": "print(sorted(counts.collect()))\nprint(\"partitions:\", lines.getNumPartitions(), counts.getNumPartitions())\n",
      "note": "`collect` is the first line that asks for a result, so it is the one that runs the job."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit rdd_kinds.py
WARNING: Using incubator modules: jdk.incubator.vector
(365) PythonRDD[6] at RDD at PythonRDD.scala:59 []
  |   MapPartitionsRDD[5] at mapPartitions at PythonRDD.scala:171 []
  |   ShuffledRDD[4] at partitionBy at NativeMethodAccessorImpl.java:0 []
  +-(365) PairwiseRDD[3] at reduceByKey at /home/ana/big/rdd_kinds.py:10 []
      |   PythonRDD[2] at reduceByKey at /home/ana/big/rdd_kinds.py:10 []
      |   data/raw/clicks/*/*.csv.gz MapPartitionsRDD[1] at textFile at NativeMethodAccessorImpl.java:0 []
      |   data/raw/clicks/*/*.csv.gz HadoopRDD[0] at textFile at NativeMethodAccessorImpl.java:0 []
[('cart', 1920654), ('purchase', 959814), ('search', 1920318), ('view', 19199214)]
partitions: 365 365
```

The counts are lesson 3's and lesson 4's, from a third program. The block at the top is the point
of this section.

**That is the *lineage* of `counts`**, read from the bottom up: a `HadoopRDD` that reads the files,
a `MapPartitionsRDD` of lines, the Python `filter` and `map` fused into one `PythonRDD`, the pairs,
and then, at the `+-` where the indentation changes, a shuffle: `ShuffledRDD` is the boundary lesson
4 called the shuffle, between the map side and the reduce side. The `(365)` at each level is the
number of partitions, one per gzipped file, because a gzip file cannot be split and so each is read
by one task.

**The lineage is the *resilient* in the name.** An RDD's partitions are not stored anywhere by
default. What Spark keeps is the recipe, and if an executor dies holding the partitions of
`counts`, Spark reruns the recipe for exactly those partitions, from the files, which still exist.
This is what lesson 2 watched without a name for it: the lost task ran again because its input
could be recomputed from the record of how it was made.

RDDs are still there, under every DataFrame, and they are the right tool when the data has no
shape a table can express. For anything that does, the rest of this lesson prefers the DataFrame,
for reasons the planner of lesson 6 makes concrete.
