---
title: Creating, finding and removing them without an outage
version: 2
---

## `CREATE INDEX` takes a lock

Building an index means reading the whole table, and by default PostgreSQL holds a lock that blocks
**writes** to that table for the whole build. On a large table that is minutes, and lesson 3's queue
forms behind it: the writes wait, and everything arriving afterwards waits behind them.

```sql
CREATE INDEX CONCURRENTLY ON orders (customer_id);
```

`CONCURRENTLY` builds it without blocking writes. The cost is real and worth knowing:

- It makes **two passes** over the table, so it takes roughly twice as long.
- It waits for every transaction that started before it to finish — so one long-running transaction
  from lesson 8 will hold the build open indefinitely.
- If it fails, it leaves an **invalid** index behind: present in the catalogue, maintained on every
  write, used by nothing. You have to drop it and start again.

```sql
SELECT indexrelid::regclass FROM pg_index WHERE NOT indisvalid;
```

Run that after any failed build, and put it in the checklist for any migration that creates one.

**And `CONCURRENTLY` cannot run inside a transaction block.** Most migration tools wrap each
migration in a transaction, so an index build has to be marked as an exception — every tool has a
way to say so, and finding it before the deploy is easier than during it.

`DROP INDEX CONCURRENTLY` exists for the same reason and behaves the same way.

MySQL's equivalent is online DDL: `ALTER TABLE … ADD INDEX` with `ALGORITHM=INPLACE, LOCK=NONE`
permits reads and writes during the build, and the server tells you if the combination you asked
for is not supported for that change.

## Finding the ones nobody uses

```sql
SELECT relname AS table, indexrelname AS index,
       idx_scan AS times_used,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM   pg_stat_user_indexes
ORDER BY idx_scan, pg_relation_size(indexrelid) DESC;
```

A row with `times_used` at zero and a size in gigabytes is a tax being paid for nothing. Three
caveats before you drop it, and each of them has caught somebody:

**The counter starts from the last statistics reset**, which may have been at the last restart. A
zero on a database that came up on Tuesday means nothing.

**A unique index may be doing its other job.** It can enforce a constraint faithfully for years
without a single query ever searching it, and dropping it removes the guarantee. Check whether it
backs a constraint before believing the number.

**Replicas keep their own counters.** An index used only by the reporting queries that run on a
read replica shows zero scans on the primary. If you have replicas, look at all of them, and this
is the mistake that turns a cleanup into an incident.

MySQL offers `sys.schema_unused_indexes`, with the same caveats.

## Finding the duplicates

Two indexes where one is a prefix of the other — `(customer_id)` beside `(customer_id, placed_at)`
— are one index too many, for the leftmost-prefix reason. They accumulate because two tickets asked
for two queries and nobody compared them.

```sql
SELECT indrelid::regclass AS table, array_agg(indexrelid::regclass) AS indexes
FROM   pg_index
GROUP BY indrelid, indkey
HAVING count(*) > 1;
```

That finds exact duplicates; the prefix case needs an eye, and it is worth the five minutes on any
table with more than four indexes.

## Bloat, and rebuilding

Indexes accumulate dead entries for the same reason tables do — lesson 8's row versions — and an
index that has had a lot of updates can end up much larger than the data in it warrants. The
symptom is an index that grows while the row count does not.

```sql
REINDEX INDEX CONCURRENTLY orders_customer_id_idx;      -- PostgreSQL 12 and later
```

Before version 12 a reindex held a lock for the duration, and the usual workaround was to build a
new index concurrently under a different name and drop the old one. It is worth knowing which
version you are on before planning the maintenance window, because on one of them you do not need
a window.

## The workflow

Four steps, and the first one is the one people skip:

1. **Measure.** `EXPLAIN` the slow query and find out what it is doing. This is lesson 10, and it is
   next for a reason.
2. **Add the index**, concurrently, and with the column order the `composite-indexes` section
   argues for.
3. **Verify it is used.** `EXPLAIN` the same query again. An index that the planner declined is a
   cost with no benefit, and the `when-it-is-not-used` list is where you look for why.
4. **Check again later.** Query patterns change, and the index that earned its place last year may
   be on the unused list now.

Which is the rule from earlier in the lesson, with the steps written out:

> **Do not add an index because it seems likely to help. Add it because you looked — and go back
> and look again.**

The looking is the next lesson, and everything here is easier to decide once you can read a plan.
