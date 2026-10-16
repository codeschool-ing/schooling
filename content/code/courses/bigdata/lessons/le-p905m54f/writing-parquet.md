---
title: Writing the silver layer
version: 1
---

**Every lesson so far has read the same 365 gzipped CSV files and paid to parse text each time.**
Lesson 3 called that the raw layer, kept as it arrived. This section writes the next layer, the same
events typed and stored in Parquet, a columnar format that lesson 10 takes apart. The rest of the
course reads it. Save this as `~/big/to_parquet.py`:

```schooling-example
{
  "language": "python",
  "file": "to_parquet.py",
  "parts": [
    {
      "code": "\"\"\"Write the raw clicks and books again, typed, as Parquet: the silver layer.\"\"\"\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"to parquet\").getOrCreate()\nSCHEMA = (\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n          \"book_id INT, device STRING\")\n"
    },
    {
      "code": "clicks = spark.read.option(\"header\", True).schema(SCHEMA).csv(\"data/raw/clicks\")\n",
      "note": "The raw layer, read with the declared schema. The `day` column comes from the directory names."
    },
    {
      "code": "clicks.write.mode(\"overwrite\").partitionBy(\"day\").parquet(\"data/silver/clicks\")\n\nbooks = (spark.read.option(\"header\", True)\n         .schema(\"book_id INT, category STRING, price_cents INT\").csv(\"data/raw/books\"))\nbooks.write.mode(\"overwrite\").parquet(\"data/silver/books\")\n\n",
      "note": "**Written as Parquet, partitioned by day again**: the same layout, with the types stored in the files. `overwrite` replaces whatever is there, so running it twice is safe."
    },
    {
      "code": "print(spark.read.parquet(\"data/silver/clicks\").count(), \"events,\",\n      spark.read.parquet(\"data/silver/books\").count(), \"books\")\n",
      "note": "Read back, to check that nothing was lost."
    }
  ]
}
```

```
ana@lab:~/big$ time spark-submit to_parquet.py
WARNING: Using incubator modules: jdk.incubator.vector
24000000 events, 3000 books

real	1m44.537s
user	0m41.455s
sys	0m2.534s
ana@lab:~/big$ du -sh data/raw/clicks data/silver/clicks
243M	data/raw/clicks
396M	data/silver/clicks
ana@lab:~/big$ ls data/silver/clicks/day=2025-03-14
part-00012-77d3ee8e-f18d-439a-bc6d-1f55b07e48d3.c000.snappy.parquet
```

**24 million events and 3,000 books, read back, so nothing was lost.** The layout is the raw
layer's, one directory per day, now with one Parquet file in each, and the types travel inside the
files: any program that reads `data/silver/clicks` gets `ts` as a timestamp without being told.

Two numbers here will surprise you, and both are lesson 10's. **The Parquet copy is larger than the
gzipped CSV**, 396 MB against 243, although Parquet is supposed to be the compact format; and the
write took longer than any job so far. Lesson 10 measures why, and fixes both by changing how the
files are written rather than what they hold.

**`mode("overwrite")` replaces the output if it exists.** The other modes are `"error"`, the default,
which refuses; `"append"`, which adds files beside the old ones; and `"ignore"`, which does nothing
if the output exists. A nightly job that appends and is run twice by mistake doubles a day's data,
with no error, and lesson 11's table formats are the cure for that too.
