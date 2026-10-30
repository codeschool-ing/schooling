---
title: PostgreSQL itself, in the container
version: 1
---

**A flexible server runs the community's PostgreSQL**, the same engine anybody can download, so the
container lesson 1 set up runs the part of this lesson that is the engine's. Version 17.6, the image
`compose.yaml` names, is a minor release of the major version the previous section declared.

Start it in `~/azure`, and give the client a short name, as lesson 8 did for SQL Server. `psql` is
PostgreSQL's own command-line client and comes inside the container:

```sh
docker compose --profile postgres up -d
pg() { docker compose exec -T postgres psql -U postgres -X "$@"; }
```

`-U postgres` connects as the superuser the image creates, and `-X` skips any personal settings file,
so that what you see is what the engine answers. Then the engine's own description of itself:

```
ana@laptop:~/azure$ pg -c "SELECT version()"
                                                      version                                                       
--------------------------------------------------------------------------------------------------------------------
 PostgreSQL 17.6 (Debian 17.6-2.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
(1 row)

```

## The orders, again

The same hundred thousand orders lesson 8 put in SQL Server, written the way PostgreSQL says it. Save
this as `~/azure/orders-pg.sql`:

`orders-pg.sql`:

```sql
CREATE TABLE orders (
  order_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id int NOT NULL,
  placed_at   timestamptz NOT NULL,
  total_cents int NOT NULL
);
INSERT INTO orders (customer_id, placed_at, total_cents)
SELECT i % 7000, timestamptz '2026-01-01 00:00-03' + i * interval '5 minutes', 1500 + (i * 37) % 30000
FROM generate_series(1, 100000) AS i;
CREATE INDEX orders_customer ON orders (customer_id) INCLUDE (total_cents);
SELECT count(*) AS orders, pg_size_pretty(pg_total_relation_size('orders')) AS size FROM orders;
```

```
ana@laptop:~/azure$ pg < orders-pg.sql
CREATE TABLE
INSERT 0 100000
CREATE INDEX
 orders | size  
--------+-------
 100000 | 10 MB
(1 row)

```

**`generate_series` is PostgreSQL's numbers table**, and it does what lesson 8's `sys.all_objects`
cross join did with less ceremony. The index is the one lesson 8 had to add; here it is part of the
table from the start. And the support screen's question has the same answer as on SQL Server:

```
ana@laptop:~/azure$ pg -c "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT count(*), sum(total_cents) FROM orders WHERE customer_id = 17"
                                QUERY PLAN                                 
---------------------------------------------------------------------------
 Aggregate (actual rows=1 loops=1)
   Buffers: shared hit=15 read=3
   ->  Bitmap Heap Scan on orders (actual rows=15 loops=1)
         Recheck Cond: (customer_id = 17)
         Heap Blocks: exact=15
         Buffers: shared hit=15 read=3
         ->  Bitmap Index Scan on orders_customer (actual rows=15 loops=1)
               Index Cond: (customer_id = 17)
               Buffers: shared read=3
 Planning:
   Buffers: shared hit=77 read=7
(11 rows)

ana@laptop:~/azure$ pg -c "SELECT count(*), sum(total_cents) FROM orders WHERE customer_id = 17"
 count |  sum   
-------+--------
    15 | 256935
(1 row)

```

**Fifteen orders, 256,935 cents, and two kinds of page touched**: `shared hit` counts pages found in
PostgreSQL's own cache and `read` counts pages it had to fetch. That cache is `shared_buffers`, and its
size is a server parameter, which is where the next section starts.

## What Azure changes about the engine, and what it does not

**The engine, its SQL and its plans are the same on a flexible server**, and that is what makes the
container a fair place to practise. Three things differ, and each is a documented property of the
service rather than something run here:

- **you are not the superuser.** The administrator login Azure creates is a member of a role called
  `azure_pg_admin`, which can create databases, roles and the allowed extensions, and cannot do what
  only a superuser can, such as reading the server's files or changing its configuration with SQL;
- **minor versions are applied for you**, in a maintenance window you can choose, and a major upgrade,
  17 to 18, is something you start after testing it;
- **the configuration file is not yours.** The settings live as server parameters, read and written
  through Azure, which is the next section.
