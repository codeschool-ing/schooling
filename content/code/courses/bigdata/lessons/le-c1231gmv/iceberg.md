---
title: Apache Iceberg
version: 1
---

**Iceberg came from Netflix, and its first concern was tables of millions of files**, where even
listing a directory is too slow. Instead of a log replayed from the start, each commit writes a new
*metadata file* that points to a *manifest list*, which points to *manifests*, which list data files
with statistics for each. A catalogue keeps one pointer per table, to the current metadata file, and a
commit is swapping that pointer. Reading a table never lists a directory.

Iceberg tables live in a *catalogue*, and this program uses the simplest one, a directory. Save it as
`~/big/iceberg_basics.py`:

```schooling-example
{
  "language": "python",
  "file": "iceberg_basics.py",
  "parts": [
    {
      "code": "\"\"\"An Iceberg table of purchases, partitioned by day without a day column.\"\"\"\nimport json\nimport os\nimport time\nimport urllib.request\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "spark = (SparkSession.builder.appName(\"iceberg basics\")\n         .config(\"spark.sql.extensions\",\n                 \"org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions\")\n         .config(\"spark.sql.catalog.lab\", \"org.apache.iceberg.spark.SparkCatalog\")\n         .config(\"spark.sql.catalog.lab.type\", \"hadoop\")\n         .config(\"spark.sql.catalog.lab.warehouse\", \"file://\" + os.path.abspath(\"data/iceberg\"))\n         .getOrCreate())\npurchases = (spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\n             .select(\"event_id\", \"ts\", \"visitor_id\", \"book_id\"))\n\n",
      "note": "**A catalog named `lab`**, of the simplest kind Iceberg has: a directory, where each table keeps its own metadata. Production catalogs are services (Hive's metastore, a REST catalog, AWS Glue); the tables are the same."
    },
    {
      "code": "spark.sql(\"DROP TABLE IF EXISTS lab.shop.purchases\")\nspark.sql(\"\"\"CREATE TABLE lab.shop.purchases\n             (event_id BIGINT, ts TIMESTAMP, visitor_id STRING, book_id INT)\n             USING iceberg PARTITIONED BY (days(ts))\"\"\")\npurchases.where(F.col(\"ts\") < \"2025-02-01\").writeTo(\"lab.shop.purchases\").append()\npurchases.where((F.col(\"ts\") >= \"2025-02-01\") & (F.col(\"ts\") < \"2025-03-01\")) \\\n    .writeTo(\"lab.shop.purchases\").append()\nspark.sql(\"DELETE FROM lab.shop.purchases WHERE visitor_id = 'v0000000'\")\n\n",
      "note": "**Hidden partitioning**: the table is partitioned by `days(ts)`, a function of a column it already has. Nobody writes a `day` column, and a query that filters on `ts` is pruned by day without knowing the table is partitioned."
    },
    {
      "code": "spark.sql(\"\"\"SELECT snapshot_id, operation,\n                    summary['added-data-files'] AS added,\n                    summary['deleted-data-files'] AS deleted,\n                    summary['total-records'] AS records\n             FROM lab.shop.purchases.snapshots ORDER BY committed_at\"\"\").show()\nfirst = spark.sql(\"SELECT min_by(snapshot_id, committed_at) FROM lab.shop.purchases.snapshots\").first()[0]\n",
      "note": "**Every commit is a snapshot**, and the table answers questions about itself through metadata tables named after it."
    },
    {
      "code": "print(\"first snapshot:\", spark.sql(\n    f\"SELECT count(*) FROM lab.shop.purchases VERSION AS OF {first}\").first()[0], \"purchases\")\n\n",
      "note": "**Time travel by snapshot id**: the table after the first append only."
    },
    {
      "code": "day = spark.sql(\"\"\"SELECT count(*) FROM lab.shop.purchases\n                   WHERE ts >= '2025-02-14' AND ts < '2025-02-15'\"\"\").first()[0]\nprint(\"14 February:\", day, \"purchases\")\ntime.sleep(1)\nsc = spark.sparkContext\nurl = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/sql?details=true&planDescription=false\"\nlast = max(json.load(urllib.request.urlopen(url)), key=lambda q: q[\"id\"])\nfor node in last[\"nodes\"]:\n    if node[\"nodeName\"].startswith(\"BatchScan\"):\n        m = {x[\"name\"]: x[\"value\"] for x in node[\"metrics\"]}\n        print(f\"  {m['number of result data files']} data files read,\"\n              f\" {m['number of skipped data files']} skipped\")\n",
      "note": "**A filter on `ts` alone**, then the scan's own metrics from the driver's REST interface, as lesson 6's `lastscan.py` read them for Parquet: how many data files the scan read and how many it skipped."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit --jars $HOME/jars/iceberg-spark-runtime-4.1_2.13-1.12.0.jar iceberg_basics.py
WARNING: Using incubator modules: jdk.incubator.vector
+-------------------+---------+-----+-------+-------+
|        snapshot_id|operation|added|deleted|records|
+-------------------+---------+-----+-------+-------+
|4290993200430658696|   append|   32|   NULL|  80988|
|2530551120499753072|   append|   29|   NULL| 154822|
|9086536705081289043|overwrite|   60|     61| 148537|
+-------------------+---------+-----+-------+-------+

first snapshot: 80988 purchases
14 February: 2469 purchases
  2 data files read, 58 skipped
```

**Three snapshots, one per commit**, each with its own id, and the delete was recorded as an
`overwrite` that removed 61 files and added 60: Iceberg, like Delta, rewrote the files holding the
crawler's rows. Time travel uses the snapshot id instead of a version number.

**January was written as 32 files, not 31**, and the reason is a detail worth knowing. `days(ts)`
cuts by days in UTC, and the lab's timestamps are São Paulo's, three hours behind: a local day
straddles two UTC days, and January's purchases, from local midnight on the 1st to local midnight on
the 1st of February, touch 32 of them. **The query for 14 February read two files for the same
reason**, and skipped the other 58 without opening them. It never mentioned a partition; Iceberg
turned the filter on `ts` into a filter on the days. That is *hidden partitioning*, and it means a
table's partitioning can be changed later without changing a single query.

The metadata, on disk:

```
ana@lab:~/big$ ls data/iceberg/shop/purchases/metadata | grep -v crc
633faf96-6df9-4029-8850-a257690c54aa-m0.avro
633faf96-6df9-4029-8850-a257690c54aa-m1.avro
633faf96-6df9-4029-8850-a257690c54aa-m2.avro
a3e8d1bf-a24f-47af-aaf1-b44789c5383d-m0.avro
a6636b0e-b3bb-45d9-8455-a4dc91686f17-m0.avro
snap-2530551120499753072-1-a6636b0e-b3bb-45d9-8455-a4dc91686f17.avro
snap-4290993200430658696-1-a3e8d1bf-a24f-47af-aaf1-b44789c5383d.avro
snap-9086536705081289043-1-633faf96-6df9-4029-8850-a257690c54aa.avro
v1.metadata.json
v2.metadata.json
v3.metadata.json
v4.metadata.json
version-hint.text
```

Four versions of the table's metadata, `v1` for the creation and one per commit. A manifest list per
snapshot, the `snap-` files, and the manifests they point to, the `-m` files, all of them Avro. And
`version-hint.text`, the pointer this directory catalogue keeps, which holds the number of the
current
version. **Production catalogues are services**: Hive's metastore of
lesson 12, AWS Glue, Nessie, or any server speaking Iceberg's REST catalogue protocol, which is what
lets engines other than Spark find and commit to the same tables.
