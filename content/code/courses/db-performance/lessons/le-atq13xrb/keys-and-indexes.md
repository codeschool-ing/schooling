---
title: Keys and indexes on a partitioned table
version: 1
---

A partitioned table looks like one table to a query and is several tables to everything that
enforces a rule. Indexes and unique constraints are where the difference shows, and both follow
from one fact: **an index on a partitioned table is one index per partition**, each knowing only
its own rows.

## The primary key has to include the partition key

`events_by_month` has `PRIMARY KEY (id, at)`, although `id` alone is what identifies an event. Try
the obvious version:

```
market=# CREATE TABLE events_wrong (id bigint PRIMARY KEY, at timestamptz NOT NULL) PARTITION BY RANGE (at);
ERROR:  unique constraint on partitioned table must include all partitioning columns
DETAIL:  PRIMARY KEY constraint on table "events_wrong" lacks column "at" which is part of the partition key.
Time: 3.570 ms
```

The server refuses, and the message names the reason. A unique index on `id` would be four separate
indexes, one per month, and each could only check that no other row **in its month** had the same
`id`. Two rows with the same `id` in October and November would both pass. The server only accepts a
uniqueness it can actually guarantee, and it can guarantee it when the partition key is part of the
unique columns: rows with different months can never collide, because a row's month decides which
index it is checked in.

**What you give up is real.** `(id, at)` promises that no two events share **both** an id and an
instant, which is weaker than "no two events share an id". On `events` the identity column makes
duplicates impossible anyway, so nothing is lost; on a table whose ids come from outside, a
duplicate `id` arriving with a different `at` is now accepted. If the application needs `id` unique
on its own, it needs either a key that includes the time, or the uniqueness checked somewhere else.

A **foreign key pointing at** a partitioned table has to reference that full key too, which is why
partitioning a table that many others refer to is the hardest case: every referring table has to
carry the partition key as well. Partitioning a table at the end of the references — events, logs,
readings — avoids it, and it is another reason those are the tables usually partitioned.

## An index declared once, built many times

`events_by_month` declared one index, on `customer_id`, on the parent. The server built one on each
partition, and named them after the partition:

```
market=# \di events_2025_1*
                            List of relations
 Schema |              Name              | Type  | Owner |     Table      
--------+--------------------------------+-------+-------+----------------
 public | events_2025_11_customer_id_idx | index | ana   | events_2025_11
 public | events_2025_11_pkey            | index | ana   | events_2025_11
 public | events_2025_12_customer_id_idx | index | ana   | events_2025_12
 public | events_2025_12_pkey            | index | ana   | events_2025_12
(4 rows)
```

`events_2025_11_customer_id_idx` and `events_2025_11_pkey`, the same pair for December, and the same
for every partition attached later: `ATTACH` checks that the table has a matching index, uses it if
it has one, and builds it if it does not. That last step can be slow on a big table, which is one
more reason to prepare a partition in advance, index included, before attaching it.

**Being separate is also the useful part.** Each index covers one month, so rebuilding one
with `REINDEX` touches one month and not the whole history, and dropping a month drops its indexes
with it at no cost.

## The one thing you cannot do on the parent

On an ordinary table, an index on a busy table is built with `CREATE INDEX CONCURRENTLY`, which does
not block writes while it runs. On the parent of a partitioned table:

```
market=# CREATE INDEX CONCURRENTLY ON events_by_month (kind);
ERROR:  cannot create index on partitioned table "events_by_month" concurrently
Time: 0.778 ms
```

The way round it is longer and worth knowing exists: create the index on the parent alone with
`CREATE INDEX … ON ONLY events_by_month`, which builds nothing and is marked invalid; build each
partition's index with `CONCURRENTLY`; and attach each one to the parent's with `ALTER INDEX …
ATTACH PARTITION`. When the last partition's index is attached, the parent's becomes valid. Several
statements per partition, and the reason tools that manage partitions exist.

## Leaving `market` as lesson 18 expects

Lesson 18 starts from `market` as lesson 3 does, plus `events_by_month` exactly as the file in
section 03 builds it. This lesson ended with October dropped and a default partition holding a test
row, so put the database back and build the table once more:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 15.413 ms
CREATE INDEX
Time: 1458.838 ms (00:01.459)
ana@vm:~$ psql -q market -v ON_ERROR_STOP=1 -f events_by_month.sql
psql:events_by_month.sql:4: NOTICE:  table "events_by_month" does not exist, skipping
DROP TABLE
Time: 0.669 ms
CREATE TABLE
Time: 4.226 ms
CREATE TABLE
Time: 5.253 ms
CREATE TABLE
Time: 4.003 ms
CREATE TABLE
Time: 3.899 ms
CREATE TABLE
Time: 3.827 ms
INSERT 0 5000000
Time: 15204.206 ms (00:15.204)
CREATE INDEX
Time: 3045.838 ms (00:03.046)
VACUUM
Time: 2002.887 ms (00:02.003)
```

If you ever run `~/reset-market.sh` between this lesson and the next, run `psql market -f
events_by_month.sql` after it: the reset makes `market` from the copy, which has never had this
table.
