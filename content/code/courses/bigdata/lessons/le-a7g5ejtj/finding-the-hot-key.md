---
title: Finding the hot key
version: 1
---

**A slow task tells you that a partition is large; it does not tell you which key made it so.** The
key is found by counting rows per key and sorting, which is cheap next to the job that suffers from
it. With the visitors table of the last section, the count is already done. Save this as
`~/big/hot_key.py`:

```schooling-example
{
  "language": "python",
  "file": "hot_key.py",
  "parts": [
    {
      "code": "\"\"\"The visitors with the most events.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"hot key\").getOrCreate()\n"
    },
    {
      "code": "visitors = spark.read.parquet(\"data/silver/visitors\")\nvisitors.orderBy(F.desc(\"events\")).show(5)\n",
      "note": "**Finding a hot key is a grouping and a sort**: count per key, largest first. With the visitors table already counted, it is a sort."
    },
    {
      "code": "print(\"median events per visitor:\", visitors.approxQuantile(\"events\", [0.5], 0.01)[0])\n",
      "note": "The median visitor, for comparison: the approximate median of `events`, computed on the cluster."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit hot_key.py
WARNING: Using incubator modules: jdk.incubator.vector
+----------+----------+------+
|visitor_id| first_day|events|
+----------+----------+------+
|  v0000000|2025-01-01|960905|
|  v1885325|2025-02-06|    69|
|  v1639364|2025-01-06|    66|
|  v1057185|2025-01-09|    64|
|  v1586330|2025-01-25|    64|
+----------+----------+------+
only showing top 5 rows
median events per visitor: 12.0
```

**`v0000000` has 960,905 events; the next visitor has 69, and the median visitor 12.** The second
column of the table is the useful one: skew is rarely a gentle slope. It is usually one value, or a
handful, far above everything else, and the rest of the distribution is ordinary.

The usual suspects are the same in every company's data:

- **A placeholder.** A `NULL`, an empty string, `0`, `unknown` or `-1` used where a real value was
  missing. Every row with nothing to say lands on one key.
- **A machine.** A crawler, a monitoring check, a load test, an integration that calls the same
  endpoint every second. It is ours: `v0000000` is a crawler that never identifies itself.
- **A giant customer.** One shop in a marketplace, one city in a country, one product on the day it
  launched. The data is right and the distribution is the business.

The first two are often best handled by asking whether the rows belong in the job at all. Joining
the crawler's events to visitor attributes answers no question anybody asked; a filter before the
join makes the skew disappear along with the rows. The third cannot be filtered away, and the rest
of this lesson is about it.

**`approxQuantile` is approximate on purpose.** An exact median needs every value sorted in one
place. With a relative error of 0.01, Spark computes a summary per partition and merges them, and
the answer is within one percent of the true rank: good enough for "what is a normal visitor", and
it never brings the data to the driver.
