---
title: Why the silver layer came out larger
version: 1
---

**Lesson 5 left two surprises: the Parquet copy of the clicks was larger than the gzipped CSV, 396
MB against 243, and the job that wrote it took longer than any before.** This program writes
January's 2 million rows seven ways and measures each one's size, the time to write it and the time
to read every column back. Save it as `~/big/codecs.py`:

```schooling-example
{
  "language": "python",
  "file": "codecs.py",
  "parts": [
    {
      "code": "\"\"\"January's clicks written in seven ways, and what each costs on disk and to read.\"\"\"\nimport os\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"codecs\").getOrCreate()\njanuary = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"day\") < \"2025-02-01\")\n\n\ndef mib(path):\n    return sum(os.path.getsize(os.path.join(d, f)) for d, _, names in os.walk(path)\n               for f in names if f.startswith(\"part-\")) / 2**20\n\n\n"
    },
    {
      "code": "def written(label, fmt, **options):\n    path = f\"data/tmp/{label.replace(', ', '-').replace(' ', '-')}\"\n    start = time.time()\n    january.write.mode(\"overwrite\").options(**options).partitionBy(\"day\").format(fmt).save(path)\n    wrote = time.time() - start\n    back = spark.read.format(fmt).load(path)\n    start = time.time()\n    back.agg(F.max(F.length(F.concat_ws(\"|\", *back.columns)))).collect()\n    print(f\"{label:24} {mib(path):7.1f} MiB, written in {wrote:4.1f} s, read in\"\n          f\" {time.time() - start:4.1f} s\")\n\n\n",
      "note": "**Each way is written, measured, and read back** with a query that needs every column, so that reading costs what decompressing and decoding the whole file costs."
    },
    {
      "code": "january.write.mode(\"overwrite\").parquet(\"data/tmp/warm-up\")\n\n",
      "note": "**The first write of a program also warms up the JVM**, so one is made and thrown away before any is timed."
    },
    {
      "code": "SCHEMA = (\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n          \"book_id INT, device STRING\")\ncsv = (spark.read.option(\"header\", True).schema(SCHEMA).csv(\"data/raw/clicks\")\n       .where(F.col(\"day\") < \"2025-02-01\"))\nraw = sum(mib(f\"data/raw/clicks/day=2025-01-{d:02}\") for d in range(1, 32))\nstart = time.time()\ncsv.agg(F.max(F.length(F.concat_ws(\"|\", *csv.columns)))).collect()\nprint(f\"{'csv, gzip (raw)':24} {raw:7.1f} MiB,\"\n      f\" {'':17} read in {time.time() - start:4.1f} s\")\nwritten(\"parquet, snappy\", \"parquet\", compression=\"snappy\")\nwritten(\"parquet, none\", \"parquet\", compression=\"none\")\nwritten(\"parquet, gzip\", \"parquet\", compression=\"gzip\")\nwritten(\"parquet, zstd\", \"parquet\", compression=\"zstd\")\n",
      "note": "**The raw layer's January for comparison**: the same rows as gzipped CSV, as lesson 1 wrote them, read with lesson 5's schema and the same query as the rest."
    },
    {
      "code": "spark.conf.set(\"spark.sql.parquet.outputTimestampType\", \"TIMESTAMP_MICROS\")\nwritten(\"parquet, zstd, micros\", \"parquet\", compression=\"zstd\")\n",
      "note": "**Timestamps as 64-bit integers.** Spark writes a timestamp in Parquet as `INT96` unless told otherwise, a 12-byte type kept for old readers that no encoding can shrink. `TIMESTAMP_MICROS` stores microseconds in an ordinary 64-bit integer."
    },
    {
      "code": "written(\"parquet v2, zstd, micros\", \"parquet\", compression=\"zstd\",\n        **{\"parquet.writer.version\": \"v2\"})\n",
      "note": "**And version 2 of Parquet's page format**: it adds delta encodings, which store each value as its difference from the one before, the right shape for ids and timestamps in order."
    },
    {
      "code": "print(\"orc codec:\", spark.conf.get(\"spark.sql.orc.compression.codec\"))\nwritten(\"orc\", \"orc\")\n",
      "note": "**ORC**, the other columnar format, at its default codec in this Spark."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit codecs.py
WARNING: Using incubator modules: jdk.incubator.vector
csv, gzip (raw)             20.1 MiB,                   read in  6.8 s
parquet, snappy             33.0 MiB, written in  5.9 s, read in  2.8 s
parquet, none               54.2 MiB, written in  4.1 s, read in  2.0 s
parquet, gzip               21.4 MiB, written in  4.4 s, read in  2.2 s
parquet, zstd               19.6 MiB, written in  3.0 s, read in  2.1 s
parquet, zstd, micros       14.4 MiB, written in  2.4 s, read in  2.1 s
parquet v2, zstd, micros     7.2 MiB, written in  3.3 s, read in  2.1 s
orc codec: zstd
orc                          6.1 MiB, written in  5.2 s, read in  4.3 s
```

**The first answer is the codec.** Spark compresses Parquet with Snappy by default, which is built to
be fast rather than small: 33.0 MiB, where gzip gets the same file to 21.4 and zstd to 19.6. Gzipped
CSV was 20.1. So the CSV was not beaten by a worse format; it was compressed by a stronger codec.

**The second is the timestamps.** Spark writes a timestamp in Parquet as `INT96`, 12 bytes, a type
kept for readers from Parquet's early years. No encoding applies to it, so every row's `ts` is
twelve bytes of mostly the same digits for the codec to find. Written as `TIMESTAMP_MICROS`, a
64-bit integer, the same zstd file fell from 19.6 MiB to 14.4.

**The third is the page format.** Version 2 adds delta encodings, and with them the file fell to
7.2 MiB, a third of the gzipped CSV and less than a quarter of the silver layer's format. The next
section opens it to see where the space went.

**And the time.** Every Parquet write here took between 2.4 and 5.9 seconds for a month, and every
read of all columns between 2.0 and 2.8. Reading the same month from gzipped CSV took 6.8 seconds,
more than twice the slowest Parquet read, before writing anything. Lesson 5's job read and parsed every line of text of the year, which is what the
raw layer costs every time it is read, and is why the silver layer exists.

**ORC, the other columnar format, came out smallest of all**, 6.1 MiB at its default codec, which in
this Spark is zstd. Section 08 is about it.
