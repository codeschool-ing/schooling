---
title: DataFrames: a table with a schema
version: 1
---

**A DataFrame is an RDD whose rows have named columns of declared types**, and the declaration
changes what Spark can do with it. A function in a `map` is opaque: Spark ships it and runs it.
A column expression such as `kind = 'purchase'` is something Spark can read, reorder, push down to
the file reader and compile. Save this as `~/big/explore.py`:

```schooling-example
{
  "language": "python",
  "file": "explore.py",
  "parts": [
    {
      "code": "\"\"\"A first look at the clicks as a DataFrame.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"explore\").getOrCreate()\n"
    },
    {
      "code": "clicks = spark.read.option(\"header\", True).csv(\"data/raw/clicks\")\nclicks.printSchema()\n",
      "note": "**A DataFrame is a table: rows, and named columns with a type each.** With only `header`, Spark takes the names from the first line and calls every column a string."
    },
    {
      "code": "clicks.show(3)\n",
      "note": "`show` is an action: it runs a small job and prints the first rows as a table."
    },
    {
      "code": "(clicks.where(F.col(\"kind\") == \"purchase\")\n       .groupBy(\"device\")\n       .agg(F.count(\"*\").alias(\"purchases\"))\n       .orderBy(F.desc(\"purchases\"))\n       .show())\n",
      "note": "**The question is said in columns, not in functions on lines.** `where`, `groupBy` and `agg` name what to compute; how to split the work is left to Spark."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit explore.py
WARNING: Using incubator modules: jdk.incubator.vector
root
 |-- event_id: string (nullable = true)
 |-- ts: string (nullable = true)
 |-- visitor_id: string (nullable = true)
 |-- kind: string (nullable = true)
 |-- book_id: string (nullable = true)
 |-- device: string (nullable = true)
 |-- day: date (nullable = true)

+--------+-------------------+----------+----+-------+-------+----------+
|event_id|                 ts|visitor_id|kind|book_id| device|       day|
+--------+-------------------+----------+----+-------+-------+----------+
|21209482|2025-11-19 13:27:39|  v1497081|cart|      1| mobile|2025-11-19|
|21172603|2025-11-19 00:00:00|  v1399865|cart|   1139|desktop|2025-11-19|
|21209483|2025-11-19 13:27:40|  v1497081|view|    306| mobile|2025-11-19|
+--------+-------------------+----------+----+-------+-------+----------+
only showing top 3 rows
+-------+---------+
| device|purchases|
+-------+---------+
| mobile|   595590|
|desktop|   316622|
| tablet|    47602|
+-------+---------+
```

The schema came from the header line, and every column is a `string`: a CSV file carries no types,
so a timestamp is text and a book id is text until something says otherwise. The `day` column is
different. It came from the directory names, and Spark recognised the values as dates.

**The question is written in columns.** `where`, `groupBy`, `agg` and `orderBy` read like SQL
because they are the same operations, and they compile to the same plan as the SQL of section 09.
What the program does not say is anything about partitions, pairs or which task gets what; that is
the planner's, and lesson 6 shows the plan it made.

The DataFrame is the API to use by default. The rest of this course does, and drops to the RDD only
where a section says why.
