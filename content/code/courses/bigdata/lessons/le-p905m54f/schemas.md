---
title: Declare the schema, or pay for a guess
version: 1
---

**A CSV file has no types, so somebody has to supply them**: Spark, by reading the data and
guessing, or you, by saying. The difference is measurable. Save this as `~/big/schema.py`:

```schooling-example
{
  "language": "python",
  "file": "schema.py",
  "parts": [
    {
      "code": "\"\"\"Reading the same CSV with an inferred schema and with a declared one.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"schema\").getOrCreate()\n\n"
    },
    {
      "code": "t = time.time()\nguessed = (spark.read.option(\"header\", True).option(\"inferSchema\", True)\n           .csv(\"data/raw/clicks\"))\nprint(f\"inferred: {time.time() - t:.1f} s\")\nguessed.printSchema()\n\n",
      "note": "**`inferSchema` makes Spark read the whole input once just to guess each column's type**, before the job you asked for has started."
    },
    {
      "code": "SCHEMA = (\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n          \"book_id INT, device STRING\")\nt = time.time()\ndeclared = spark.read.option(\"header\", True).schema(SCHEMA).csv(\"data/raw/clicks\")\nprint(f\"declared: {time.time() - t:.1f} s\")\ndeclared.printSchema()\n",
      "note": "A declared schema, as one string of names and types, costs nothing to read. It also says `LONG` for an id that will outgrow an `int`, which no guess can know."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit schema.py
WARNING: Using incubator modules: jdk.incubator.vector
inferred: 44.1 s
root
 |-- event_id: integer (nullable = true)
 |-- ts: timestamp (nullable = true)
 |-- visitor_id: string (nullable = true)
 |-- kind: string (nullable = true)
 |-- book_id: integer (nullable = true)
 |-- device: string (nullable = true)
 |-- day: date (nullable = true)

declared: 4.7 s
root
 |-- event_id: long (nullable = true)
 |-- ts: timestamp (nullable = true)
 |-- visitor_id: string (nullable = true)
 |-- kind: string (nullable = true)
 |-- book_id: integer (nullable = true)
 |-- device: string (nullable = true)
 |-- day: date (nullable = true)
```

**The guess cost a full read of 1.3 GB of text before the real job could start**:
44.1 seconds against 4.7. The
declared schema cost a listing of the directories. Both give the same columns, with one difference
worth noticing: the guess made `event_id` an `integer`, because no value in 2025 was larger than an
`int` holds, and next year's file may not agree. A declared `LONG` is right for both.

Three more reasons to declare, beyond the time:

- **A guess changes when the data does.** One malformed row, an empty column in a new file, a date
  in a different format, and the inferred type changes without anybody deciding it, and every job
  downstream sees a different table.
- **A declaration fails loudly where a guess fails quietly.** With a declared schema, a value that
  does not fit becomes `null`, or, with `.option("mode", "FAILFAST")`, stops the job with the row
  that broke it.
- **It documents the data.** The one string in `schema.py` is the clearest description of the clicks
  anywhere in this course.

Formats that store the schema in the file, such as Parquet in section 08 and lesson 10, make the
question go away: the types are written once, by the job that wrote the data, and every reader gets
them for free.
