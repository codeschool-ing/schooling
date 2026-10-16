---
title: The broadcast join, timed
version: 1
---

**Lesson 6 showed the planner choosing a broadcast for the books; this section times the choice.**
Two joins, each run both ways with a hint: the clicks with the books, 3,000 rows, and the clicks
with the visitors of section 02, 1.7 million rows. Save this as `~/big/join_times.py`:

```schooling-example
{
  "language": "python",
  "file": "join_times.py",
  "parts": [
    {
      "code": "\"\"\"The same two joins, as a broadcast and as a sort-merge, timed.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"join times\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nbooks = spark.read.parquet(\"data/silver/books\")\nvisitors = spark.read.parquet(\"data/silver/visitors\")\n\n\n"
    },
    {
      "code": "def timed(label, make):\n    make().collect()\n    start = time.time()\n    make().collect()\n    print(f\"{label:28} {time.time() - start:5.1f} s\")\n\n\n",
      "note": "Each join is run twice and the second time kept, as in lesson 6, with the query built afresh each time."
    },
    {
      "code": "for name, small in [(\"books\", books), (\"visitors\", visitors)]:\n    key = \"book_id\" if name == \"books\" else \"visitor_id\"\n    timed(f\"{name}, broadcast\", lambda: clicks.join(F.broadcast(small), key)\n          .groupBy(\"device\").count())\n    timed(f\"{name}, sort-merge\", lambda: clicks.join(small.hint(\"merge\"), key)\n          .groupBy(\"device\").count())\n",
      "note": "**Hints choose the strategy**: `F.broadcast(df)` asks for a broadcast join, and `df.hint(\"merge\")` for a sort-merge join, whatever the planner would have chosen."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit join_times.py
WARNING: Using incubator modules: jdk.incubator.vector
books, broadcast               4.4 s
books, sort-merge             19.8 s
visitors, broadcast            8.9 s
visitors, sort-merge          19.0 s
```

| | broadcast | sort-merge | |
|---|---|---|---|
| books, 3,000 rows | 4.4 s | 19.8 s | 4.5 times faster |
| visitors, 1.7 million rows | 8.9 s | 19.0 s | 2.1 times faster |

**For the books, the broadcast wins by the whole cost of a shuffle**: the sort-merge plan moves 24
million click rows across the cluster and sorts them to meet a table of 3,000, and the broadcast
moves 3,000 rows to three executors. The planner would have chosen the broadcast for the books on
its own.

**For the visitors it depends on the query.** The planner estimates a side from the size of its
files, scaled down to the columns the query uses. This query uses only `visitor_id`, and the estimate
comes in just under the 10 MB threshold, so the planner would have broadcast the visitors unprompted.
Section 02's query also uses `first_day`, which takes the estimate over the line and the plan to a
sort-merge join; `explain("cost")`, from lesson 6, shows both numbers. **The threshold is a guess made
for a cluster of unknown size**, and a table of 14 MB on disk was twice as fast broadcast to three
executors of 768 MB each. On executors with gigabytes to spare, raising the threshold to 50 or 100 MB
is one of the cheapest changes there is.

Broadcasting also cures this lesson's problem by the way: **a broadcast join has no skew**, because
there is no shuffle on the large side. Each task joins the rows it already holds against the whole
table, and the crawler's events stay spread over the partitions they were read in. When the small
side of a skewed join fits in memory, that is the first thing to try.
