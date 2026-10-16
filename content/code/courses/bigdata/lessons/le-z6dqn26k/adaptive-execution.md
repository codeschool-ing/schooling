---
title: Replanning while the job runs
version: 1
---

**The planner decides before the job starts, from estimates. Adaptive query execution decides again
while it runs, from facts.** Every `Exchange` is a point where one stage has finished and the next
has not started, and at that point Spark knows exactly how much data each partition of the shuffle
holds. With AQE on, which it is by default since Spark 3.2, Spark uses that moment to replan what
comes after.

That is what `AdaptiveSparkPlan isFinalPlan=false` at the top of every physical plan in this lesson
meant: the plan printed is the starting point. `formatted.py` ran its query with `collect` and then
explained it again; the end of what it printed:

```
[Row(category='poetry', purchases=154689), Row(category='science', purchases=115387), Row(category='cookery', purchases=94744)]
== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=true
+- == Final Plan ==
   ResultQueryStage 3
   +- *(4) Sort [purchases#12L DESC NULLS LAST], true, 0
      +- AQEShuffleRead coalesced
         +- ShuffleQueryStage 2
            +- Exchange rangepartitioning(purchases#12L DESC NULLS LAST, 200), ENSURE_REQUIREMENTS, [plan_id=183]
               +- *(3) HashAggregate(keys=[category#8], functions=[count(1)])
                  +- AQEShuffleRead coalesced
                     +- ShuffleQueryStage 1
                        +- Exchange hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=146]
                           +- *(2) HashAggregate(keys=[category#8], functions=[partial_count(1)])
                              +- *(2) Project [category#8]
                                 +- *(2) BroadcastHashJoin [book_id#4], [book_id#7], Inner, BuildRight, false
                                    :- *(2) Project [book_id#4]
                                    :  +- *(2) Filter ((isnotnull(kind#3) AND (kind#3 = purchase)) AND isnotnull(book_id#4))
                                    :     +- *(2) ColumnarToRow
                                    :        +- FileScan parquet [kind#3,book_id#4,day#6] Batched: true, DataFilters: [isnotnull(kind#3), (kind#3 = purchase), isnotnull(book_id#4)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/clicks], PartitionFilters: [], PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase), IsNotNull(book_id)], ReadSchema: struct<kind:string,book_id:int>
                                    +- BroadcastQueryStage 0
                                       +- BroadcastExchange HashedRelationBroadcastMode(List(cast(input[0, int, false] as bigint)),false), [plan_id=78]
                                          +- *(1) Filter isnotnull(book_id#7)
                                             +- *(1) ColumnarToRow
                                                +- FileScan parquet [book_id#7,category#8] Batched: true, DataFilters: [isnotnull(book_id#7)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/books], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int,category:string>
+- == Initial Plan ==
   Sort [purchases#12L DESC NULLS LAST], true, 0
   +- Exchange rangepartitioning(purchases#12L DESC NULLS LAST, 200), ENSURE_REQUIREMENTS, [plan_id=48]
      +- HashAggregate(keys=[category#8], functions=[count(1)])
         +- Exchange hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=45]
            +- HashAggregate(keys=[category#8], functions=[partial_count(1)])
               +- Project [category#8]
                  +- BroadcastHashJoin [book_id#4], [book_id#7], Inner, BuildRight, false
                     :- Project [book_id#4]
                     :  +- Filter ((isnotnull(kind#3) AND (kind#3 = purchase)) AND isnotnull(book_id#4))
                     :     +- FileScan parquet [kind#3,book_id#4,day#6] Batched: true, DataFilters: [isnotnull(kind#3), (kind#3 = purchase), isnotnull(book_id#4)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/clicks], PartitionFilters: [], PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase), IsNotNull(book_id)], ReadSchema: struct<kind:string,book_id:int>
                     +- BroadcastExchange HashedRelationBroadcastMode(List(cast(input[0, int, false] as bigint)),false), [plan_id=40]
                        +- Filter isnotnull(book_id#7)
                           +- FileScan parquet [book_id#7,category#8] Batched: true, DataFilters: [isnotnull(book_id#7)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/books], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int,category:string>
```

**`isFinalPlan=true`, and two plans: the one that ran, and the *Initial Plan* below it.** The plan
that ran is cut into *query stages*, `BroadcastQueryStage 0` for the books and `ShuffleQueryStage 1`
and `2` for the two shuffles, each run and measured before the next was planned. And above each
shuffle stage sits a node the initial plan did not have: **`AQEShuffleRead coalesced`.**

Section 04 noticed the `200` in `hashpartitioning(category#8, 200)`: the grouping produced ten
categories, so 190 of the 200 shuffle partitions were empty and the other ten tiny. Run as planned,
that is 200 tasks, most of them reading nothing, each paying lesson 2's fixed cost. AQE saw the
real sizes after stage 1 and **coalesced** the 200 into a handful of partitions of a sensible size,
so the next stage ran a handful of tasks. Lesson 7 counts them.

AQE does three things, and the other two belong to later lessons:

- **Coalescing shuffle partitions**, as here: too many small partitions become a few.
- **Switching a join strategy**: a join planned as a shuffle join, whose side turns out small after a
  filter, becomes a broadcast join at run time. Next section.
- **Splitting skewed partitions**: one partition far larger than the rest is cut into pieces.
  Lesson 8 is built around it.

**What AQE cannot fix** is anything decided before the first shuffle: which files are read, which
columns, which partitions. Those are the static planner's, and the earlier sections of this lesson.
