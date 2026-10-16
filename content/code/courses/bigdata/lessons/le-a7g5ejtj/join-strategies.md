---
title: How Spark can join
version: 1
---

**A join needs every row of a key from both sides in the same task.** There are two ways to arrange
that, and lesson 4 named them for MapReduce: move both sides by key so they meet, which is a shuffle,
or copy the small side whole to every task that reads the large one, which is not. Spark has five
physical strategies built on those two ideas, and the plan names the one it chose.

| strategy | what moves | when Spark picks it |
|---|---|---|
| broadcast hash join | the small side, whole, to every executor | an equality join whose smaller side is estimated under `spark.sql.autoBroadcastJoinThreshold`, 10 MB, or is hinted |
| sort-merge join | both sides, shuffled by key, then sorted | an equality join with neither side small enough: the default |
| shuffle hash join | both sides, shuffled by key, no sort | an equality join when asked, by hint or by `spark.sql.join.preferSortMergeJoin=false` |
| broadcast nested loop join | the small side, whole | a join with no equality in its condition, such as a range |
| cartesian product | every pair of partitions | no equality and neither side broadcast: the last resort |

**The two that matter almost every day are the first two.** A broadcast hash join builds a hash table
of the small side and streams the large side through it, partition by partition, with no shuffle on
the large side at all. A sort-merge join shuffles both sides into the same number of partitions by
the join key, sorts each partition, and walks the two sorted streams together. It never needs
either side to fit in memory, because a sort can spill, and that is why it is the default.

A shuffle hash join skips the sort and builds a hash table per partition instead: faster when a
partition's smaller side fits in memory, and a failure when it does not. By default Spark only picks
it when told to.

**Hints override the planner** when the program knows something the estimates do not. In the
DataFrame API, `F.broadcast(df)` or `df.hint("broadcast")`, `df.hint("merge")` and
`df.hint("shuffle_hash")`; in SQL, the same words in a comment after `SELECT`:

```sql
SELECT /*+ BROADCAST(b) */ b.category, count(*)
FROM clicks c JOIN books b ON c.book_id = b.book_id
GROUP BY b.category
```

**A hint is a request, not an order.** If the strategy cannot run the join, as with a broadcast
asked for on the left side of a left outer join, whose every row has to be kept, Spark ignores the
hint and logs a warning.
