---
title: A bigger machine, or more of them
version: 1
---

**When something runs out, there are two ways to get more of it.** Scaling *up* is a bigger
machine: more memory, more cores, faster disks. Scaling *out* is more machines, each doing a
share. They are not two prices for the same thing, and the difference decides most of this course.

**Scaling up is simpler, and should be the first thing you consider.** Nothing in your program
changes. `visitors.py` on a machine with 4 GB would never have met its wall. Cloud providers rent
single machines with several terabytes of memory, by the hour. The limits are that the price grows
faster than the size near the top of the range, and that the top of the range exists: there is a
largest machine, and a business whose data grows will one day pass it.

**Scaling out has no top**, and costs complexity from the first machine. Data has to be split, as
section 09 split it, and moved between machines whenever the split has to change. A machine can
fail in the middle of a job, so the system has to notice and redo the lost work: lesson 2. And
every step that brings data together has to send it over a network that is far slower than memory.

Here is the same question asked of the cluster you started in section 04. Save it as
`~/big/visitors_spark.py`:

```schooling-example
{
  "language": "python",
  "file": "visitors_spark.py",
  "parts": [
    {
      "code": "\"\"\"The same question, asked of the cluster.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"visitors\").getOrCreate()\n"
    },
    {
      "code": "clicks = spark.read.option(\"header\", True).csv(\"data/raw/clicks\")\n",
      "note": "Spark reads every file under the directory, and the `day=` directories become a column of their own."
    },
    {
      "code": "(clicks.where(F.col(\"book_id\").isNotNull())\n       .groupBy(\"book_id\")\n       .agg(F.countDistinct(\"visitor_id\").alias(\"visitors\"))\n       .orderBy(F.desc(\"visitors\"))\n       .show(3))\n",
      "note": "**The same question, stated rather than programmed**: group by book, count distinct visitors. How the sets are split up and where they are counted is Spark's to decide."
    }
  ]
}
```

```
ana@lab:~/big$ time spark-submit visitors_spark.py
WARNING: Using incubator modules: jdk.incubator.vector
+-------+--------+
|book_id|visitors|
+-------+--------+
|      1|  936076|
|      2|  335986|
|      3|  244287|
+-------+--------+
only showing top 3 rows

real	1m13.765s
user	0m30.083s
sys	0m1.518s
```

**The same three numbers again, in 74 seconds.** That is not faster than the Python program, and it
is worth stopping on, because it is the most important measurement in this lesson. Spark used three
cores, where Python used one, and spent the difference on starting a cluster application, splitting
the data, moving it between its workers and putting it back together. At 24 million rows on one
machine, that overhead is the whole job.

What Spark bought was something else: **no step held the whole set**, and the same ten lines run
unchanged on a hundred machines and a hundred times the data, where the Python program does not run
at all. That is the trade a cluster offers, and it is only worth taking when the data has passed
the wall.

## Before reaching for a cluster

A short list, in the order to try it:

- **Measure the peak**, as `visitors.py` did. Most programs are nowhere near their machine's limit.
- **Process in a stream or in parts**, as `buckets.py` did, on the machine you have.
- **Use a single-machine engine built for analytics.** DuckDB reads Parquet files by column,
  spills to disk when memory is short, and uses every core; Polars is another of the kind. Lesson 14 runs one against the
  same question.
- **Rent a bigger machine for the hour you need it.**
- **Then a cluster.** When the data is past what one machine reads in the time you have, or when it
  will be soon and the program would have to be rewritten anyway.
