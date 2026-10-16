---
title: A slow report
version: 1
---

**Ponto Final's analysts want, every morning, the revenue of each category in each month.** The
question joins the purchases to the books and adds up prices, and every lesson of this course has
done a piece of it. This program answers it as it was first written, with four mistakes that each
appeared in an earlier lesson, and a flag to put each one back. Save it as `~/big/report.py`:

```schooling-example
{
  "language": "python",
  "file": "report.py",
  "parts": [
    {
      "code": "\"\"\"Revenue per category per month: the report Ponto Final's analysts ask for every morning.\"\"\"\nimport argparse\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "parser = argparse.ArgumentParser()\nparser.add_argument(\"--csv\", action=\"store_true\", help=\"read the raw CSV instead of the silver layer\")\nparser.add_argument(\"--udf\", action=\"store_true\", help=\"take the month with a Python function\")\nparser.add_argument(\"--partitions\", type=int, default=0, help=\"fix the shuffle partitions, AQE off\")\nparser.add_argument(\"--no-broadcast\", action=\"store_true\", help=\"forbid broadcasting the books\")\nargs = parser.parse_args()\n\nspark = SparkSession.builder.appName(\"report\").getOrCreate()\nif args.partitions:\n    spark.conf.set(\"spark.sql.adaptive.enabled\", False)\n    spark.conf.set(\"spark.sql.shuffle.partitions\", args.partitions)\nif args.no_broadcast:\n    spark.conf.set(\"spark.sql.autoBroadcastJoinThreshold\", -1)\n\nif args.csv:\n    clicks = (spark.read.option(\"header\", True)\n              .schema(\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n                      \"book_id INT, device STRING\")\n              .csv(\"data/raw/clicks\"))\nelse:\n    clicks = spark.read.parquet(\"data/silver/clicks\")\nbooks = spark.read.parquet(\"data/silver/books\")\n\n",
      "note": "**Each flag puts back one mistake**, so that the same program can be run as it was first written and then with each mistake removed in turn."
    },
    {
      "code": "if args.udf:\n    month = F.udf(lambda ts: ts.strftime(\"%Y-%m\"), \"string\")(\"ts\")\nelse:\n    month = F.date_format(F.date_trunc(\"month\", \"ts\"), \"yyyy-MM\")\n\nstart = time.time()\nreport = (clicks.where(F.col(\"kind\") == \"purchase\")\n          .join(books, \"book_id\")\n          .groupBy(month.alias(\"month\"), \"category\")\n          .agg(F.count(\"*\").alias(\"purchases\"), F.sum(\"price_cents\").alias(\"cents\"))\n          .orderBy(\"month\", F.desc(\"cents\")))\nrows = report.collect()\nprint(f\"{len(rows)} rows in {time.time() - start:.1f} s; top of January:\",\n      [(r.category, r.cents // 100) for r in rows[:2]])\n",
      "note": "**The month**, either with the built-in `date_trunc`, which Catalyst understands and runs in the JVM, or with a Python function, which sends every purchase to a Python worker and back."
    }
  ]
}
```

The flags, and the lesson each mistake comes from:

| flag | the mistake | where the course measured it |
|---|---|---|
| `--csv` | reading the raw layer's gzipped CSV instead of the silver Parquet | lessons 5 and 10 |
| `--udf` | taking the month with a Python function instead of a built-in one | lesson 6 |
| `--partitions 2000` | a fixed number of shuffle partitions, with adaptive execution off | lesson 7 |
| `--no-broadcast` | forbidding the broadcast of a 3,000-row table | lesson 8 |

With all four, as the report ran for months before anybody looked:

```
ana@lab:~/big$ spark-submit report.py --csv --udf --partitions 2000 --no-broadcast 2>/dev/null
120 rows in 131.1 s; top of January: [('poetry', 997352), ('science', 877502)]
```

**Two minutes and eleven seconds for 120 rows.** The answer is right; the rest of this lesson is
about the time, and then about what the time costs.
