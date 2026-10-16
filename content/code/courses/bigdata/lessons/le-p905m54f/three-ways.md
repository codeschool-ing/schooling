---
title: The same question, three ways
version: 1
---

**Purchases per device, asked with the RDD API, the DataFrame API and SQL.** Each is run twice, in
turn, so that the first does not pay alone for warming the machine up. Save this as
`~/big/three_ways.py`:

```schooling-example
{
  "language": "python",
  "file": "three_ways.py",
  "parts": [
    {
      "code": "\"\"\"Purchases per device, asked three ways.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"three ways\").getOrCreate()\nSCHEMA = (\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n          \"book_id INT, device STRING\")\nclicks = spark.read.option(\"header\", True).schema(SCHEMA).csv(\"data/raw/clicks\")\n"
    },
    {
      "code": "clicks.createOrReplaceTempView(\"clicks\")\n\n\ndef rdd():\n    return (spark.sparkContext.textFile(\"data/raw/clicks/*/*.csv.gz\")\n            .filter(lambda line: \",purchase,\" in line)\n            .map(lambda line: (line.split(\",\")[5], 1))\n            .reduceByKey(lambda a, b: a + b).collect())\n\n\ndef dataframe():\n    return clicks.where(\"kind = 'purchase'\").groupBy(\"device\").count().collect()\n\n\ndef sql():\n    return spark.sql(\"SELECT device, count(*) FROM clicks \"\n                     \"WHERE kind = 'purchase' GROUP BY device\").collect()\n\n\n",
      "note": "A *temporary view* gives the DataFrame a name that SQL can use, for as long as this program runs."
    },
    {
      "code": "for round_ in (1, 2):\n    for name, ask in [(\"rdd\", rdd), (\"dataframe\", dataframe), (\"sql\", sql)]:\n        t = time.time()\n        answer = sorted(tuple(row) for row in ask())\n        print(round_, f\"{name:9}\", answer, f\"{time.time() - t:.1f} s\")\n",
      "note": "Each one twice, in turn, so that the first to run does not pay alone for warming the machine up."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit three_ways.py
WARNING: Using incubator modules: jdk.incubator.vector
1 rdd       [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 28.6 s
1 dataframe [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 18.9 s
1 sql       [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 13.5 s
2 rdd       [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 22.6 s
2 dataframe [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 12.5 s
2 sql       [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 12.2 s
```

**Three identical answers.** Look at the second round, where nobody is paying for anything else.
The DataFrame took 12.5 seconds and the SQL 12.2, the same within the noise of a shared machine; the
RDD took 22.6, nearly twice as long. The first round shows why one measurement is not enough: the
DataFrame paid 18.9 seconds there for being the first to read the files with a schema.

The DataFrame and the SQL take the same time because they are the same thing: two spellings of one
query, compiled by one planner into one plan. The RDD is slower for the reason the UDF of section 07
was: its `filter` and its `map` are Python functions, so every one of 24 million lines goes from
Java to Python and back, and Spark could not skip reading a single column, because to an RDD a line
is a string and not a row with columns.

**Choosing between them**:

- **SQL** when the question is a query and the people who read it know SQL. Most analytical jobs.
- **The DataFrame API** when the question is built by a program: columns chosen at runtime, a
  pipeline of steps written as functions, tests for each step. Same performance as SQL.
- **The RDD** when the data has no table shape, or for an operation neither of the others can
  express. Rare, and a deliberate choice when it happens.

The next lesson opens the planner and reads the plan these programs became.
