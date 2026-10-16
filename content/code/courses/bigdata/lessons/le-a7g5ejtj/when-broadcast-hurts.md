---
title: When a broadcast hurts
version: 1
---

**A broadcast is paid for twice: once in the driver and once in every executor.** The driver runs
the small side's query, collects its rows, builds the hash table and sends it out; each executor
keeps a whole copy in memory for as long as the join runs. Nothing about it spills. A side that is
not small after all is the way a broadcast goes wrong.

The clearest case is a hint on the wrong side. Save this as `~/big/too_big.py`:

```schooling-example
{
  "language": "python",
  "file": "too_big.py",
  "parts": [
    {
      "code": "\"\"\"A broadcast join asked for on the wrong side.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"too big to broadcast\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nvisitors = spark.read.parquet(\"data/silver/visitors\")\n"
    },
    {
      "code": "print(visitors.join(F.broadcast(clicks), \"visitor_id\").groupBy(\"device\").count().collect())\n",
      "note": "**The hint names the clicks, all 24 million of them, as the side to copy to every task.** The driver has to collect them first."
    }
  ]
}
```

Run it, with `grep` keeping the one line of the stack trace that says what happened:

```
ana@lab:~/big$ spark-submit too_big.py 2>&1 | grep -E 'WARN|SparkException'
WARNING: Using incubator modules: jdk.incubator.vector
01:47:38 WARN TaskMemoryManager: Failed to allocate a page (1073741824 bytes), try again.
: org.apache.spark.SparkException: Not enough memory to build and broadcast the table to all worker nodes. As a workaround, you can either disable broadcast by setting spark.sql.autoBroadcastJoinThreshold to -1 or increase the spark driver memory by setting spark.driver.memory to a higher value or apply the shuffle sort merge join hint as described in the Spark documentation: https://spark.apache.org/docs/latest/sql-ref-syntax-qry-select-hints.html#join-hints.
```

**The driver refused, and said why.** It tried to take a gigabyte of memory to hold 24 million rows
and could not, and the message lists the three ways out: switch broadcasting off, give the driver
more memory, or hint a sort-merge join instead. Only the last is a fix; the first throws away the
broadcasts that were helping, and the second moves the wall without removing it.

Nobody writes this hint on purpose. **How it happens in practice is an estimate that was wrong:**

- **Statistics from before a filter.** The planner estimates a side from its files and the
  filters it can see. A table that was small last month and has grown, or a filter written as a
  Python UDF that the planner cannot see through, sends a large side to the driver.
- **A hint that outlived its reason.** `F.broadcast(countries)` was right when the table had 200
  rows. Two years later somebody joined it to cities first.
- **A threshold raised for one job and left raised** in the cluster's defaults, where every other
  job inherits it.

Two settings bound the damage. `spark.sql.broadcastTimeout`, 300 seconds by default, fails a
broadcast that takes too long to build. And adaptive execution, on by default, re-plans a join
after the shuffle when its real size is known; it can turn a sort-merge join into a broadcast when a
side came out small, though it does not turn a broadcast back into a sort-merge. A wrong hint is
obeyed until it fails.
