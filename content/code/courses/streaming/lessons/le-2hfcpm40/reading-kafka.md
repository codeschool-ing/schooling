---
title: Reading the sales topic
version: 1
---

Before counting anything, look at what Spark gets when it reads a Kafka topic. **It is not your
sales: it is Kafka's records, with the sale inside one column as raw bytes**, and the first job of
every streaming query on Kafka is to take them out.

Start from a clean topic and two hundred sales. If the `sales` topic from earlier lessons is still
there, `./cluster.sh stop`, `./cluster.sh new 1` and `./cluster.sh start` give you an empty cluster
first, so that your numbers match the ones below:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
Created topic sales.
```

`--rate 0` sends them as fast as Kafka takes them, because this time nobody is watching them
arrive. The till's clock still advances one to twenty seconds between sales, so the two hundred
cover a little over half an hour of shop time, from 09:00 to 09:36:41:

```
ubuntu@stream:~/work$ python tills.py --count 200 --rate 0
sent 200 sales to sales, the last one at 09:36:41
```

## The smallest query

Save this as `~/work/spark_raw.py`:

```schooling-example
{
  "file": "spark_raw.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"spark_raw.py: the sales topic as Spark sees it, before any parsing.\"\"\"\nimport sys\n\nfrom pyspark.sql import SparkSession\n",
      "note": "What it is for, in one line."
    },
    {
      "code": "spark = (SparkSession.builder.appName(\"spark-raw\").master(\"local[2]\")\n         .config(\"spark.jars.packages\", \"org.apache.spark:spark-sql-kafka-0-10_2.13:4.1.3\")\n         .config(\"spark.sql.session.timeZone\", \"America/Sao_Paulo\")\n         .config(\"spark.ui.showConsoleProgress\", \"false\")\n         .getOrCreate())\nspark.sparkContext.setLogLevel(\"ERROR\")\n",
      "note": "**A Spark program starts by asking for a session**, and this one is a whole Spark inside your Python process: `local[2]` means two worker threads on this machine and no cluster. The first `config` line is the Kafka connector from the last section. The time zone is set so that Spark prints times as the shops' clocks read them, whatever zone your machine is in."
    },
    {
      "code": "raw = (spark.readStream.format(\"kafka\")\n       .option(\"kafka.bootstrap.servers\", \"localhost:9092\")\n       .option(\"subscribe\", \"sales\")\n       .option(\"startingOffsets\", \"earliest\")\n       .load())\nraw.printSchema()\nsys.stdout.flush()\n",
      "note": "`readStream` instead of `read` is the whole difference between a stream and a table here. **`startingOffsets` says where to begin the first time this query runs**, and `earliest` means the oldest sale the topic still holds. The schema is printed and flushed at once, so it reaches the screen before anything Spark itself prints."
    },
    {
      "code": "query = (raw.withColumn(\"value\", raw.value.cast(\"string\"))\n         .select(\"key\", \"value\", \"partition\", \"offset\", \"timestamp\")\n         .writeStream.format(\"console\").trigger(availableNow=True).start())\nquery.awaitTermination()",
      "note": "The value is cast from bytes to text, five columns are kept, and the result goes to the console. `availableNow` makes the query read what is in the topic now and then stop, which section 07 explains."
    }
  ]
}
```

Spark writes a great deal about itself on standard error: the libraries it loads, the warnings of
the Java libraries under it, and on the first run the whole report of the connector's download.
**Send all of that to a file with `2>spark.log`**, so that what reaches your screen is what the
query printed, and read the file when something goes wrong:

```
ubuntu@stream:~/work$ python spark_raw.py 2>spark.log
root
 |-- key: binary (nullable = true)
 |-- value: binary (nullable = true)
 |-- topic: string (nullable = true)
 |-- partition: integer (nullable = true)
 |-- offset: long (nullable = true)
 |-- timestamp: timestamp (nullable = true)
 |-- timestampType: integer (nullable = true)

-------------------------------------------
Batch: 0
-------------------------------------------
+--------------------+--------------------+---------+------+--------------------+
|                 key|               value|partition|offset|           timestamp|
+--------------------+--------------------+---------+------+--------------------+
|[6A 6F 61 6F 2D 7...|{"sale": "joa-000...|        1|     0|2026-10-10 22:45:...|
|    [6E 61 74 61 6C]|{"sale": "nat-000...|        1|     1|2026-10-10 22:45:...|
| [6F 6C 69 6E 64 61]|{"sale": "oli-000...|        1|     2|2026-10-10 22:45:...|
|    [6E 61 74 61 6C]|{"sale": "nat-000...|        1|     3|2026-10-10 22:45:...|
|    [6E 61 74 61 6C]|{"sale": "nat-000...|        1|     4|2026-10-10 22:45:...|
| [72 65 63 69 66 65]|{"sale": "rec-000...|        1|     5|2026-10-10 22:45:...|
| [72 65 63 69 66 65]|{"sale": "rec-000...|        1|     6|2026-10-10 22:45:...|
|    [6E 61 74 61 6C]|{"sale": "nat-000...|        1|     7|2026-10-10 22:45:...|
|    [6E 61 74 61 6C]|{"sale": "nat-000...|        1|     8|2026-10-10 22:45:...|
| [72 65 63 69 66 65]|{"sale": "rec-000...|        1|     9|2026-10-10 22:45:...|
|[6A 6F 61 6F 2D 7...|{"sale": "joa-000...|        1|    10|2026-10-10 22:45:...|
|    [6E 61 74 61 6C]|{"sale": "nat-000...|        1|    11|2026-10-10 22:45:...|
| [6F 6C 69 6E 64 61]|{"sale": "oli-000...|        1|    12|2026-10-10 22:45:...|
| [72 65 63 69 66 65]|{"sale": "rec-000...|        1|    13|2026-10-10 22:45:...|
| [6F 6C 69 6E 64 61]|{"sale": "oli-000...|        1|    14|2026-10-10 22:45:...|
| [72 65 63 69 66 65]|{"sale": "rec-000...|        1|    15|2026-10-10 22:45:...|
|[6A 6F 61 6F 2D 7...|{"sale": "joa-000...|        1|    16|2026-10-10 22:45:...|
|[6A 6F 61 6F 2D 7...|{"sale": "joa-000...|        1|    17|2026-10-10 22:45:...|
|[6A 6F 61 6F 2D 7...|{"sale": "joa-000...|        1|    18|2026-10-10 22:45:...|
|[6A 6F 61 6F 2D 7...|{"sale": "joa-000...|        1|    19|2026-10-10 22:45:...|
+--------------------+--------------------+---------+------+--------------------+
only showing top 20 rows
```

It took about fifteen seconds here, most of it starting Java, and the first run takes longer by
the download.

## What came out

The schema came first, then one batch. **The schema is the same seven columns for every Kafka
topic**, whatever is in it:

| column | what it holds |
|---|---|
| `key`, `value` | the record's key and value, as bytes; Spark does not know they are text |
| `topic`, `partition`, `offset` | where the record is, which is also what Spark remembers as its position |
| `timestamp`, `timestampType` | the record's Kafka timestamp, and whether the producer set it or the broker did |

The `key` column shows the problem the cast solves for the value: `[6E 61 74 61 6C]` is `natal` in
bytes. The `timestamp` column is the other trap, and it is lesson 9's subject: it is the moment
`tills.py` handed the record to Kafka, today, while the moment of the sale is `at`, inside the
JSON, on 2 March 2026. **A window over `timestamp` would count sales by when they were sent.** The
next section takes `at` out of the value and counts by that.

Only twenty rows were printed, all from partition 1, because the console shows twenty by default.
Partition 1 holds most of the sales: four of the five shops' keys land there and only `caruaru`
lands in partition 0, which lesson 3 explains. That will matter in the next section.

The connector's download went into your home directory:

```
ubuntu@stream:~/work$ ls ~/.ivy2.5.2/jars
com.google.code.findbugs_jsr305-3.0.0.jar
org.apache.commons_commons-pool2-2.12.1.jar
org.apache.hadoop_hadoop-client-api-3.4.2.jar
org.apache.hadoop_hadoop-client-runtime-3.4.2.jar
org.apache.kafka_kafka-clients-3.9.1.jar
org.apache.spark_spark-sql-kafka-0-10_2.13-4.1.3.jar
org.apache.spark_spark-token-provider-kafka-0-10_2.13-4.1.3.jar
org.lz4_lz4-java-1.8.0.jar
org.scala-lang.modules_scala-parallel-collections_2.13-1.2.0.jar
org.slf4j_slf4j-api-2.0.17.jar
org.xerial.snappy_snappy-java-1.1.10.8.jar
```

Eleven files: the connector, Kafka's own Java client that it uses to talk to the broker, and the
libraries those two need. Nothing in it is a consumer group, and section 06 says why Spark does not
need one.
