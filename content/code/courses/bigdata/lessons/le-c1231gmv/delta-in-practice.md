---
title: Delta Lake in practice
version: 1
---

**A Delta table is written with `format("delta")` and changed with SQL**, and every change is a
commit. This program builds a table of purchases in three commits, one of them run twice on purpose.
Save it as `~/big/delta_basics.py`:

```schooling-example
{
  "language": "python",
  "file": "delta_basics.py",
  "parts": [
    {
      "code": "\"\"\"A Delta table of purchases: written, appended to, corrected, and read as it was.\"\"\"\nimport os\nimport subprocess\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "spark = (SparkSession.builder.appName(\"delta basics\")\n         .config(\"spark.sql.extensions\", \"io.delta.sql.DeltaSparkSessionExtension\")\n         .config(\"spark.sql.catalog.spark_catalog\",\n                 \"org.apache.spark.sql.delta.catalog.DeltaCatalog\")\n         .getOrCreate())\nPATH = os.path.abspath(\"data/delta/purchases\")\nTABLE = f\"delta.`{PATH}`\"\npurchases = (spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\n             .select(\"event_id\", \"ts\", \"visitor_id\", \"book_id\", \"day\"))\n\n\ndef count(sql_from=TABLE):\n    return spark.sql(f\"SELECT count(*) FROM {sql_from}\").first()[0]\n\n\n",
      "note": "**Two settings make Spark speak Delta**: an extension that adds Delta's SQL commands, and a catalog that knows a Delta table when it sees one. Both have to be set before the session starts."
    },
    {
      "code": "purchases.where(F.col(\"day\") < \"2025-02-01\").write.format(\"delta\").mode(\"overwrite\").save(PATH)\nprint(\"version 0:\", count(), \"purchases\")\n",
      "note": "**Version 0: January, written as Delta.** The data files are ordinary Parquet; what makes it a table is the `_delta_log` directory beside them."
    },
    {
      "code": "february = purchases.where((F.col(\"day\") >= \"2025-02-01\") & (F.col(\"day\") < \"2025-03-01\"))\nfor attempt in (1, 2):\n    (february.write.format(\"delta\").mode(\"append\")\n     .option(\"txnAppId\", \"nightly-purchases\").option(\"txnVersion\", 20250228).save(PATH))\n    print(f\"version 1, attempt {attempt}:\", count(), \"purchases\")\n",
      "note": "**Version 1: February, appended**, with an id for the job and a number for this run of it. Delta records the pair in the log and ignores a second write that brings the same pair, which is what makes a job safe to run twice."
    },
    {
      "code": "spark.sql(f\"DELETE FROM {TABLE} WHERE visitor_id = 'v0000000'\")\nprint(\"version 2:\", count(), \"purchases\")\n\n",
      "note": "**Version 2: one visitor's purchases deleted**, the way a request to be forgotten would be served. In a plain Parquet lake this means finding and rewriting every file that holds them, by hand."
    },
    {
      "code": "print(\"as of version 1:\", count(f\"{TABLE} VERSION AS OF 1\"), \"purchases\")\n\n",
      "note": "**Time travel**: the table as it was at version 1, before the delete, read from the same directory."
    },
    {
      "code": "for row in spark.sql(f\"DESCRIBE HISTORY {TABLE}\").orderBy(\"version\").collect():\n    m = row.operationMetrics\n    added = m.get(\"numFiles\") or m.get(\"numAddedFiles\")\n    print(f\"version {row.version}: {row.operation:7} {added} files added,\"\n          f\" {m.get('numRemovedFiles', '0')} removed\")\n\n",
      "note": "**The history the log keeps**: one line per commit, what it did, and from its metrics the files it added and removed."
    },
    {
      "code": "print(subprocess.run([\"ls\", f\"{PATH}/_delta_log\"], capture_output=True, text=True).stdout,\n      end=\"\")\n",
      "note": "**And the log itself**: one JSON file per commit, numbered."
    }
  ]
}
```

Run it with the two Delta jars:

```
ana@lab:~/big$ spark-submit --jars $HOME/jars/delta-spark_2.13-4.3.1.jar,$HOME/jars/delta-storage-4.3.1.jar delta_basics.py
WARNING: Using incubator modules: jdk.incubator.vector
03:34:50 WARN SparkStringUtils: Truncated the string representation of a plan since it was too large. This behavior can be adjusted by setting 'spark.sql.debug.maxToStringFields'.
version 0: 80988 purchases
version 1, attempt 1: 154822 purchases
version 1, attempt 2: 154822 purchases
03:35:29 WARN DeleteCommand: Could not validate number of records due to missing statistics.
version 2: 148537 purchases
as of version 1: 154822 purchases
version 0: WRITE   3 files added, 0 removed
version 1: WRITE   3 files added, 0 removed
version 2: DELETE  3 files added, 6 removed
00000000000000000000.crc
00000000000000000000.json
00000000000000000001.crc
00000000000000000001.json
00000000000000000002.crc
00000000000000000002.json
_staged_commits
```

**The second attempt at February changed nothing.** The write carried a job id and a run number,
`txnAppId` and `txnVersion`; the first attempt recorded the pair in the log, and the second found it
there and wrote nothing. That is how a Delta job is made safe to retry, and it is the fix for this
lesson's first section, as long as each run of the job brings its own number, the date it is for
being the usual choice. The log itself is the numbered JSON files with a checksum beside each;
`_staged_commits` is for tables whose commits go through a catalogue service, and is empty here.

**The delete rewrote six files into three.** Parquet files cannot be edited, so `DELETE` read every
file that held a row of `v0000000`, wrote new ones without those rows, and committed both lists: the
six removed and the three added. The warning says Delta could not cross-check the number of rows it
deleted against the statistics in its log; the program's own count after the delete is the check
that matters here. The commit for the delete:

```
ana@lab:~/big$ jq -c 'keys[0]' data/delta/purchases/_delta_log/00000000000000000002.json | sort | uniq -c
      3 "add"
      1 "commitInfo"
      6 "remove"
ana@lab:~/big$ jq -c 'select(.add) | .add | {path, size, rows: (.stats | fromjson | .numRecords)}' data/delta/purchases/_delta_log/00000000000000000002.json
{"path":"part-00000-3e3734cc-4c96-4088-ab55-3150e6b5afe2-c000.snappy.parquet","size":1168116,"rows":55171}
{"path":"part-00001-32805b50-e127-4f0a-a4af-7de42ace70b4-c000.snappy.parquet","size":1072544,"rows":50636}
{"path":"part-00002-f9e0992f-fc98-49a3-9084-ba7f3b7933d9-c000.snappy.parquet","size":908023,"rows":42730}
```

**A commit is a list of actions, one JSON object per line**: a `commitInfo` saying who did what, six
`remove`s and three `add`s, each `add` carrying the file's size and its row count. The removed files
are still on disk, which is what lets `VERSION AS OF 1` read the table as it was before the delete:
the log at version 1 names them.

Delta has the rest of SQL's changes too. `UPDATE` rewrites the files holding the rows it changes, and
`MERGE INTO` takes a batch of rows and, row by row, updates the ones whose key matches and inserts
the rest: the upsert, which section 07 does with Hudi.
