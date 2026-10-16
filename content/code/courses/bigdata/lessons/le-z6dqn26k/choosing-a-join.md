---
title: How the planner chose the join
version: 1
---

**The planner picked a broadcast join for purchases per category without being told to**, the
map-side join of lesson 4. It chose from an estimate of each side's size, and the estimate and the
rule are both visible. Save this as `~/big/joins_chosen.py`:

```schooling-example
{
  "language": "python",
  "file": "joins_chosen.py",
  "parts": [
    {
      "code": "\"\"\"How Spark chose to join, and what it estimated to choose it.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"joins chosen\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nbooks = spark.read.parquet(\"data/silver/books\")\n\n\ndef joined():\n    return clicks.join(books, \"book_id\").groupBy(\"category\").agg(F.count(\"*\"))\n\n\n\n"
    },
    {
      "code": "joined().explain(\"cost\")\n",
      "note": "`\"cost\"` prints the optimised logical plan with the size Spark estimated for each step. The books are the step to look at."
    },
    {
      "code": "print(spark.conf.get(\"spark.sql.autoBroadcastJoinThreshold\"))\n\n",
      "note": "**The threshold under which a side is copied to every task instead of shuffled**, 10 MB by default."
    },
    {
      "code": "spark.conf.set(\"spark.sql.autoBroadcastJoinThreshold\", -1)\njoined().explain()\n",
      "note": "**Set to -1, the threshold turns broadcasting off**, and the same query, built again so that it is planned again, is planned the other way."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit joins_chosen.py
WARNING: Using incubator modules: jdk.incubator.vector
== Optimized Logical Plan ==
Aggregate [category#8], [category#8, count(1) AS count(1)#22L], Statistics(sizeInBytes=783.6 GiB)
+- Project [category#8], Statistics(sizeInBytes=609.5 GiB)
   +- Join Inner, (book_id#4 = book_id#7), Statistics(sizeInBytes=783.6 GiB)
      :- Project [book_id#4], Statistics(sizeInBytes=50.7 MiB)
      :  +- Filter isnotnull(book_id#4), Statistics(sizeInBytes=388.8 MiB)
      :     +- Relation [event_id#0L,ts#1,visitor_id#2,kind#3,book_id#4,device#5,day#6] parquet, Statistics(sizeInBytes=388.8 MiB)
      +- Project [book_id#7, category#8], Statistics(sizeInBytes=15.5 KiB)
         +- Filter isnotnull(book_id#7), Statistics(sizeInBytes=17.4 KiB)
            +- Relation [book_id#7,category#8,price_cents#9] parquet, Statistics(sizeInBytes=17.4 KiB)

== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=false
+- HashAggregate(keys=[category#8], functions=[count(1)], output=[category#8, count(1)#22L])
   +- Exchange hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=40]
      +- HashAggregate(keys=[category#8], functions=[partial_count(1)], output=[category#8, count#24L])
         +- Project [category#8]
            +- BroadcastHashJoin [book_id#4], [book_id#7], Inner, BuildRight, false
               :- Project [book_id#4]
               :  +- Filter isnotnull(book_id#4)
               :     +- FileScan parquet [book_id#4,day#6] Batched: true, DataFilters: [isnotnull(book_id#4)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/clicks], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int>
               +- BroadcastExchange HashedRelationBroadcastMode(List(cast(input[0, int, false] as bigint)),false), [plan_id=35]
                  +- Filter isnotnull(book_id#7)
                     +- FileScan parquet [book_id#7,category#8] Batched: true, DataFilters: [isnotnull(book_id#7)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/books], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int,category:string>


10485760b
== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=false
+- HashAggregate(keys=[category#8], functions=[count(1)])
   +- Exchange hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=86]
      +- HashAggregate(keys=[category#8], functions=[partial_count(1)])
         +- Project [category#8]
            +- SortMergeJoin [book_id#4], [book_id#7], Inner
               :- Sort [book_id#4 ASC NULLS FIRST], false, 0
               :  +- Exchange hashpartitioning(book_id#4, 200), ENSURE_REQUIREMENTS, [plan_id=78]
               :     +- Project [book_id#4]
               :        +- Filter isnotnull(book_id#4)
               :           +- FileScan parquet [book_id#4,day#6] Batched: true, DataFilters: [isnotnull(book_id#4)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/clicks], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int>
               +- Sort [book_id#7 ASC NULLS FIRST], false, 0
                  +- Exchange hashpartitioning(book_id#7, 200), ENSURE_REQUIREMENTS, [plan_id=79]
                     +- Filter isnotnull(book_id#7)
                        +- FileScan parquet [book_id#7,category#8] Batched: true, DataFilters: [isnotnull(book_id#7)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/books], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int,category:string>
```

**Read the `Statistics` on each line of the optimised plan.** The books' `Relation` is estimated at
17.4 KiB, which is the size of its Parquet file, and after keeping two columns, 15.5 KiB. The clicks
are 388.8 MiB. The threshold printed after the plan is `10485760b`, 10 MB: a side estimated below
it is broadcast, so the books are, and the plan shows `BroadcastHashJoin`.

The other estimates are worth a look for how wrong they are. The join is estimated at 783.6 GiB,
two thousand times its input, because without knowing anything about the values of `book_id` the
planner assumes the worst. For choosing a broadcast it only needs the small side, and that estimate
is good; a planner that chose join orders from these numbers would choose badly. Spark has a
*cost-based optimiser* for that, which uses column statistics computed by `ANALYZE TABLE` on tables
in a catalog, and it is off by default. Lesson 12 meets the catalog.

**With the threshold set to -1, the same query becomes a `SortMergeJoin`**: both sides are shuffled
by `book_id` into 200 partitions, each partition is sorted, and the two sorted streams are merged.
Two `Exchange` nodes and two `Sort` nodes where the broadcast had none on the clicks' side: 24
million rows moved to meet a table of 3,000. That is the reduce-side join of lesson 4, and lesson 8
times the two against each other.

The threshold is a setting because broadcasting has a limit: the small side is collected by the
driver and held whole in every executor's memory. A side wrongly estimated as small, broadcast at
2 GB, is a common way to run a driver or an executor out of memory, and lesson 8 shows what that
looks like.
