---
title: Spark SQL
version: 1
---

**Spark speaks SQL, and for most questions about tables SQL is the shortest way to ask.** It is not
a separate engine: a SQL query and the DataFrame code that says the same thing compile to the same
plan, and the next section shows they cost the same.

Spark comes with a SQL shell, `spark-sql`, that runs one query with `-e` and prints the result. A
Parquet directory can be queried directly by naming its format before its path:

```
ana@lab:~/big$ time spark-sql -e 'SELECT b.category, count(*) AS purchases FROM parquet.`data/silver/clicks` c JOIN parquet.`data/silver/books` b ON c.book_id = b.book_id WHERE c.kind = "purchase" GROUP BY b.category ORDER BY purchases DESC LIMIT 3'
WARNING: Using incubator modules: jdk.incubator.vector
22:29:26 WARN ObjectStore: Version information not found in metastore. hive.metastore.schema.verification is not enabled so recording the schema version 2.3.0
22:29:26 WARN ObjectStore: setMetaStoreSchemaVersion called but recording version is disabled: version = 2.3.0, comment = Set by MetaStore ana@127.0.1.1
Spark Web UI available at http://localhost:4040
Spark master: spark://localhost:7077, Application Id: app-20261015222916-0019
22:29:28 WARN ObjectStore: Failed to get database parquet, returning NoSuchObjectException
22:29:28 WARN ObjectStore: Failed to get database parquet, returning NoSuchObjectException
poetry	154689
science	115387
cookery	94744
Time taken: 25.506 seconds, Fetched 3 row(s)

real	0m42.590s
user	0m48.194s
sys	0m2.381s
```

**Purchases per category, joining the clicks to the books**, from files and nothing else: no
database, no table definitions. The SQL is ordinary, and `parquet.` followed by a path in backticks
is Spark's way of naming files where a table name would go. Spark counted 25 seconds for the query and the whole command took
43; the difference is starting an application and, the first time, a small database `spark-sql`
creates in `~/big/metastore_db` to keep table definitions in. The `ObjectStore` warnings at the top
come from that database, which is Hive's metastore, and lesson 12 is about it.

Inside a program, a DataFrame becomes queryable by giving it a name:

```python
clicks.createOrReplaceTempView("clicks")
spark.sql("SELECT device, count(*) FROM clicks GROUP BY device").show()
```

**A temporary view lives as long as the session that made it** and is visible to nobody else. For
names that outlive one program, with their schema and location recorded somewhere every program can
find, Spark needs a *catalog*. That is the Hive metastore of lesson 12, and the table formats of
lesson 11 bring catalogs of their own.
