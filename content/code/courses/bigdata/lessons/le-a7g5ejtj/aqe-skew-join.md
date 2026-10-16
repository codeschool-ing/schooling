---
title: Letting adaptive execution split it
version: 1
---

**Adaptive execution can do the salting itself, for a sort-merge join.** After the map side of the
shuffle has run, Spark knows the size of every partition. A partition much larger than the median
is split into pieces, each read by its own task, and the matching partition of the other side is
read whole by each of those tasks. It is salting with the copies made only for the partition that
needs them, and without changing the program.

A partition counts as skewed when it is larger than both
`spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes`, 256 MB by default, and
`spark.sql.adaptive.skewJoin.skewedPartitionFactor` times the median, five by default. **Neither is
true of this lab's hot partition**: section 02 measured it at 3,236 KiB against a median of 760, about
four times the median and nowhere near 256 MB. Those defaults are for clusters whose partitions are
hundreds of megabytes; this program scales them down to the lab's data, and says so. Save it as
`~/big/aqe_skew.py`:

```schooling-example
{
  "language": "python",
  "file": "aqe_skew.py",
  "parts": [
    {
      "code": "\"\"\"The skewed join once more, left to adaptive execution.\"\"\"\nimport contextlib\nimport io\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nfrom spread import spread\n\nspark = SparkSession.builder.appName(\"aqe skew\").getOrCreate()\nspark.conf.set(\"spark.sql.autoBroadcastJoinThreshold\", -1)\n"
    },
    {
      "code": "spark.conf.set(\"spark.sql.adaptive.enabled\", True)\nspark.conf.set(\"spark.sql.adaptive.coalescePartitions.enabled\", False)\nspark.conf.set(\"spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes\", \"2MB\")\nspark.conf.set(\"spark.sql.adaptive.skewJoin.skewedPartitionFactor\", 3)\nspark.conf.set(\"spark.sql.adaptive.advisoryPartitionSizeInBytes\", \"1MB\")\n\nclicks = spark.read.parquet(\"data/silver/clicks\")\nvisitors = spark.read.parquet(\"data/silver/visitors\")\nstart = time.time()\nreturning = (clicks.join(visitors, \"visitor_id\")\n             .where(F.col(\"day\") > F.col(\"first_day\"))\n             .groupBy(\"device\").count())\nprint(sorted(tuple(row) for row in returning.collect()))\nprint(f\"{time.time() - start:.1f} s\")\nspread(spark)\n",
      "note": "**Adaptive execution on, with its skew handling scaled down to this lab's data**: a partition counts as skewed above 2 MB and three times the median, and is cut into pieces of about 1 MB. The defaults are 256 MB and five times, for clusters whose partitions are hundreds of megabytes. Coalescing is off, so that it does not merge the small partitions and hide the large one."
    },
    {
      "code": "plan = io.StringIO()\nwith contextlib.redirect_stdout(plan):\n    returning.explain()\nprint(\"\\n\".join(line.strip() for line in plan.getvalue().splitlines() if \"Join\" in line))\n",
      "note": "**The final plan, and only its join line**: `explain` prints, so its output is caught and filtered rather than read in full."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit aqe_skew.py
WARNING: Using incubator modules: jdk.incubator.vector
[('desktop', 4624211), ('mobile', 8687852), ('tablet', 699799)]
33.2 s
stage  tasks       rows read: min     median        max   KiB read: median    max   seconds: median   max
    7    203              119,806    123,864    317,199                760    994              0.17  2.97
+- *(5) SortMergeJoin(skew=true) [visitor_id#2], [visitor_id#7], Inner, (day#6 > first_day#8)
+- SortMergeJoin [visitor_id#2], [visitor_id#7], Inner, (day#6 > first_day#8)
```

**`skew=true` in the plan is adaptive execution saying it split a partition.** The stage that read the
shuffle had 203 tasks instead of 200: the hot partition became four pieces, and the largest task read
317,199 rows instead of 1,086,798. The answer is the same as before, which is the property that makes
this safe to leave on. The join appears twice because `explain`, after a run, prints the plan that
ran and then the one first made, and only the first carries the split.

**The slowest task was not quicker**, at 2.97 seconds against 1.72. A task's time on this lab moves
by half a second between runs of the same program, and with tasks this short the rows are the
measure to trust.

**And the job still took longer than with no cure at all**, 33.2 seconds against 26.3. Nothing on this
lab can be faster than a skew that costs under two seconds. What this section shows is the
mechanism and how to see it work: the `skew=true`, the extra tasks, and the largest task coming down
to the size of the others. On a cluster, with the default thresholds, the same thing happens to a
partition of gigabytes without anybody asking for it.

**Its limits are worth knowing before relying on it.** It works on sort-merge and shuffle hash joins,
not on a skewed `groupBy`; there, partial aggregation before the shuffle already shrinks a hot key to
one row per task, which is why lesson 7's grouping by visitor never suffered from the crawler. In an
outer join it can split only the side whose rows are all kept, because a split of the other side
would emit each unmatched row once per piece. And it measures
compressed shuffle bytes, so a key whose rows compress well looks smaller than it is.
