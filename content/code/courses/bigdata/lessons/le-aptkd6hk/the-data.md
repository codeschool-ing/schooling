---
title: A year of clicks, written by a program you can read
version: 1
---

**Every row of data in this course is written by one short program, and you run it yourself.** It
is a Spark program, so it also tests the cluster you have just started: if it finishes, the master
handed out cores, the workers started their processes and the data came back. Lesson 5 explains the
API it uses; for now, read it for what it writes.

Save it as `~/big/generate.py`:

```schooling-example
{
  "language": "python",
  "file": "generate.py",
  "parts": [
    {
      "code": "\"\"\"Write a year of Ponto Final's website clickstream, and its book list.\n\nEvery value comes from a hash of the row number, so the same command writes\nthe same rows on every machine. Run it with spark-submit.\n\"\"\"\nimport sys\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "EVENTS = int(sys.argv[1]) if len(sys.argv) > 1 else 24_000_000\nOUT = \"data/raw\"\n\nspark = SparkSession.builder.appName(\"generate\").getOrCreate()\n\n\n",
      "note": "How many events to write, 24 million unless the command line says otherwise. Section 06 says when to ask for fewer."
    },
    {
      "code": "def u(seed):\n    \"\"\"A number in [0, 1) drawn from the row number and a seed.\"\"\"\n    return F.pmod(F.xxhash64(\"id\", F.lit(seed)), F.lit(1_000_000)) / 1_000_000\n\n\nSECONDS_2025 = 365 * 24 * 3600\nstart = F.lit(\"2025-01-01 00:00:00\").cast(\"timestamp\")\n\n",
      "note": "**No random numbers.** `xxhash64` of the row number and a seed gives the same value on every machine and every run, so your data is Ana's data, row for row."
    },
    {
      "code": "clicks = (\n    spark.range(EVENTS)\n    .withColumn(\"ts\", F.timestamp_seconds(\n        F.unix_timestamp(start) + F.floor(F.col(\"id\") * SECONDS_2025 / EVENTS)))\n    .withColumn(\"session\", F.floor(F.col(\"id\") / 6))\n",
      "note": "`spark.range` makes the row numbers. The events are spread evenly over 2025 in the order of their number, and every six consecutive events share a session."
    },
    {
      "code": "    .withColumn(\"visitor_id\", F.when(u(7) < 0.04, F.lit(\"v0000000\")).otherwise(\n        F.concat(F.lit(\"v\"), F.lpad(\n            (F.pmod(F.xxhash64(\"session\"), F.lit(1_999_999)) + 1).cast(\"string\"), 7, \"0\"))))\n    .withColumn(\"kind\", F.when(u(4) < 0.80, \"view\").when(u(4) < 0.88, \"search\")\n                .when(u(4) < 0.96, \"cart\").otherwise(\"purchase\"))\n",
      "note": "A session belongs to one of two million visitors. **Four events in a hundred belong to `v0000000`**, a crawler that never identifies itself. Lesson 8 is about what one visitor that large does to a job."
    },
    {
      "code": "    .withColumn(\"book_id\", F.when(F.col(\"kind\") == \"search\", F.lit(None))\n                .otherwise(1 + F.floor(3000 * F.pow(u(3), 3))).cast(\"int\"))\n    .withColumn(\"device\", F.when(u(5) < 0.62, \"mobile\").when(u(5) < 0.95, \"desktop\")\n                .otherwise(\"tablet\"))\n    .withColumn(\"day\", F.to_date(\"ts\"))\n    .select(F.col(\"id\").alias(\"event_id\"), \"ts\", \"visitor_id\", \"kind\", \"book_id\",\n            \"device\", \"day\")\n)\n",
      "note": "A search names no book. The others name one of 3,000, and the cube makes low numbers far likelier: book 1 is in about one event in fifteen, the way a bestseller is."
    },
    {
      "code": "(clicks.repartition(\"day\").write.mode(\"overwrite\").partitionBy(\"day\")\n       .option(\"header\", True).option(\"compression\", \"gzip\")\n       .option(\"timestampFormat\", \"yyyy-MM-dd HH:mm:ss\").csv(OUT + \"/clicks\"))\n\n",
      "note": "One gzipped CSV file per day, in a directory named `day=2025-01-01` and so on: the shape a web server's logs land in. Lesson 3 explains the directory names."
    },
    {
      "code": "CATEGORIES = [\"fiction\", \"crime\", \"fantasy\", \"history\", \"science\", \"children\",\n              \"poetry\", \"travel\", \"cookery\", \"business\"]\nbooks = (\n    spark.range(1, 3001).withColumnRenamed(\"id\", \"book_id\")\n    .withColumn(\"category\", F.element_at(F.array(*map(F.lit, CATEGORIES)),\n                (F.pmod(F.xxhash64(\"book_id\", F.lit(1)), F.lit(10)) + 1).cast(\"int\")))\n    .withColumn(\"price_cents\", (2990 + F.pmod(F.xxhash64(\"book_id\", F.lit(2)),\n                                              F.lit(120)) * 100).cast(\"int\"))\n)\nbooks.coalesce(1).write.mode(\"overwrite\").option(\"header\", True).csv(OUT + \"/books\")\nprint(f\"wrote {EVENTS:,} events and {books.count():,} books under {OUT}/\")\n",
      "note": "The shop's 3,000 books, with a category and a price in cents, in one small CSV file."
    }
  ]
}
```

Run it with `spark-submit`, the command that hands a Python program to the cluster:

```
ana@lab:~/big$ time spark-submit generate.py
WARNING: Using incubator modules: jdk.incubator.vector
wrote 24,000,000 events and 3,000 books under data/raw/
04:21:04 WARN Dispatcher: Message RemoteProcessDisconnected(127.0.0.1:49650) dropped. Could not find OutputCommitCoordinator.

real	1m4.011s
user	0m23.271s
sys	0m1.393s
```

A little over a minute, on three workers of one core each. What it wrote:

```
ana@lab:~/big$ ls data/raw/clicks | head -3
_SUCCESS
day=2025-01-01
day=2025-01-02
ana@lab:~/big$ ls data/raw/clicks | wc -l
366
ana@lab:~/big$ du -sh data/raw/clicks data/raw/books
243M	data/raw/clicks
68K	data/raw/books
ana@lab:~/big$ zcat data/raw/clicks/*/*.gz | wc -c
1291255017
```

One directory per day of 2025, 365 of them, each with one compressed CSV file in it; the 366th
name is `_SUCCESS`, an empty file Spark writes when a job finishes, so that a reader can tell a
complete output from one still being written. The 24 million events take 243 MB compressed, and
`zcat` counts 1,291,255,017 bytes unpacked, about five times as much. The first rows of one day:

```
ana@lab:~/big$ zcat data/raw/clicks/day=2025-03-14/*.gz | head -5
event_id,ts,visitor_id,kind,book_id,device
4734247,2025-03-14 00:00:00,v0094455,view,1967,mobile
4734248,2025-03-14 00:00:01,v0094455,view,786,desktop
4734249,2025-03-14 00:00:03,v0094455,view,37,desktop
4734250,2025-03-14 00:00:04,v0094455,search,,desktop
```

**Each row is one thing a visitor did**: when, who, what kind of event, which book if any, and on
what device. Row 0 is the first second of 2025 and the last row is the last second, so the
numbers on the left also tell you how far into the year an event is. The `books` directory holds
the 3,000 books, with a category and a price in cents.

**The data is synthetic, and it says so.** No person is in it, and the visitor ids name nobody. The
shape is what makes it useful: most events are views, a few are purchases, a handful of books
take a large share of the attention, and one "visitor" is a crawler responsible for four events in
every hundred. Each of those features is there because a later lesson needs it.
