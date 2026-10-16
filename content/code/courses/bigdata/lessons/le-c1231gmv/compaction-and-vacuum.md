---
title: Compaction and vacuum
version: 1
---

**Every commit adds files, and a table written in small commits fills up with small files**, lesson
3's problem again with a log on top. Two commands deal with it, and the second has a price. Save this
as `~/big/delta_maintenance.py`:

```schooling-example
{
  "language": "python",
  "file": "delta_maintenance.py",
  "parts": [
    {
      "code": "\"\"\"A Delta table written one day at a time, then compacted and vacuumed.\"\"\"\nimport os\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = (SparkSession.builder.appName(\"delta maintenance\")\n         .config(\"spark.sql.extensions\", \"io.delta.sql.DeltaSparkSessionExtension\")\n         .config(\"spark.sql.catalog.spark_catalog\",\n                 \"org.apache.spark.sql.delta.catalog.DeltaCatalog\")\n         .getOrCreate())\nPATH = os.path.abspath(\"data/delta/daily\")\nTABLE = f\"delta.`{PATH}`\"\nclicks = spark.read.parquet(\"data/silver/clicks\")\n\n\ndef files():\n    on_disk = len([f for f in os.listdir(PATH) if f.endswith(\".parquet\")])\n    live = spark.sql(f\"DESCRIBE DETAIL {TABLE}\").first().numFiles\n    return f\"{live} files in the table, {on_disk} on disk\"\n\n\n"
    },
    {
      "code": "for d in range(1, 32):\n    (clicks.where(F.col(\"day\") == f\"2025-01-{d:02}\")\n     .write.format(\"delta\").mode(\"overwrite\" if d == 1 else \"append\").save(PATH))\nprint(\"after 31 appends:\", files())\n\n",
      "note": "**January's clicks, appended one day at a time**, as a daily job would: 31 commits, each adding the files its tasks wrote."
    },
    {
      "code": "spark.sql(f\"OPTIMIZE {TABLE}\").select(\"metrics.numFilesAdded\", \"metrics.numFilesRemoved\").show()\nprint(\"after OPTIMIZE:  \", files())\n\n",
      "note": "**`OPTIMIZE` rewrites the small files into large ones**, in a commit of its own. Readers of the table see the new files from that commit on; the old ones are no longer part of it but stay on disk, because older versions still point at them."
    },
    {
      "code": "spark.conf.set(\"spark.databricks.delta.retentionDurationCheck.enabled\", False)\nspark.sql(f\"VACUUM {TABLE} RETAIN 0 HOURS\")\nprint(\"after VACUUM:    \", files())\n\n",
      "note": "**`VACUUM` deletes the files no current version needs.** It refuses to look back less than seven days unless a safety check is switched off, because a reader still running on an old version would lose its files mid-query. Switched off here, so that the effect shows at once."
    },
    {
      "code": "try:\n    spark.sql(f\"SELECT count(DISTINCT visitor_id) FROM {TABLE} VERSION AS OF 0\").show()\nexcept Exception as e:\n    cause = [line for line in str(e).splitlines() if \"FileNotFoundException\" in line][0]\n    print(\"version 0:\", cause.strip()[:150])\n",
      "note": "**And the price**: version 0 is still in the log, and its files are gone. The query counts distinct visitors because a plain `count(*)` is answered from the row counts in the log, without opening a file."
    }
  ]
}
```

The warnings this program prints are long and say nothing new, so this run sends them away:

```
ana@lab:~/big$ spark-submit --jars $HOME/jars/delta-spark_2.13-4.3.1.jar,$HOME/jars/delta-storage-4.3.1.jar delta_maintenance.py 2>/dev/null
after 31 appends: 31 files in the table, 31 on disk
+-------------+---------------+
|numFilesAdded|numFilesRemoved|
+-------------+---------------+
|            1|             31|
+-------------+---------------+

after OPTIMIZE:   1 files in the table, 32 on disk
Deleted 31 files and directories in a total of 1 directories.
after VACUUM:     1 files in the table, 1 on disk
version 0: Caused by: java.io.FileNotFoundException: File file:/home/ana/big/data/delta/daily/part-00000-dea0fa9c-6734-480a-9d56-91c9e7b603ec-c000.snappy.parquet
```

**31 daily commits left 31 files**, and the log adds one more JSON file per commit. `OPTIMIZE`
rewrote them into one, in a commit of its own: from then on the table is one file, and readers that
began before it carry on with the 31 they were given. **Both sets stayed on disk**, 32 files, because
the log's earlier versions still name the old ones.

**`VACUUM` deleted the files no version needed within its retention**, here zero hours, and left one
file. Then version 0, still listed in the log, could not be read: its file was gone. That is the
trade every table format makes. History costs storage for as long as it is kept, and `VACUUM` sets
how long. The default retention is seven days, and the check that refused anything shorter exists
because a long query on an old version, or a job that reads yesterday's version, loses its files
when the retention is shorter than the job.

Two more things `OPTIMIZE` can do: `ZORDER BY (visitor_id)` sorts the rewritten files so that rows
with close values of the named columns share files, lesson 10's sorting with more than one column at
once; and Delta tables can be set to compact small writes as they happen, which trades a slower write
for never accumulating the files in the first place.
