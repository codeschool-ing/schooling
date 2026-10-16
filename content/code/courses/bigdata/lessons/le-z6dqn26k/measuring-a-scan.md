---
title: Measuring what a query read
version: 1
---

**A plan says what Spark intends to read. The driver's metrics say what it did.** Lesson 3 read
the locality of tasks from the driver's REST interface; the same interface keeps, for every SQL
query, each plan node's metrics. A small module reads the scan's. Save it as `~/big/lastscan.py`:

```schooling-example
{
  "language": "python",
  "file": "lastscan.py",
  "parts": [
    {
      "code": "\"\"\"What the last query's file scans did, from the driver's REST interface.\"\"\"\nimport json\nimport time\nimport urllib.request\n\n\n"
    },
    {
      "code": "def scans(spark):\n    sc = spark.sparkContext\n    url = (f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}\"\n           \"/sql?details=true&planDescription=false\")\n",
      "note": "**The driver keeps, for every SQL query it ran, the plan and the metrics each step of it reported.** This asks for the newest query and prints three numbers from each of its file scans."
    },
    {
      "code": "    time.sleep(1)\n    last = max(json.load(urllib.request.urlopen(url)), key=lambda q: q[\"id\"])\n    for node in last[\"nodes\"]:\n        if node[\"nodeName\"].startswith(\"Scan\"):\n            m = {x[\"name\"]: x[\"value\"] for x in node[\"metrics\"]}\n",
      "note": "The metrics arrive a moment after the query ends, so the function waits a second first."
    },
    {
      "code": "            print(f\"  {m.get('number of files read')} files of \"\n                  f\"{m.get('size of files read')}, {m.get('number of output rows')} rows\")\n",
      "note": "How many files the scan opened, their total size on disk, and how many rows it handed to the rest of the plan."
    }
  ]
}
```

And four questions about purchases that differ in what they need from the files. Save this as
`~/big/pruning.py`; it imports the module above from the same directory:

```schooling-example
{
  "language": "python",
  "file": "pruning.py",
  "parts": [
    {
      "code": "\"\"\"Four questions about purchases, and what each one read.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nfrom lastscan import scans\n\nspark = SparkSession.builder.appName(\"pruning\").getOrCreate()\n"
    },
    {
      "code": "def run(label, make):\n    make().collect()\n    start = time.time()\n    answer = make().collect()[0][0]\n    print(label, answer, f\"in {time.time() - start:.1f} s\")\n    scans(spark)\n\n\ndef purchases():\n    return spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\n\n\n",
      "note": "A helper that builds a query twice and runs each, keeping the second time, so that warming up is not counted, then prints what its scan did. The query is built afresh each time because Spark reuses the intermediate files of a query it has already run, which lesson 9 explains, and that would time nothing."
    },
    {
      "code": "run(\"every column:\", lambda: purchases().agg(\n    F.max(F.length(F.concat_ws(\"|\", *purchases().columns)))))\n",
      "note": "**Every column**: the longest purchase written out as text, every column joined by `|`, which needs every column of every purchase."
    },
    {
      "code": "run(\"one column:  \", lambda: purchases().agg(F.countDistinct(\"book_id\")))\n",
      "note": "**One column**: a count of distinct books reads `book_id`, and `kind` for the filter."
    },
    {
      "code": "run(\"one day:     \", lambda: purchases().where(F.col(\"day\") == \"2025-03-14\")\n                                        .agg(F.countDistinct(\"book_id\")))\n\n",
      "note": "**One day**: the same count for 14 March. `day` is the partition column."
    },
    {
      "code": "is_pi_day = F.udf(lambda d: d.month == 3 and d.day == 14, \"boolean\")\nrun(\"one day, udf:\", lambda: purchases().where(is_pi_day(\"day\"))\n                                        .agg(F.countDistinct(\"book_id\")))\n",
      "note": "**The same day, chosen by a Python function** that does exactly what `== \"2025-03-14\"` does."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit pruning.py
WARNING: Using incubator modules: jdk.incubator.vector
every column: 70 in 14.9 s
  365 files of 388.8 MiB, 24,000,000 rows
one column:   3000 in 6.5 s
  365 files of 388.8 MiB, 24,000,000 rows
one day:      1304 in 3.1 s
  1 files of 1098.7 KiB, 65,753 rows
one day, udf: 1304 in 6.7 s
  365 files of 388.8 MiB, 24,000,000 rows
```

Four answers, and four very different scans:

- **Every column** opened all 365 files and took the longest.
- **One column** opened all 365 files, the same 388.8 MiB by the metric, and took about half the time.
- **One day** opened one file of 1 MiB and handed on 65,753 rows instead of 24 million.
- **One day, chosen by a Python function**, opened all 365 files again, for the same answer as the
  line above it.

**A warning about the metric's name.** *Size of files read* is the size of the files the scan
opened, not the bytes it read from them. A Parquet file can be opened and read in part, which is
exactly what the next section is about, and this number cannot see it; the time can. Sections 06,
07 and 08 explain the three differences.
