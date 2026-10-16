---
title: Reading a physical plan
version: 1
---

**The physical plan is a tree, and `explain("formatted")` prints it numbered**, with each node's
details below under its number, which is much easier to read than the indented form. Save this as
`~/big/formatted.py`:

```schooling-example
{
  "language": "python",
  "file": "formatted.py",
  "parts": [
    {
      "code": "\"\"\"The physical plan of the same query, numbered, and then run.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"formatted\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nbooks = spark.read.parquet(\"data/silver/books\")\nper_category = (clicks.join(books, \"book_id\")\n                .where(F.col(\"kind\") == \"purchase\")\n                .groupBy(\"category\")\n                .agg(F.count(\"*\").alias(\"purchases\"))\n                .orderBy(F.desc(\"purchases\")))\n\n"
    },
    {
      "code": "per_category.explain(\"formatted\")\n",
      "note": "`\"formatted\"` prints the physical plan as a numbered tree, then each node's details under its number."
    },
    {
      "code": "print(per_category.collect()[:3])\nper_category.explain()\n",
      "note": "`collect` runs this exact query. After it, `explain()` shows the plan Spark ended up using, which may differ from the one above: section 10."
    }
  ]
}
```

The first part of what it prints:

```
ana@lab:~/big$ spark-submit formatted.py
WARNING: Using incubator modules: jdk.incubator.vector
== Physical Plan ==
AdaptiveSparkPlan (14)
+- Sort (13)
   +- Exchange (12)
      +- HashAggregate (11)
         +- Exchange (10)
            +- HashAggregate (9)
               +- Project (8)
                  +- BroadcastHashJoin Inner BuildRight (7)
                     :- Project (3)
                     :  +- Filter (2)
                     :     +- Scan parquet  (1)
                     +- BroadcastExchange (6)
                        +- Filter (5)
                           +- Scan parquet  (4)


(1) Scan parquet 
Output [3]: [kind#3, book_id#4, day#6]
Batched: true
Location: InMemoryFileIndex [file:/home/ana/big/data/silver/clicks]
PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase), IsNotNull(book_id)]
ReadSchema: struct<kind:string,book_id:int>

(2) Filter
Input [3]: [kind#3, book_id#4, day#6]
Condition : ((isnotnull(kind#3) AND (kind#3 = purchase)) AND isnotnull(book_id#4))

(3) Project
Output [1]: [book_id#4]
Input [3]: [kind#3, book_id#4, day#6]

(4) Scan parquet 
Output [2]: [book_id#7, category#8]
Batched: true
Location: InMemoryFileIndex [file:/home/ana/big/data/silver/books]
PushedFilters: [IsNotNull(book_id)]
ReadSchema: struct<book_id:int,category:string>

(5) Filter
Input [2]: [book_id#7, category#8]
Condition : isnotnull(book_id#7)

(6) BroadcastExchange
Input [2]: [book_id#7, category#8]
Arguments: HashedRelationBroadcastMode(List(cast(input[0, int, false] as bigint)),false), [plan_id=40]

(7) BroadcastHashJoin
Left keys [1]: [book_id#4]
Right keys [1]: [book_id#7]
Join type: Inner
Join condition: None

(8) Project
Output [1]: [category#8]
Input [3]: [book_id#4, book_id#7, category#8]

(9) HashAggregate
Input [1]: [category#8]
Keys [1]: [category#8]
Functions [1]: [partial_count(1)]
Aggregate Attributes [1]: [count#23L]
Results [2]: [category#8, count#24L]

(10) Exchange
Input [2]: [category#8, count#24L]
Arguments: hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=45]

(11) HashAggregate
Input [2]: [category#8, count#24L]
Keys [1]: [category#8]
Functions [1]: [count(1)]
Aggregate Attributes [1]: [count(1)#22L]
Results [2]: [category#8, count(1)#22L AS purchases#12L]

(12) Exchange
Input [2]: [category#8, purchases#12L]
Arguments: rangepartitioning(purchases#12L DESC NULLS LAST, 200), ENSURE_REQUIREMENTS, [plan_id=48]

(13) Sort
Input [2]: [category#8, purchases#12L]
Arguments: [purchases#12L DESC NULLS LAST], true, 0

(14) AdaptiveSparkPlan
Output [2]: [category#8, purchases#12L]
Arguments: isFinalPlan=false
```

Read the tree from the leaves up, which is the order the data moves in:

- **(1) to (3), the clicks.** A scan that reads two columns, `kind` and `book_id`, a filter that keeps
  purchases, and a projection that keeps only `book_id`.
- **(4) to (6), the books**, scanned, filtered and handed to a `BroadcastExchange`: collected by the
  driver and sent whole to every executor.
- **(7) the join**, done inside each task that reads clicks, against its own copy of the books.
  `BuildRight` means the right-hand side, the books, is the one held in memory.
- **(9) to (11), the aggregation in two halves**, the combiner of lesson 4 under another name.
  `partial_count` counts within each task before the shuffle; the `Exchange` at (10) sends each
  category to one place, `hashpartitioning(category#8, 200)`, into 200 partitions; and the second
  `HashAggregate` adds the partial counts.
- **(12) and (13), the sort.** Another `Exchange`, this time `rangepartitioning`: to sort globally,
  Spark samples the values, splits them into ranges, and sends each range to one task, so that the
  outputs read in order. This is the range partitioner lesson 4 said a sorted output needs.

**Every `Exchange` is a shuffle, and every shuffle is the boundary of a stage.** Counting the
exchanges is the quickest estimate of what a query will cost: this one has two, both on small
data, after the join and the partial count have shrunk 24 million rows to ten categories per task.
Lesson 7 counts the stages these become.

`200` appears twice, and nothing in the query asked for it. It is the default number of shuffle
partitions, and with ten categories it means 190 empty ones. Section 10 shows Spark noticing.
