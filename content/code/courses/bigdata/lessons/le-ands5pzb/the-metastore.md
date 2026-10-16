---
title: Hive and its metastore
version: 1
---

**Hive was Facebook's answer to "we have analysts who know SQL and a cluster that only runs Java"**:
it turned a SQL query into a chain of MapReduce jobs, lesson 4's limitation turned into a product.
The engine has since been replaced, first by Tez and LLAP inside Hive, then for most users by Spark,
Trino and the cloud warehouses. **What every one of them kept is Hive's metastore**: a database of
table names, each with its location, format, schema, partitions and statistics. Lesson 5 promised
it, and lesson 6 said the planner's best estimates need it.

Spark carries the Hive metastore inside it. With no metastore service configured, a session with Hive
support starts one in the driver, on an embedded Derby database in the working directory. Save this
as `~/big/metastore.py`:

```schooling-example
{
  "language": "python",
  "file": "metastore.py",
  "parts": [
    {
      "code": "\"\"\"Tables in Hive's metastore: the silver clicks and books, registered once and found by name.\"\"\"\nimport os\n\nfrom pyspark.sql import SparkSession\n\n"
    },
    {
      "code": "spark = SparkSession.builder.appName(\"metastore\").enableHiveSupport().getOrCreate()\n\n",
      "note": "**`enableHiveSupport()` gives the session a metastore.** With no metastore service configured, Spark starts one inside the driver, on an embedded Derby database in the directory `metastore_db`, and keeps managed tables under `spark-warehouse`."
    },
    {
      "code": "spark.sql(\"CREATE DATABASE IF NOT EXISTS shop\")\nfor name in (\"clicks\", \"books\"):\n    spark.sql(f\"\"\"CREATE TABLE IF NOT EXISTS shop.{name} USING parquet\n                  LOCATION '{os.path.abspath('data/silver/' + name)}'\"\"\")\n",
      "note": "**External tables over the files that already exist.** Nothing is copied: the metastore records the location, the format and the schema it infers, including the `day` partition column found in the directory names."
    },
    {
      "code": "spark.sql(\"MSCK REPAIR TABLE shop.clicks\")\nprint(spark.sql(\"SHOW PARTITIONS shop.clicks\").count(), \"partitions of shop.clicks\")\n\n",
      "note": "**The partitions are not registered by the `CREATE`**: `MSCK REPAIR TABLE` walks the directory and adds one per `day=` directory it finds."
    },
    {
      "code": "spark.sql(\"ANALYZE TABLE shop.books COMPUTE STATISTICS FOR ALL COLUMNS\")\ntable = spark.sql(\"DESCRIBE TABLE EXTENDED shop.books\").where(\"col_name = 'Statistics'\")\nprint(\"shop.books:\", table.first().data_type)\nspark.sql(\"DESCRIBE TABLE EXTENDED shop.books book_id\").show()\n",
      "note": "**Statistics, kept in the metastore**: row counts, and for every column of the books its distinct values, nulls and range. The planner reads them instead of guessing from file sizes."
    }
  ]
}
```

Run it after starting the standalone cluster again; its warnings about the metastore's schema
version are the metastore creating itself, and are sent away here:

```
ana@lab:~/big$ spark-submit metastore.py 2>/dev/null
365 partitions of shop.clicks
shop.books: 17800 bytes, 3000 rows
+--------------+----------+
|     info_name|info_value|
+--------------+----------+
|      col_name|   book_id|
|     data_type|       int|
|       comment|      NULL|
|           min|         1|
|           max|      3000|
|     num_nulls|         0|
|distinct_count|      2963|
|   avg_col_len|         4|
|   max_col_len|         4|
|     histogram|      NULL|
+--------------+----------+
```

**Two names now stand for two directories**, with 365 partitions registered for the clicks, one per
`day=` directory, the meaning lesson 3 said Hive gave the word. The books' statistics are the
planner's: 3,000 rows in 17,800 bytes, and for `book_id` a range from 1 to 3000 with no nulls.
**`distinct_count` says 2,963, not 3,000**: Spark counts distinct values with HyperLogLog, a sketch
that is a few percent off by design and needs a fraction of the memory of an exact count. A
cost-based optimiser, switched on with `spark.sql.cbo.enabled`, uses these numbers to order joins
and size their outputs instead of lesson 6's guesses.

Then a second application, which knows the tables only by their names. Save it as
`~/big/by_name.py`:

```schooling-example
{
  "language": "python",
  "file": "by_name.py",
  "parts": [
    {
      "code": "\"\"\"Another application, which knows the tables only by their names.\"\"\"\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"by name\").enableHiveSupport().getOrCreate()\n"
    },
    {
      "code": "spark.sql(\"\"\"SELECT b.category, count(*) AS purchases\n             FROM shop.clicks c JOIN shop.books b ON c.book_id = b.book_id\n             WHERE c.kind = 'purchase' AND c.day = '2025-03-14'\n             GROUP BY b.category ORDER BY purchases DESC LIMIT 3\"\"\").show()\n",
      "note": "**No path and no schema in this program**: the metastore supplies both, and the filter on `day` is pruned to one partition as in lesson 6."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit by_name.py 2>/dev/null
+--------+---------+
|category|purchases|
+--------+---------+
|  poetry|      420|
| science|      314|
| cookery|      258|
+--------+---------+
```

**No path, no format, no schema in the program**, and the answer came from the files of one day. That
is what a catalog is for: the people who write queries stop needing to know where the data is, and
the people who move the data can do so by changing one row in the metastore.

**The embedded Derby database admits one process at a time**, which is why a real metastore runs as
a service of its own, the *Hive metastore server*, on a PostgreSQL or MySQL database, with every
Spark, Trino and Hive client pointed at it by `hive.metastore.uris`. Lesson 11's Iceberg catalogs
and AWS Glue speak the same protocol for the same reason.
