---
title: Postgres does that too
version: 1
---

The shop in `sql-databases` ran on PostgreSQL, and the reasons given for leaving a relational
database are mostly about features it is supposed to lack: documents with a flexible shape, fast
key-value access, a cache, a queue. **Postgres has had each of those for years**, inside the same
database that already holds the orders, with the same transactions and the same backup. This
section runs four of them, then says plainly what Postgres does not do as well.

## Postgres beside the other three

`postgres:16` is the official image, on the course's `nosql` network like the others. The password
is required by the image and only ever used inside the container:

```sh
docker run -d --name postgres --network nosql -e POSTGRES_PASSWORD=lab postgres:16
```

```
ana@vm:~$ docker run -d --name postgres --network nosql -e POSTGRES_PASSWORD=lab postgres:16
15baf0d53a82d3d06169fb4ee7dc8cd805958e71e35cdfa2f9b3983e0c685d5b
ana@vm:~$ docker exec postgres psql -U postgres -c "SELECT version()"
                                                       version                                                        
----------------------------------------------------------------------------------------------------------------------
 PostgreSQL 16.15 (Debian 16.15-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
(1 row)

```

Each of the three files below is saved in the VM and fed to `psql` on its input; `-a` echoes every
line of the file before its answer, so the transcript reads as a session.

## Documents: `jsonb` and a GIN index

The orders of lesson 6, as documents in one `jsonb` column. One order in fifty carries a `gift`
object the others do not have, which is the varying shape that is supposed to need a document
database:

```sql
-- documents.sql: the shop's orders as JSON documents, in one column
CREATE TABLE orders (id bigint PRIMARY KEY, doc jsonb NOT NULL);
INSERT INTO orders
SELECT n, jsonb_build_object(
         'customer', (ARRAY['ana', 'bruno', 'carla', 'diego', 'elisa'])[n % 5 + 1] || '@example.com',
         'items', jsonb_build_array(jsonb_build_object(
                    'sku', (ARRAY['KB-101', 'MS-204', 'MN-330', 'CB-012'])[n % 4 + 1],
                    'qty', 1 + n % 3)))
       || CASE WHEN n % 50 = 0 THEN '{"gift": {"wrap": true, "note": "Happy birthday"}}'::jsonb
               ELSE '{}'::jsonb END
FROM generate_series(1, 100000) AS n;
CREATE INDEX orders_doc ON orders USING gin (doc jsonb_path_ops);
ANALYZE orders;
SELECT doc FROM orders WHERE id = 50;
EXPLAIN (COSTS OFF) SELECT count(*) FROM orders WHERE doc @> '{"gift": {"wrap": true}}';
SELECT count(*) FROM orders WHERE doc @> '{"gift": {"wrap": true}}';
```

```
ana@vm:~$ docker exec -i postgres psql -U postgres -a < documents.sql
-- documents.sql: the shop's orders as JSON documents, in one column
CREATE TABLE orders (id bigint PRIMARY KEY, doc jsonb NOT NULL);
CREATE TABLE
INSERT INTO orders
SELECT n, jsonb_build_object(
         'customer', (ARRAY['ana', 'bruno', 'carla', 'diego', 'elisa'])[n % 5 + 1] || '@example.com',
         'items', jsonb_build_array(jsonb_build_object(
                    'sku', (ARRAY['KB-101', 'MS-204', 'MN-330', 'CB-012'])[n % 4 + 1],
                    'qty', 1 + n % 3)))
       || CASE WHEN n % 50 = 0 THEN '{"gift": {"wrap": true, "note": "Happy birthday"}}'::jsonb
               ELSE '{}'::jsonb END
FROM generate_series(1, 100000) AS n;
INSERT 0 100000
CREATE INDEX orders_doc ON orders USING gin (doc jsonb_path_ops);
CREATE INDEX
ANALYZE orders;
ANALYZE
SELECT doc FROM orders WHERE id = 50;
                                                            doc                                                            
---------------------------------------------------------------------------------------------------------------------------
 {"gift": {"note": "Happy birthday", "wrap": true}, "items": [{"qty": 3, "sku": "MN-330"}], "customer": "ana@example.com"}
(1 row)

EXPLAIN (COSTS OFF) SELECT count(*) FROM orders WHERE doc @> '{"gift": {"wrap": true}}';
                              QUERY PLAN                              
----------------------------------------------------------------------
 Aggregate
   ->  Bitmap Heap Scan on orders
         Recheck Cond: (doc @> '{"gift": {"wrap": true}}'::jsonb)
         ->  Bitmap Index Scan on orders_doc
               Index Cond: (doc @> '{"gift": {"wrap": true}}'::jsonb)
(5 rows)

SELECT count(*) FROM orders WHERE doc @> '{"gift": {"wrap": true}}';
 count 
-------
  2000
(1 row)

```

`@>` is **containment**: does the document contain this smaller document? It is the question
MongoDB's `find({ "gift.wrap": true })` asks, and the plan answers it with a **`Bitmap Index Scan
on orders_doc`**, the GIN index, rather than reading all 100,000 rows. The 2,000 gift orders are one
in fifty, as generated. `jsonb_path_ops` is the GIN flavour built for exactly this operator: smaller
and faster for `@>`, and useless for asking which keys exist, which the default flavour can.

What the document gets **in addition** is everything relational: a primary key, a `CHECK` on any
field, a foreign key from `doc->>'customer'` if you extract it into a column, and a join to any
other table, in the same transaction as the rest of the shop.

## Key-value: an upsert, a counter and a cache

```sql
-- keyvalue.sql: a counter, and a cache that does not need to survive a crash
CREATE TABLE page_views (page text PRIMARY KEY, n bigint NOT NULL);
CREATE UNLOGGED TABLE cache (key text PRIMARY KEY, value jsonb NOT NULL, expires_at timestamptz NOT NULL);
INSERT INTO page_views VALUES ('/product/MN-330', 1)
  ON CONFLICT (page) DO UPDATE SET n = page_views.n + 1 RETURNING n;
INSERT INTO page_views VALUES ('/product/MN-330', 1)
  ON CONFLICT (page) DO UPDATE SET n = page_views.n + 1 RETURNING n;
INSERT INTO cache VALUES ('product:MN-330', '{"name": "27-inch monitor", "price": "1499.00"}', now() + interval '5 minutes')
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, expires_at = EXCLUDED.expires_at;
SELECT value FROM cache WHERE key = 'product:MN-330' AND expires_at > now();
SELECT relname, relpersistence FROM pg_class WHERE relname IN ('page_views', 'cache');
```

```
ana@vm:~$ docker exec -i postgres psql -U postgres -a < keyvalue.sql
-- keyvalue.sql: a counter, and a cache that does not need to survive a crash
CREATE TABLE page_views (page text PRIMARY KEY, n bigint NOT NULL);
CREATE TABLE
CREATE UNLOGGED TABLE cache (key text PRIMARY KEY, value jsonb NOT NULL, expires_at timestamptz NOT NULL);
CREATE TABLE
INSERT INTO page_views VALUES ('/product/MN-330', 1)
  ON CONFLICT (page) DO UPDATE SET n = page_views.n + 1 RETURNING n;
 n 
---
 1
(1 row)

INSERT 0 1
INSERT INTO page_views VALUES ('/product/MN-330', 1)
  ON CONFLICT (page) DO UPDATE SET n = page_views.n + 1 RETURNING n;
 n 
---
 2
(1 row)

INSERT 0 1
INSERT INTO cache VALUES ('product:MN-330', '{"name": "27-inch monitor", "price": "1499.00"}', now() + interval '5 minutes')
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, expires_at = EXCLUDED.expires_at;
INSERT 0 1
SELECT value FROM cache WHERE key = 'product:MN-330' AND expires_at > now();
                      value                      
-------------------------------------------------
 {"name": "27-inch monitor", "price": "1499.00"}
(1 row)

SELECT relname, relpersistence FROM pg_class WHERE relname IN ('page_views', 'cache');
  relname   | relpersistence 
------------+----------------
 page_views | p
 cache      | u
(2 rows)

```

**`INSERT ... ON CONFLICT DO UPDATE` is the upsert**: insert the key, or update it if it is there,
atomically. The same statement answered 1 and then 2, which is Redis's `INCR` in SQL. The cache
entry carries its own expiry, checked in the `WHERE`; unlike Redis, nothing deletes expired rows
for you, so a scheduled `DELETE` does that.

`relpersistence` says `p` for permanent and **`u` for unlogged**. An unlogged table skips the
write-ahead log, which makes its writes cheaper, and the price is written in the documentation and
easy to prove. Kill the server the way a power cut would, and start it again:

```
ana@vm:~$ docker kill postgres
postgres
ana@vm:~$ docker start postgres
postgres
ana@vm:~$ docker exec postgres psql -U postgres -c "SELECT (SELECT count(*) FROM page_views) AS page_views, (SELECT count(*) FROM cache) AS cache"
 page_views | cache 
------------+-------
          1 |     0
(1 row)

ana@vm:~$ docker logs postgres 2>&1 | grep -E "not properly shut down|redo done|ready to accept" | tail -3
2026-10-11 02:00:59.432 UTC [34] LOG:  database system was not properly shut down; automatic recovery in progress
2026-10-11 02:00:59.512 UTC [34] LOG:  redo done at 0/2C002D8 system usage: CPU: user: 0.05 s, system: 0.01 s, elapsed: 0.07 s
2026-10-11 02:00:59.580 UTC [1] LOG:  database system is ready to accept connections
```

Recovery replayed the log, the counter survived, and **the unlogged cache came back empty**, which
is what a cache is allowed to do and what lesson 13's Redis without persistence does too. The same
choice, made per table.

## A queue: `FOR UPDATE SKIP LOCKED`

Three jobs, and two workers that must never take the same one:

```sql
-- queue.sql: three jobs, for workers that must not take the same one
CREATE TABLE jobs (id bigserial PRIMARY KEY, task text NOT NULL, done boolean NOT NULL DEFAULT false);
INSERT INTO jobs (task) VALUES ('email order 1001'), ('email order 1002'), ('email order 1003');
```

The first worker takes a job and holds it for thirty seconds, in the background; the second asks
while the first still holds it:

```
ana@vm:~$ docker exec -i postgres psql -U postgres -q < queue.sql
ana@vm:~$ docker exec -d postgres psql -U postgres -c "BEGIN; SELECT id FROM jobs WHERE NOT done ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED; SELECT pg_sleep(30); COMMIT;"
ana@vm:~$ docker exec postgres psql -U postgres -c "SELECT id, task FROM jobs WHERE NOT done ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED"
 id |       task       
----+------------------
  2 | email order 1002
(1 row)

ana@vm:~$ docker exec postgres psql -U postgres -c "SELECT locktype, relation::regclass, mode, granted FROM pg_locks WHERE relation = 'jobs'::regclass"
 locktype | relation |     mode     | granted 
----------+----------+--------------+---------
 relation | jobs     | RowShareLock | t
(1 row)
```

The second worker got **job 2, without waiting**: `FOR UPDATE` locks the row it returns, and `SKIP
LOCKED` passes over rows another transaction has locked instead of queuing behind them. The
`RowShareLock` in `pg_locks` is the first worker's mark on the table, still open in its
`pg_sleep`; the row lock itself lives in the row. A worker marks its job `done` and commits; one that
dies rolls back, and the job is free for the next. `LISTEN` and `NOTIFY` add the missing half,
waking the workers when a job arrives instead of having them poll.

## What Postgres does not do as well

Honesty runs both ways, and the gaps are real:

- **Writes on many machines at once.** A Postgres cluster has one primary that takes every write;
  the replicas of `db-reliability` read. When the write volume outgrows the largest machine you can
  buy, sharding Postgres is possible with extensions and with work in the application, and it is
  what Cassandra and MongoDB's sharding were built to do from the start (lessons 10 and 16).
- **Writes in several regions at once.** Accepting writes in São Paulo and Lisbon at the same
  moment, with no primary to wait for across the Atlantic, is Cassandra's multi-datacentre
  replication (lesson 17). Postgres's answer is one region that writes, and readers elsewhere.
- **Memory-speed structures.** Sorted sets, streams with consumer groups and sub-millisecond
  counters are what Redis is (lesson 12); a table with an index is a good counter and a slower
  leaderboard.

Those three are the honest list. **Most applications never reach the first two**, and the third is
usually solved by putting Redis beside Postgres rather than instead of it, which is the subject of
the next two sections.
