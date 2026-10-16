---
title: Apache Hudi
version: 1
---

**Hudi came from Uber, and its first concern was upserts**: a stream of changes, some new rows and
some corrections of old ones, applied to a large table every few minutes. Every Hudi table has a
record key, and a write is an upsert by default. Save this as `~/big/hudi_basics.py`:

```schooling-example
{
  "language": "python",
  "file": "hudi_basics.py",
  "parts": [
    {
      "code": "\"\"\"A Hudi table of purchases, and an upsert that corrects some of them and adds more.\"\"\"\nimport os\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "spark = (SparkSession.builder.appName(\"hudi basics\")\n         .config(\"spark.serializer\", \"org.apache.spark.serializer.KryoSerializer\")\n         .config(\"spark.kryo.registrator\", \"org.apache.spark.HoodieSparkKryoRegistrar\")\n         .config(\"spark.sql.extensions\", \"org.apache.spark.sql.hudi.HoodieSparkSessionExtension\")\n         .config(\"spark.sql.catalog.spark_catalog\",\n                 \"org.apache.spark.sql.hudi.catalog.HoodieCatalog\")\n         .getOrCreate())\nPATH = os.path.abspath(\"data/hudi/purchases\")\npurchases = (spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\n             .select(\"event_id\", \"ts\", \"visitor_id\", \"book_id\", \"day\")\n             .withColumn(\"updated\", F.unix_micros(\"ts\")))\n\n",
      "note": "**Hudi asks for Kryo**, Spark's faster serializer, with its own classes registered, besides the extension and catalog the other two formats needed."
    },
    {
      "code": "options = {\n    \"hoodie.table.name\": \"purchases\",\n    \"hoodie.datasource.write.recordkey.field\": \"event_id\",\n    \"hoodie.datasource.write.precombine.field\": \"updated\",\n    \"hoodie.datasource.write.partitionpath.field\": \"day\",\n    \"hoodie.datasource.write.table.type\": \"COPY_ON_WRITE\",\n}\n\njanuary = purchases.where(F.col(\"day\") < \"2025-02-01\")\njanuary.write.format(\"hudi\").options(**options).mode(\"overwrite\").save(PATH)\nprint(\"after January:\", spark.read.format(\"hudi\").load(PATH).count(), \"purchases\")\n\n",
      "note": "**A record key and an ordering field are what make an upsert possible**: a row whose `event_id` is already in the table replaces it, and when two versions of a row meet, the one with the larger `updated` wins. `updated` is the time the row was last changed, in microseconds; a timestamp column as the ordering field failed in this version of Hudi with Spark 4.1, and a number is what every version accepts."
    },
    {
      "code": "corrected = (january.orderBy(\"event_id\").limit(1000)\n             .withColumn(\"book_id\", F.lit(42))\n             .withColumn(\"updated\", F.col(\"updated\") + 86_400_000_000))\nfebruary = purchases.where((F.col(\"day\") >= \"2025-02-01\") & (F.col(\"day\") < \"2025-03-01\"))\n(corrected.unionByName(february).write.format(\"hudi\").options(**options)\n .option(\"hoodie.datasource.write.operation\", \"upsert\").mode(\"append\").save(PATH))\n\ntable = spark.read.format(\"hudi\").load(PATH)\nprint(\"after the upsert:\", table.count(), \"purchases,\",\n      table.where(F.col(\"updated\") > F.unix_micros(\"ts\")).count(), \"of them corrected\")\n",
      "note": "**The upsert**: a thousand of January's purchases sent again with a corrected book and a later `updated`, a day after the original, together with all of February. Nothing in the batch says which rows are new."
    },
    {
      "code": "table.groupBy(\"_hoodie_commit_time\").count().orderBy(\"_hoodie_commit_time\").show()\n",
      "note": "**Every row carries the commit that last wrote it**, in a column Hudi adds: `_hoodie_commit_time`."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit --jars $HOME/jars/hudi-spark4.1-bundle_2.13-1.2.1.jar hudi_basics.py 2>/dev/null
# WARNING: Unable to get Instrumentation. Dynamic Attach failed. You may add this JAR as -javaagent manually, or supply -Djdk.attach.allowAttachSelf
# WARNING: Unable to attach Serviceability Agent. Unable to attach even with module exceptions: [org.apache.hudi.org.openjdk.jol.vm.sa.SASupportException: Sense failed., org.apache.hudi.org.openjdk.jol.vm.sa.SASupportException: Sense failed., org.apache.hudi.org.openjdk.jol.vm.sa.SASupportException: Sense failed.]
after January: 80988 purchases
after the upsert: 154822 purchases, 1000 of them corrected
+-------------------+-----+
|_hoodie_commit_time|count|
+-------------------+-----+
|  20261016034138060|79988|
|  20261016034229238|74834|
+-------------------+-----+
```

**The batch held 1,000 corrections and February, and the table ended with each purchase once**:
154,822, the same count as January plus February, 1,000 of them carrying the later `updated`. Hudi
looked up each incoming `event_id`, replaced the rows it found, and inserted the rest. With Delta or
Iceberg the same thing is a `MERGE INTO`; with Hudi it is the ordinary write.

**`_hoodie_commit_time` says which commit last wrote each row**: 79,988 rows of January from the first
commit, and 74,834 from the second, February's 73,834 plus the 1,000 corrections. Hudi adds five such
columns to every row, which is what makes incremental reads possible: *give me what changed since
this commit*, without comparing tables.

The two `# WARNING` lines come from a library inside the Hudi bundle that estimates the size of
objects in memory and tries to attach to the running JVM to do it; it falls back to estimating
without, and nothing else depends on it. The timeline, Hudi's log:

```
ana@lab:~/big$ ls data/hudi/purchases/.hoodie/timeline
20261016034138060.commit.requested
20261016034138060.inflight
20261016034138060_20261016034226170.commit
20261016034229238.commit.requested
20261016034229238.inflight
20261016034229238_20261016034250468.commit
history
```

**Each commit passes through three states, each a file**: `requested`, `inflight`, and the completed
commit, named after its start and end times. A reader trusts only completed commits; a writer that
dies leaves an `inflight` that the next writer rolls back.

This table is *copy on write*: an upsert rewrites every file that holds a changed row, so reads are
plain Parquet and writes cost more. Hudi's other type, *merge on read*, writes changes to small log
files beside the Parquet and merges them when the table is read, until a *compaction* folds them in:
cheap writes, dearer reads, for tables that change every few minutes.
