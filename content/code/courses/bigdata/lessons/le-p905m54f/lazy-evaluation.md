---
title: Nothing happens until you ask for an answer
version: 1
---

**Spark's operations come in two kinds, and only one of them does any work.** A *transformation*,
such as `filter`, `map` or `groupBy`, returns a new dataset and computes nothing: it adds a step to
the lineage. An *action*, such as `count`, `collect`, `show` or a `write`, needs a result, so it
turns the lineage into a job and runs it. Save this as `~/big/lazy.py`:

```schooling-example
{
  "language": "python",
  "file": "lazy.py",
  "parts": [
    {
      "code": "\"\"\"Transformations cost nothing until an action asks for a result.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"lazy\").getOrCreate()\nsc = spark.sparkContext\n\n"
    },
    {
      "code": "t = time.time()\nlines = sc.textFile(\"data/raw/clicks/*/*.csv.gz\")\nviews = lines.filter(lambda line: \",view,\" in line)\npairs = views.map(lambda line: (line.split(\",\")[4], 1))\nprint(f\"three transformations: {time.time() - t:.3f} s\")\n\n",
      "note": "Three transformations, timed. They only record what to do."
    },
    {
      "code": "t = time.time()\nprint(\"views:\", views.count(), f\"{time.time() - t:.1f} s\")\n",
      "note": "`count` is an action: it runs a job that reads every file and filters every line."
    },
    {
      "code": "t = time.time()\nprint(\"views again:\", views.count(), f\"{time.time() - t:.1f} s\")\n",
      "note": "**The same action again runs the same job again**, from the files. Nothing was kept from the first time; lesson 9 is about keeping it."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit lazy.py
WARNING: Using incubator modules: jdk.incubator.vector
three transformations: 0.559 s
views: 19199214 26.3 s
views again: 19199214 17.8 s
```

**Three transformations in half a second, and nearly all of that was setting up the reader**; not
one line of a file was read. The first `count` read every file. The second `count` read every file
again, because `views` is a recipe and not a result: two actions, two jobs, the same work twice.
It was faster the second time because the operating system had the files in its cache and the
executors' Python processes were already running, not because Spark kept anything.

**Laziness is what lets Spark plan.** When the action arrives, Spark sees every step at once, from
the files to the result, and can choose how to run them: fuse the `filter` and the `map` into one
pass, as the lineage in the last section showed, or, with a DataFrame, read only the columns the
result needs. A program that ran each line as it was written would have to read everything at the
first line, before knowing what the last would ask for.

The cost is a habit to unlearn. **A line that looks expensive may cost nothing, and a cheap-looking
`count` at the end may run everything above it**, again, each time. Two actions on the same
transformed data are two jobs unless you ask Spark to keep the data between them, and lesson 9 is
about when to do that.
