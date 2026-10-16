---
title: Spark Connect
version: 1
---

**Every program in this course has been a driver**: `spark-submit` started a Java process beside
Python, and the program's DataFrames lived in it. *Spark Connect* splits that in two. A server runs
the driver, next to the cluster; a thin client, anywhere, sends it plans over gRPC and gets rows back.
The client needs no Java, no Spark jars, and no route to the executors.

The server ships with Spark. Start it on the standalone cluster:

```sh
start-connect-server.sh
```

The client is a Python package of its own, `pyspark-client`, which brings pandas, PyArrow and gRPC and
nothing from the JVM. In an environment of its own:

```sh
python3 -m venv ~/connect-env
~/connect-env/bin/pip install pyspark-client==4.1.3
```

Save this as `~/big/connect_client.py`:

```schooling-example
{
  "language": "python",
  "file": "connect_client.py",
  "parts": [
    {
      "code": "\"\"\"A Spark client with no Spark in it: the DataFrame API over a network connection.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "spark = SparkSession.builder.remote(\"sc://localhost:15002\").getOrCreate()\nprint(\"server runs Spark\", spark.version)\n\n",
      "note": "**`remote` instead of a master**: the session is a connection to a Spark Connect server, which runs the driver. This process starts no Java and holds no cluster resources."
    },
    {
      "code": "clicks = spark.read.parquet(\"data/silver/clicks\")\nfor row in clicks.groupBy(\"kind\").count().orderBy(\"kind\").collect():\n    print(row.kind, row[\"count\"])\n\n",
      "note": "**The same DataFrame code as lesson 5.** The client sends the plan, unresolved, to the server; the server analyses it, runs it on its cluster and streams the rows back as Arrow batches. The path is the server's, relative to the directory it was started in."
    },
    {
      "code": "try:\n    clicks.select(\"no_such_column\").collect()\nexcept Exception as e:\n    print(type(e).__name__ + \":\", str(e).splitlines()[0][:100])\n",
      "note": "**An error comes back as an exception in the client**, raised from the server's analysis, before anything runs."
    }
  ]
}
```

Run with the environment's Python, not `spark-submit`, and with the client's own error log sent
away, since the program fails on purpose at the end:

```
ana@lab:~/big$ ~/connect-env/bin/python connect_client.py 2>/dev/null
server runs Spark 4.1.3
cart 1920654
purchase 959814
search 1920318
view 19199214
AnalysisException: [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `no_such_col
```

**The same counts as lesson 4, from a process that has never started Java.** The plan travelled to the
server, which ran it on the cluster like any other application's, and the four rows came back. The
deliberate mistake came back as the same `AnalysisException` a local session raises, from the server's
analyser, before anything ran.

**That is what managed services and notebooks have moved to**, and it changes three things. A
client crash, or a laptop closing, no longer kills a driver holding the cluster's executors. The
client and the server can be upgraded separately, within a version range. And several users can share
one server, with sessions kept apart, the way they would share a database. What it does not change is
anything about how the job runs: the plan, the shuffle and the memory are the server's, exactly as
before.

Stop the server when done:

```sh
stop-connect-server.sh
```
