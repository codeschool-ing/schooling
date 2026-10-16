---
title: The price of a Python function
version: 1
---

**A built-in function runs inside the executor's Java process. A Python function does not**, and the
difference is the most common avoidable cost in a PySpark job. Spark has hundreds of built-in
functions, in `pyspark.sql.functions`: dates, strings, arithmetic, arrays, JSON. When none fits,
you can write your own in Python, a *user-defined function* or UDF. Save this as `~/big/udf.py`:

```schooling-example
{
  "language": "python",
  "file": "udf.py",
  "parts": [
    {
      "code": "\"\"\"The hour of each event, with a built-in function and with a Python function.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"udf\").getOrCreate()\nSCHEMA = (\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n          \"book_id INT, device STRING\")\nclicks = spark.read.option(\"header\", True).schema(SCHEMA).csv(\"data/raw/clicks\")\n\n\n"
    },
    {
      "code": "@F.udf(\"int\")\ndef hour_of(ts):\n    return ts.hour\n\n\n",
      "note": "**A user-defined function in Python.** `@F.udf(\"int\")` turns an ordinary function into something a DataFrame can call, declaring what it returns. Spark cannot look inside it."
    },
    {
      "code": "for name, column in [(\"built-in\", F.hour(\"ts\")), (\"python udf\", hour_of(\"ts\"))]:\n    t = time.time()\n    rows = clicks.groupBy(column.alias(\"hour\")).count().collect()\n    print(f\"{name}: {len(rows)} hours, {time.time() - t:.1f} s\")\n",
      "note": "The same grouping twice: once with Spark's own `hour`, once with the Python function."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit udf.py
WARNING: Using incubator modules: jdk.incubator.vector
built-in: 24 hours, 22.9 s
python udf: 24 hours, 56.5 s
```

**Same 24 hours, same counts, and the Python function took two and a half times as long: 56.5 seconds against
22.9.** What the UDF adds is a journey for every row: the
executor's Java process serialises the timestamp, sends it to a Python process beside it, Python
deserialises it, calls `hour_of`, serialises the answer and sends it back. Twenty-four million times.
The built-in `hour` does the arithmetic where the data already is.

And there is a cost the clock does not show: **the planner cannot see inside a UDF.** It does not
know that `hour_of` only reads `ts`, or that it never returns a value outside 0 to 23, so it cannot
use any of that to plan. Lesson 6 shows a filter written as a UDF defeating an optimisation that the
same filter written as a column expression gets for free.

The rule, in order:

1. **Look for a built-in function first.** `pyspark.sql.functions` has most of what a UDF is written
   for, and a combination of two or three built-ins beats one UDF.
2. **If it must be Python, make it a vectorised UDF**, `@F.pandas_udf`, which hands Python a whole
   batch of rows as a column at a time instead of one row at a time. It needs `pandas` and `pyarrow`
   installed beside Spark on every machine, which this lab does not have, so it was not measured
   here.
3. **A plain UDF last**, and only when the data is small or the logic truly has no other form.
