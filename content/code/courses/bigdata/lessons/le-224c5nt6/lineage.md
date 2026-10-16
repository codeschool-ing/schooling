---
title: A lineage that grows
version: 1
---

**Every DataFrame carries the plan that produces it, all the way back to the files.** That is what
let the last section rebuild a lost partition, and it is usually free. In a loop it is not. A
DataFrame built from the previous iteration's DataFrame carries the previous plan inside its own, so
iteration twenty's plan contains nineteen others.

Section 04 avoided this by bringing the ranks back to the driver each time. When the state is too
large for the driver, it stays on the cluster as a DataFrame, and the plan grows. This program runs
PageRank that way, on a smaller graph made from purchases so that twenty iterations take minutes,
and prints the size of the plan and the time every five iterations. Save it as `~/big/lineage.py`:

```schooling-example
{
  "language": "python",
  "file": "lineage.py",
  "parts": [
    {
      "code": "\"\"\"PageRank with the ranks kept on the cluster, and the plan that grows with every iteration.\"\"\"\nimport contextlib\nimport io\nimport os\nimport sys\nimport time\n\nfrom pyspark.sql import SparkSession, Window\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"lineage\").getOrCreate()\nCHECKPOINT = \"checkpoint\" in sys.argv[1:]\n"
    },
    {
      "code": "spark.sparkContext.setCheckpointDir(\"file://\" + os.path.abspath(\"checkpoints\"))\n\n",
      "note": "**Where checkpoints are written.** Every executor writes its partitions there and the driver reads them back, so on a real cluster this is a directory in HDFS or an object store. Here every process shares one disk, and a local path works."
    },
    {
      "code": "bought = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\nafter = Window.partitionBy(\"visitor_id\").orderBy(\"ts\", \"event_id\")\nlinks = (bought.select(F.col(\"book_id\").alias(\"src\"),\n                       F.lead(\"book_id\").over(after).alias(\"dst\"))\n         .where(F.col(\"dst\").isNotNull() & (F.col(\"src\") != F.col(\"dst\")))\n         .groupBy(\"src\", \"dst\").count()\n         .withColumn(\"share\", F.col(\"count\") / F.sum(\"count\").over(Window.partitionBy(\"src\")))\n         .select(\"src\", \"dst\", \"share\")\n         .cache())\nbooks = spark.read.parquet(\"data/silver/books\").select(F.col(\"book_id\").alias(\"src\"))\nn = books.count()\n\n\ndef plan_lines(df):\n    out = io.StringIO()\n    with contextlib.redirect_stdout(out):\n        df.explain()\n    return len(out.getvalue().splitlines())\n\n\n",
      "note": "**A smaller graph, from purchases only**, so that twenty iterations run in minutes: a link is one book bought right after another by the same visitor."
    },
    {
      "code": "rank = books.withColumn(\"rank\", F.lit(1 / n))\nstart = began = time.time()\nfor i in range(1, 21):\n    received = (links.join(rank, \"src\")\n                .groupBy(\"dst\").agg(F.sum(F.col(\"rank\") * F.col(\"share\")).alias(\"r\")))\n    rank = (books.join(received, books.src == received.dst, \"left\")\n            .select(\"src\", (0.15 / n + 0.85 * F.coalesce(\"r\", F.lit(0.0))).alias(\"rank\")))\n    if i % 5 == 0:\n        #>> **With `checkpoint` on the command line**, the ranks are computed, written to the checkpoint directory and read back as a DataFrame with no history: the plan starts again from a file.\n        #pt> **Com `checkpoint` na linha de comando**, os ranks são calculados, gravados no diretório de checkpoint e lidos de volta como um DataFrame sem histórico: o plano recomeça de um arquivo.\n        if CHECKPOINT:\n            rank = rank.checkpoint()\n        top = rank.orderBy(F.desc(\"rank\")).limit(1).collect()[0]\n        print(f\"iteration {i:2}: plan of {plan_lines(rank):4} lines,\"\n              f\" {time.time() - began:5.1f} s, top book {top.src}\")\n        began = time.time()\nprint(f\"twenty iterations: {time.time() - start:.1f} s\")\n",
      "note": "**The ranks are a DataFrame now**, and each iteration is a new DataFrame defined on top of the last one. Nothing runs until the `collect` every fifth iteration, which computes the ranks from the very first. The time printed is everything since the last print."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit lineage.py
WARNING: Using incubator modules: jdk.incubator.vector
02:38:09 WARN SparkContext: Spark is not running in local mode, therefore the checkpoint directory must not be on the local filesystem. Directory 'file:///home/ana/big/checkpoints' appears to be on the local filesystem.
iteration  5: plan of  291 lines,  53.0 s, top book 1
iteration 10: plan of  576 lines,  28.5 s, top book 1
iteration 15: plan of  861 lines,  32.7 s, top book 1
iteration 20: plan of 1146 lines,  40.5 s, top book 1
twenty iterations: 154.7 s
```

**The plan grew by 57 lines an iteration, to 1,146 by the twentieth**, and Spark has to analyse,
optimise and plan all of it at every action. The time grew less steeply than the plan, but it grew:
28.5 seconds for iterations 6 to 10 and 40.5 for 16 to 20, for the same amount of new work each
time.

The warning at the top is the next section's.

**A long lineage costs in three places.** Planning time grows with the plan, and in a long enough
loop it outgrows the work. Recomputation after a failure has further to go back,
because a lost partition of iteration twenty may need iterations one to nineteen run again. And a
plan deep enough exhausts the driver's stack while Spark walks it, with a `StackOverflowError` that
names no line of the program.
