---
title: The driver program and its session
version: 1
---

**Every Spark program is a driver**, the role lesson 2 named: an ordinary Python process that
describes the work and hands it to the cluster. Its first line of real work is always the same:

```python
spark = SparkSession.builder.appName("explore").getOrCreate()
```

**The `SparkSession` is the program's connection to the cluster.** Creating it starts the driver's
Java half, asks the master named in `spark-defaults.conf` for executors, and opens the page on port
4040 that lessons 2 and 3 read. Everything after it goes through it: `spark.read` to read data,
`spark.sql` to ask a question in SQL, `spark.sparkContext` for the older API of the next section.
One program has one session, and when the program ends, so does the application.

There are two ways to run a driver, and the course uses the first:

- **`spark-submit program.py`**, as every lesson so far has done. The program runs from top to bottom
  and ends. It is how jobs are run in production, by a scheduler like the ones in `pipelines-etl`,
  and it is what every transcript in this course can show completely.
- **`pyspark`**, an interactive Python shell with `spark` already created. Type a line, see a result.
  It is how most people explore data, and everything in this lesson works in it line by line:
  type `pyspark` and paste the body of any program below, after its `getOrCreate()` line.

Notebooks, such as Jupyter, are the same interactive driver in a browser. They hold one session open
for as long as the notebook runs, and with it the executors: a notebook left open overnight keeps
its share of the cluster, which is lesson 2's `WAITING` with a different cause.

**The Python you write runs in two places.** The driver's lines run in the driver. A function you
pass to Spark, such as the `lambda` in a `filter`, is serialised, shipped to the executors and run
there, in a Python process each executor starts beside itself. The next section's code has both
kinds, and lesson 7 says what the second costs.
