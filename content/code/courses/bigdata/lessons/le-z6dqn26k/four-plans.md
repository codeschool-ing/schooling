---
title: The four plans of one query
version: 1
---

**Purchases per category is a join, a filter, a grouping and a sort**, and it is enough to see every
step of the planner. Save this as `~/big/plans.py`:

```schooling-example
{
  "language": "python",
  "file": "plans.py",
  "parts": [
    {
      "code": "\"\"\"Purchases per category: the four plans Spark makes of one query.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"plans\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nbooks = spark.read.parquet(\"data/silver/books\")\n\n"
    },
    {
      "code": "per_category = (clicks.join(books, \"book_id\")\n                .where(F.col(\"kind\") == \"purchase\")\n                .groupBy(\"category\")\n                .agg(F.count(\"*\").alias(\"purchases\"))\n                .orderBy(F.desc(\"purchases\")))\n\n",
      "note": "A join, a filter, a grouping and a sort. Nothing runs yet."
    },
    {
      "code": "per_category.explain(True)\n",
      "note": "`explain(True)` prints every plan, from what was written to what will run. It runs no job."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit plans.py
WARNING: Using incubator modules: jdk.incubator.vector
== Parsed Logical Plan ==
'Sort ['purchases DESC NULLS LAST], true
+- Aggregate [category#8], [category#8, count(1) AS purchases#12L]
   +- Filter (kind#3 = purchase)
      +- Project [book_id#4, event_id#0L, ts#1, visitor_id#2, kind#3, device#5, day#6, category#8, price_cents#9]
         +- Join Inner, (book_id#4 = book_id#7)
            :- Relation [event_id#0L,ts#1,visitor_id#2,kind#3,book_id#4,device#5,day#6] parquet
            +- Relation [book_id#7,category#8,price_cents#9] parquet

== Analyzed Logical Plan ==
category: string, purchases: bigint
Sort [purchases#12L DESC NULLS LAST], true
+- Aggregate [category#8], [category#8, count(1) AS purchases#12L]
   +- Filter (kind#3 = purchase)
      +- Project [book_id#4, event_id#0L, ts#1, visitor_id#2, kind#3, device#5, day#6, category#8, price_cents#9]
         +- Join Inner, (book_id#4 = book_id#7)
            :- Relation [event_id#0L,ts#1,visitor_id#2,kind#3,book_id#4,device#5,day#6] parquet
            +- Relation [book_id#7,category#8,price_cents#9] parquet

== Optimized Logical Plan ==
Sort [purchases#12L DESC NULLS LAST], true
+- Aggregate [category#8], [category#8, count(1) AS purchases#12L]
   +- Project [category#8]
      +- Join Inner, (book_id#4 = book_id#7)
         :- Project [book_id#4]
         :  +- Filter ((isnotnull(kind#3) AND (kind#3 = purchase)) AND isnotnull(book_id#4))
         :     +- Relation [event_id#0L,ts#1,visitor_id#2,kind#3,book_id#4,device#5,day#6] parquet
         +- Project [book_id#7, category#8]
            +- Filter isnotnull(book_id#7)
               +- Relation [book_id#7,category#8,price_cents#9] parquet

== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=false
+- Sort [purchases#12L DESC NULLS LAST], true, 0
   +- Exchange rangepartitioning(purchases#12L DESC NULLS LAST, 200), ENSURE_REQUIREMENTS, [plan_id=48]
      +- HashAggregate(keys=[category#8], functions=[count(1)], output=[category#8, purchases#12L])
         +- Exchange hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=45]
            +- HashAggregate(keys=[category#8], functions=[partial_count(1)], output=[category#8, count#24L])
               +- Project [category#8]
                  +- BroadcastHashJoin [book_id#4], [book_id#7], Inner, BuildRight, false
                     :- Project [book_id#4]
                     :  +- Filter ((isnotnull(kind#3) AND (kind#3 = purchase)) AND isnotnull(book_id#4))
                     :     +- FileScan parquet [kind#3,book_id#4,day#6] Batched: true, DataFilters: [isnotnull(kind#3), (kind#3 = purchase), isnotnull(book_id#4)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/clicks], PartitionFilters: [], PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase), IsNotNull(book_id)], ReadSchema: struct<kind:string,book_id:int>
                     +- BroadcastExchange HashedRelationBroadcastMode(List(cast(input[0, int, false] as bigint)),false), [plan_id=40]
                        +- Filter isnotnull(book_id#7)
                           +- FileScan parquet [book_id#7,category#8] Batched: true, DataFilters: [isnotnull(book_id#7)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/books], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int,category:string>
```

Read the four from the top.

**The parsed plan is the program, backwards.** Each line is an operation, indented under the one
whose output it reads, so the data flows from the bottom up: the two `Relation`s, the join, a
`Project` the join made to keep one `book_id` of the two, the filter, the aggregate and the sort.
The number after `#` on every column is how Catalyst tells apart two columns with the same name,
such as the two `book_id`s. One name, `'purchases` in the sort, still carries a `'`: it is not yet
resolved. A DataFrame resolves each name as each method is called, so almost everything is already
known here; the same query in SQL would arrive with every name marked that way.

**The analysed plan adds the result's schema**, `category: string, purchases: bigint`, and resolves
the last name. Otherwise it is the parsed plan: analysis checks, it does not rearrange.

**The optimised plan has moved things.** The filter on `kind` is no longer above the join: it has
been pushed *below* it, onto the clicks, so that the join only ever sees purchases. Each `Relation`
now sits under a `Project` that keeps only the columns the query uses, and `isnotnull` filters have
appeared on the join keys, because an inner join drops nulls anyway and dropping them early is
cheaper. None of these were in the program.

**The physical plan says how.** The join is a `BroadcastHashJoin`: the books are small enough to be
copied whole to every task, the map-side join of lesson 4, chosen without being asked. Two
`Exchange` lines are the two shuffles, one for the grouping and one for the sort. And each
`FileScan` lists what it will read and skip, which sections 05 to 08 take one at a time.
