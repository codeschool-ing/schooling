---
title: Column pruning
version: 1
---

**A query that uses two columns of seven should read two columns of seven**, and with a columnar
format it can. Parquet stores each column of a file separately, so a reader that wants `kind` and
`book_id` can skip the bytes of `ts`, `visitor_id` and the rest. Lesson 10 opens a file to show how.

The planner decides which columns are needed by working back from the result, and writes the answer
into the scan as `ReadSchema`. The three scans of `pruning.py`, as the planner wrote them, from a
program that only explains them, `~/big/scan_plans.py`:

```schooling-example
{
  "language": "python",
  "file": "scan_plans.py",
  "parts": [
    {
      "code": "\"\"\"The scan node of three of pruning.py's queries, as the planner wrote it.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"scan plans\").getOrCreate()\npurchases = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\nis_pi_day = F.udf(lambda d: d.month == 3 and d.day == 14, \"boolean\")\n\n"
    },
    {
      "code": "for label, query in [\n        (\"one column\", purchases.agg(F.countDistinct(\"book_id\"))),\n        (\"one day\", purchases.where(F.col(\"day\") == \"2025-03-14\")\n                             .agg(F.countDistinct(\"book_id\"))),\n        (\"one day, udf\", purchases.where(is_pi_day(\"day\"))\n                                  .agg(F.countDistinct(\"book_id\")))]:\n    print(f\"--- {label}\")\n    query.explain(\"formatted\")\n",
      "note": "The same three queries as `pruning.py`, explained instead of run. Each prints a numbered plan; the lesson reads only the scan's lines."
    }
  ]
}
```

`explain("formatted")` prints a long plan for each; `grep` keeps the scan's lines:

```
ana@lab:~/big$ spark-submit scan_plans.py 2>&1 | grep -E '^(---|PartitionFilters|PushedFilters|ReadSchema)'
--- one column
PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase)]
ReadSchema: struct<kind:string,book_id:int>
--- one day
PartitionFilters: [isnotnull(day#6), (day#6 = 2025-03-14)]
PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase)]
ReadSchema: struct<kind:string,book_id:int>
--- one day, udf
PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase)]
ReadSchema: struct<kind:string,book_id:int>
```

**Two columns, `kind` and `book_id`, in all three.** That is the whole of what the query needs: `kind`
for the filter and `book_id` for the count. The timings of the last section are the effect: reading
every column of every purchase took about twice as long as reading these two.

What the planner cannot prune, it reads. Three common ways to read more than you need:

- **`select("*")` early in a pipeline**, or no `select` at all, followed by a `collect` or a write of
  whole rows: every column is needed, so every column is read.
- **A Python UDF over the whole row**, such as `udf(lambda row: ...)(F.struct("*"))`, which the
  planner has to feed every column because it cannot see which ones the function touches.
- **A row-based format.** A CSV line has to be read whole to find any column in it; the pruning in
  `ReadSchema` saves parsing there and saves no reading.
