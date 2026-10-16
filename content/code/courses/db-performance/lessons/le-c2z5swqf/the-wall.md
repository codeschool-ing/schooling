---
title: The wall, and everything to try before it
version: 1
---

**Sharding** is splitting one table's rows across several database servers, each holding a part
and none holding the whole. It is the last tool in this course, and it comes last on purpose: every
tool before it makes one server do more, and this one gives up having one server. That is a trade
you make once and pay for every day afterwards, so the first thing to know about it is when you are
actually forced into it.

The belief to put down first is that sharding is what a big database needs. It is not. A database
needs sharding when **one machine can no longer do the work**, however well it is used, and that
point is much further away than most people think when they first say the word. Plenty of
companies with billions of rows run on a single primary with a few replicas behind it.

## What "the wall" means

There are three ways one server runs out, and only one of them is a reason to shard:

| what runs out | what it looks like | what usually fixes it |
|---|---|---|
| **reads** | processors busy with `SELECT`s, the cache missing | indexes, a cache, read replicas |
| **storage** | the disk filling, the working set no longer in memory | archiving, partitioning, a bigger disk |
| **writes** | every commit waits on the one disk that holds the WAL; the primary's processors are busy with `INSERT` and `UPDATE` | a bigger machine, then sharding |

The asymmetry in the last column is the whole argument. Reads can be spread over copies: lesson 20
puts a second server beside the first and sends it the `SELECT`s. Writes cannot, because every copy
has to receive every write. When **the writes alone** are more than the biggest machine you can buy
will absorb, splitting the data so that each server receives only some of them is the remaining
move. That is the wall.

## What to exhaust first, in order of cost

Each line here is something earlier lessons taught or later ones do, and each costs less than
sharding, because none of them changes what the application has to know.

- **Fix the queries.** Lesson 2's tally put three statements at 98% of the server's time. A server
  "out of capacity" is very often a server running three bad plans. Lessons 3 to 11 are this step.
- **A bigger machine.** Unglamorous and usually the cheapest line on the list. Doubling the memory
  so the working set fits, or moving to faster disks, costs a migration and an invoice; sharding
  costs a rewrite and an operations team.
- **Pooling.** A server drowning in connections is not out of capacity; lesson 16 is that fix.
- **Partitioning** one table on one server, lessons 17 and 18. It shrinks indexes, makes old data
  cheap to drop and lets a query skip most of a table, all without a second machine.
- **Read replicas**, lesson 20, for a load that is mostly reads, and a **cache**, lesson 21, for
  reads that repeat.
- **Archiving.** Data nobody reads still costs memory in its indexes, time in every vacuum and
  hours in every restore.

That last one deserves a concrete look, because `market` has the usual shape:

```
market=# SELECT extract(year FROM placed_at) AS year, count(*) FROM orders GROUP BY 1 ORDER BY 1;
 year |  count  
------+---------
 2023 |  221610
 2024 |  668658
 2025 | 1109732
(3 rows)

Time: 531.364 ms

market=# SELECT pg_size_pretty(pg_total_relation_size('orders')) AS orders, pg_size_pretty(pg_database_size('market')) AS market;
 orders | market  
--------+---------
 247 MB | 1348 MB
(1 row)

Time: 1.866 ms
```

**221610 orders from 2023, 668658 from 2024 and 1109732 from 2025.** The application's screens
read the last few weeks: a customer's recent orders, a seller's December, the pending count. The
2023 orders are kept for the accountants and read a few times a year. Moving them to a cheaper
store, or to a partition on slower disk that lesson 17 makes easy to detach, makes the hot part of
`orders` a ninth smaller today, and the share grows every year the shop runs. The whole database is
**1348 MB**, and `orders` is **247 MB** of it: on any server sold today it fits in memory several
times over. `market` is nowhere near the wall, and almost no database you meet will be.

## The signs that you have reached it

When the list above is done and the server is still drowning, the signs look like this. The
primary's processors are busy and the busiest statements in `pg_stat_statements` are writes. The
WAL is being written as fast as the disk can take it. The largest machine your provider sells is
the one you already have, or the next one up costs more than the engineers who would shard. And
the growth is not a spike: the writes per second rise every month.

There is a second, less common reason, which is **not about speed at all**: data that must live in
different places. A law that says Brazilian customers' data stays in Brazil and European customers'
data stays in Europe is a shard key chosen by a regulator. The mechanics in this lesson are the
same; the reason to accept the bill is different.

Neither is true of `market`, and you will shard it anyway in section 04, on one machine, because
the only way to understand the bill is to see each item on it arrive. Before that, the decision
that sharding cannot take back: what to split by.
