---
title: What a directory of files cannot do
version: 1
---

**A lake so far has been a directory of Parquet files, and a directory is not a table.** It has no
record of what was written when, no way to change a row without rewriting files by hand, and nothing
to stop two programs from writing at once. Lesson 3 named those gaps and lesson 5 warned that a
nightly append run twice doubles a day. Save this as `~/big/plain_append.py`:

```schooling-example
{
  "language": "python",
  "file": "plain_append.py",
  "parts": [
    {
      "code": "\"\"\"January's purchases appended to a plain Parquet directory, by a job that ran twice.\"\"\"\nimport os\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"plain append\").getOrCreate()\nPATH = \"data/plain/purchases\"\njanuary = (spark.read.parquet(\"data/silver/clicks\")\n           .where((F.col(\"kind\") == \"purchase\") & (F.col(\"day\") < \"2025-02-01\")))\n\n"
    },
    {
      "code": "for run in (1, 2):\n    january.write.mode(\"append\").parquet(PATH)\n    files = sorted(f for f in os.listdir(PATH) if f.endswith(\".parquet\"))\n    print(f\"after run {run}: {spark.read.parquet(PATH).count()} purchases in {len(files)} files\")\n",
      "note": "**The same nightly append, run twice**, as happens when a scheduler retries a job that had in fact finished."
    },
    {
      "code": "print(\"\\n\".join(files))\n",
      "note": "**What the directory knows about it**: file names, whose middle part is shared by the files of one write, and nothing that says which write came first or that the second repeats the first."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit plain_append.py
WARNING: Using incubator modules: jdk.incubator.vector
after run 1: 80988 purchases in 3 files
after run 2: 161976 purchases in 6 files
part-00000-afd13b26-e03f-473c-84d9-0f1d6f8e47cf-c000.snappy.parquet
part-00000-b90a94fc-2c0e-4510-970b-915b3ed49f87-c000.snappy.parquet
part-00001-afd13b26-e03f-473c-84d9-0f1d6f8e47cf-c000.snappy.parquet
part-00001-b90a94fc-2c0e-4510-970b-915b3ed49f87-c000.snappy.parquet
part-00002-afd13b26-e03f-473c-84d9-0f1d6f8e47cf-c000.snappy.parquet
part-00002-b90a94fc-2c0e-4510-970b-915b3ed49f87-c000.snappy.parquet
```

**Twice the purchases, and nothing in the directory says so.** The second run wrote three more files
beside the first three. Whoever reads the directory gets every file in it, so every report on January
now counts each purchase twice, and the only way back is to know which files to delete.

The same directory has the other gaps too:

- **No transactions.** A job that fails halfway through a write leaves the files it finished, and a
  reader that lists the directory during a write sees some of the new files and not others.
- **No changes to rows.** Deleting one visitor's events, a request privacy laws make routine,
  means finding every file that holds them and rewriting each one, by hand, while nobody
  reads.
- **No history.** Once a file is overwritten, what the table said yesterday is gone.
- **No schema of its own.** Each file carries its schema; nothing stops tomorrow's files from having
  a different one.

**An open table format fixes all four the same way: a log of commits beside the data files.** A
table is the set of files the log says it has, as of the latest commit, and a write is not visible
until its commit is. Delta Lake, Apache Iceberg and Apache Hudi are three designs of that idea, all
open, all built on Parquet files, and all readable by Spark.
