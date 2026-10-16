---
title: An iterative loop
version: 1
---

**Lesson 4 left a promise: a loop that does the same step over the same data many times, which
MapReduce paid for by writing to HDFS and reading back every time.** This is that loop in Spark.
The algorithm is PageRank, which ranks the pages of a web by how links lead to them; here the pages
are books, and a link from one book to another is a visitor viewing the second right after the
first. A book many readers move to ranks high, and so does a book that well-ranked books send readers
to.

Each iteration spreads every book's rank over its links and adds up what each book receives. The
links are the same in every iteration, and they are the expensive part: every view of every visitor,
sorted by time, paired with the next one and counted. Save this as `~/big/pagerank.py`:

```schooling-example
{
  "language": "python",
  "file": "pagerank.py",
  "parts": [
    {
      "code": "\"\"\"PageRank over the books, where a link is one book viewed right after another.\"\"\"\nimport sys\nimport time\n\nfrom pyspark.sql import SparkSession, Window\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"pagerank\").getOrCreate()\nCACHE = \"cache\" in sys.argv[1:]\n\n"
    },
    {
      "code": "views = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"view\")\nafter = Window.partitionBy(\"visitor_id\").orderBy(\"ts\", \"event_id\")\nlinks = (views.select(F.col(\"book_id\").alias(\"src\"),\n                      F.lead(\"book_id\").over(after).alias(\"dst\"))\n         .where(F.col(\"dst\").isNotNull() & (F.col(\"src\") != F.col(\"dst\")))\n         .groupBy(\"src\", \"dst\").count()\n         .withColumn(\"share\", F.col(\"count\") / F.sum(\"count\").over(Window.partitionBy(\"src\")))\n         .select(\"src\", \"dst\", \"share\"))\n",
      "note": "**The links**: each visitor's views in time order, and each view paired with the next with `lead`. A link from book a to book b gets the share of a's departures that went to b."
    },
    {
      "code": "if CACHE:\n    links.cache()\n\n",
      "note": "**The only difference between the two runs.** With `cache`, the links are kept in the executors' memory the first time an iteration computes them."
    },
    {
      "code": "books = [r.book_id for r in spark.read.parquet(\"data/silver/books\").select(\"book_id\").collect()]\nrank = {b: 1 / len(books) for b in books}\nstart = time.time()\nfor i in range(1, 11):\n    began = time.time()\n    current = spark.createDataFrame(list(rank.items()), \"src int, rank double\")\n    received = (links.join(current, \"src\")\n                .groupBy(\"dst\").agg(F.sum(F.col(\"rank\") * F.col(\"share\")).alias(\"r\"))\n                .collect())\n    got = {row.dst: row.r for row in received}\n    rank = {b: 0.15 / len(books) + 0.85 * got.get(b, 0.0) for b in books}\n    print(f\"iteration {i:2}: {time.time() - began:5.1f} s\")\nprint(f\"ten iterations: {time.time() - start:.1f} s\")\nprint(\"top three:\", [(b, round(r, 5)) for b, r in sorted(rank.items(), key=lambda x: -x[1])[:3]])\n",
      "note": "**The ranks are 3,000 numbers, small enough to live in the driver** as a Python dictionary. Each iteration sends them to the cluster, which spreads every book's rank over its links and adds up what each book receives."
    }
  ]
}
```

Run it twice, without and with the cache:

```
ana@lab:~/big$ spark-submit pagerank.py
WARNING: Using incubator modules: jdk.incubator.vector
iteration  1:  50.4 s
iteration  2:  36.0 s
iteration  3:  34.5 s
iteration  4:  34.8 s
iteration  5:  36.3 s
iteration  6:  37.2 s
iteration  7:  34.3 s
iteration  8:  33.2 s
iteration  9:  36.3 s
iteration 10:  32.9 s
ten iterations: 365.9 s
top three: [(1, 0.05579), (2, 0.01525), (3, 0.01073)]
```

```
ana@lab:~/big$ spark-submit pagerank.py cache
WARNING: Using incubator modules: jdk.incubator.vector
iteration  1:  67.7 s
iteration  2:  10.4 s
iteration  3:  11.2 s
iteration  4:  10.4 s
iteration  5:   9.2 s
iteration  6:   9.1 s
iteration  7:  10.3 s
iteration  8:   9.0 s
iteration  9:   8.3 s
iteration 10:   7.7 s
ten iterations: 153.3 s
top three: [(1, 0.05579), (2, 0.01525), (3, 0.01073)]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l09-iterations\" aria-label=\"Seconds taken by each of ten PageRank iterations, in two runs. Without a cache every iteration takes about 35 seconds, the first 50. With the links cached, the first iteration takes 68 seconds while it fills the copy, and every later one takes 8 to 11.\"><path d=\"M70.0 40.0 L70.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 230.0 L70.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 202.9 L690.0 202.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 202.9 L70.0 202.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"202.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M70.0 175.7 L690.0 175.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 175.7 L70.0 175.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"175.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M70.0 148.6 L690.0 148.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 148.6 L70.0 148.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"148.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M70.0 121.4 L690.0 121.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 121.4 L70.0 121.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"121.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M70.0 94.3 L690.0 94.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 94.3 L70.0 94.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"94.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M70.0 67.1 L690.0 67.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 67.1 L70.0 67.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"67.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M70.0 40.0 L690.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 40.0 L70.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">70</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">seconds</text><path d=\"M70.0 230.0 L690.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M101.0 230.0 L101.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"101.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M163.0 230.0 L163.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"163.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M225.0 230.0 L225.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"225.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M287.0 230.0 L287.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"287.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M349.0 230.0 L349.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"349.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M411.0 230.0 L411.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"411.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M473.0 230.0 L473.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"473.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><path d=\"M535.0 230.0 L535.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"535.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><path d=\"M597.0 230.0 L597.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"597.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><path d=\"M659.0 230.0 L659.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"659.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"380.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">iteration</text><rect x=\"79.0\" y=\"93.2\" width=\"20.0\" height=\"136.8\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"101.0\" y=\"46.2\" width=\"20.0\" height=\"183.8\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"141.0\" y=\"132.3\" width=\"20.0\" height=\"97.7\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"163.0\" y=\"201.8\" width=\"20.0\" height=\"28.2\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"203.0\" y=\"136.4\" width=\"20.0\" height=\"93.6\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"225.0\" y=\"199.6\" width=\"20.0\" height=\"30.4\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"265.0\" y=\"135.5\" width=\"20.0\" height=\"94.5\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"287.0\" y=\"201.8\" width=\"20.0\" height=\"28.2\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"327.0\" y=\"131.5\" width=\"20.0\" height=\"98.5\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"349.0\" y=\"205.0\" width=\"20.0\" height=\"25.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"389.0\" y=\"129.0\" width=\"20.0\" height=\"101.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"411.0\" y=\"205.3\" width=\"20.0\" height=\"24.7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"451.0\" y=\"136.9\" width=\"20.0\" height=\"93.1\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"473.0\" y=\"202.0\" width=\"20.0\" height=\"28.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"513.0\" y=\"139.9\" width=\"20.0\" height=\"90.1\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"535.0\" y=\"205.6\" width=\"20.0\" height=\"24.4\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"575.0\" y=\"131.5\" width=\"20.0\" height=\"98.5\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"597.0\" y=\"207.5\" width=\"20.0\" height=\"22.5\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"637.0\" y=\"140.7\" width=\"20.0\" height=\"89.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"659.0\" y=\"209.1\" width=\"20.0\" height=\"20.9\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"470.0\" y=\"30.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"488.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">without a cache</text><rect x=\"590.0\" y=\"30.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"608.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">links cached</text></svg>", "caption": "The cache costs the first iteration more, and every later one much less."}
```

**Without a cache, every iteration computed the links again from the 19 million views**: about 35
seconds each, and six minutes for the whole run. **With a cache, the first iteration paid more than
a minute to compute the links and fill the copy, and every later one took 8 to 11 seconds**, the
time of the join and the sum alone. The whole run took two and a half minutes.

The ranks themselves never left the driver for long. 3,000 numbers fit in a Python dictionary, and
sending them to the cluster each time is cheap; the links, millions of rows, are what has to stay
on the cluster and be computed once. That division, small state in the driver and large invariant
data cached on the executors, is the shape of most iterative work in Spark. It is also why Spark
exists: the paper that introduced its datasets in 2012 measured loops like this one, PageRank among
them, against Hadoop.

**Book 1 ranks first**, with more than three times the rank of book 2. It is the most viewed book by
construction, lesson 1's cube that makes low ids popular, and PageRank found it from the links
alone.
