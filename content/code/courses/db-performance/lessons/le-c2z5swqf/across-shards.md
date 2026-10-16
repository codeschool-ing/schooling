---
title: Two shards on one machine, and what crosses the wire
version: 1
---

The quickest way to understand sharding is to build a small one and watch what it does to queries
you already know. This section splits `orders` in two by `customer_id`, puts each half in its own
database, and gives `market` one table that looks like the whole thing. **Everything runs on your
one virtual machine**: the two shard databases stand in for two servers, and the only thing that
would change with real ones is a host name in two lines. What the demonstration cannot show is the
network between real machines, which makes every cost below larger, never smaller.

The tool is **`postgres_fdw`**, a foreign-data wrapper that ships with PostgreSQL: it lets one
database read and write a table that lives in another, sending SQL across a connection. Combined
with lesson 17's hash partitioning, it turns the partitions of a table into tables on other
servers. `market` becomes the **coordinator**, the server the application talks to, and it holds no
order rows at all.

## The shards

Each shard gets the same `orders` table, without the identity column and without the foreign keys:
a shard cannot point at `customers` on another server. Write the file:

```sh
cat > ~/shard-table.sql <<'SQL'
-- shard-table.sql: the orders table as each shard holds it.
CREATE TABLE orders (
    id          bigint      PRIMARY KEY,
    customer_id integer     NOT NULL,
    seller_id   integer     NOT NULL,
    placed_at   timestamptz NOT NULL,
    status      text        NOT NULL,
    total_cents integer     NOT NULL
);
CREATE INDEX orders_customer_id_idx ON orders (customer_id);
SQL
```

And the coordinator's half, which `market` runs:

```sh
cat > ~/coordinator.sql <<'SQL'
-- coordinator.sql: in market, one table whose two halves live on the shards.
CREATE EXTENSION postgres_fdw;

CREATE SERVER shard1 FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', dbname 'shard1', batch_size '1000');
CREATE SERVER shard2 FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', dbname 'shard2', batch_size '1000');
CREATE USER MAPPING FOR CURRENT_USER SERVER shard1
    OPTIONS (user 'ana', password 'shard-lab');
CREATE USER MAPPING FOR CURRENT_USER SERVER shard2
    OPTIONS (user 'ana', password 'shard-lab');

CREATE TABLE sharded_orders (
    id          bigint      NOT NULL,
    customer_id integer     NOT NULL,
    seller_id   integer     NOT NULL,
    placed_at   timestamptz NOT NULL,
    status      text        NOT NULL,
    total_cents integer     NOT NULL
) PARTITION BY HASH (customer_id);

CREATE FOREIGN TABLE sharded_orders_1 PARTITION OF sharded_orders
    FOR VALUES WITH (MODULUS 2, REMAINDER 0)
    SERVER shard1 OPTIONS (table_name 'orders');
CREATE FOREIGN TABLE sharded_orders_2 PARTITION OF sharded_orders
    FOR VALUES WITH (MODULUS 2, REMAINDER 1)
    SERVER shard2 OPTIONS (table_name 'orders');
SQL
```

A `SERVER` says where a shard is, and a `USER MAPPING` how to log in to it. The connection goes
over TCP to `localhost`, as it would to another machine, so your role needs a password, which it
has not needed until now; the last command of this lesson removes it again. `batch_size` lets the
coordinator send rows a thousand at a time instead of one per round trip. Then the two databases,
the table on each, the password, and the coordinator:

```
ana@vm:~$ createdb shard1
ana@vm:~$ createdb shard2
ana@vm:~$ psql -q shard1 -f shard-table.sql
CREATE TABLE
Time: 10.694 ms
CREATE INDEX
Time: 1.669 ms
ana@vm:~$ psql -q shard2 -f shard-table.sql
CREATE TABLE
Time: 8.851 ms
CREATE INDEX
Time: 2.246 ms
ana@vm:~$ psql market -c "ALTER ROLE ana PASSWORD 'shard-lab'"
ALTER ROLE
Time: 10.198 ms
ana@vm:~$ psql market -f coordinator.sql
CREATE EXTENSION
Time: 6.439 ms
CREATE SERVER
Time: 0.900 ms
CREATE SERVER
Time: 0.484 ms
CREATE USER MAPPING
Time: 0.573 ms
CREATE USER MAPPING
Time: 0.465 ms
CREATE TABLE
Time: 1.214 ms
CREATE FOREIGN TABLE
Time: 1.261 ms
CREATE FOREIGN TABLE
Time: 0.851 ms
```

## Loading through the coordinator

`sharded_orders` accepts an `INSERT` like any table and routes each row to the shard its customer
hashes to. Copy the two million orders through it, then `ANALYZE` it: the coordinator keeps no
statistics about rows that live elsewhere until it is told to fetch a sample.

```
market=# INSERT INTO sharded_orders SELECT * FROM orders;
INSERT 0 2000000
Time: 26714.135 ms (00:26.714)

market=# ANALYZE sharded_orders;
ANALYZE
Time: 6184.174 ms (00:06.184)
ana@vm:~$ psql shard1 -c 'SELECT count(*) FROM orders'
 count  
--------
 995080
(1 row)

Time: 114.505 ms
ana@vm:~$ psql shard2 -c 'SELECT count(*) FROM orders'
  count  
---------
 1004920
(1 row)

Time: 57.982 ms
```

**26.7 seconds** to write two million rows across a connection, and **995080 and 1004920** on the
two shards, the even split section 03 promised. In production nobody loads a shard this way; this
is the coordinator showing that routing works.

## A query that names the key, and one that does not

`EXPLAIN (VERBOSE)` shows, for each foreign table, the **Remote SQL**: the exact statement the
coordinator sends to the shard. Read it for one customer and for one seller:

```
market=# EXPLAIN (VERBOSE, COSTS OFF) SELECT id, placed_at, status FROM sharded_orders WHERE customer_id = 42;
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Foreign Scan on public.sharded_orders_1 sharded_orders
   Output: sharded_orders.id, sharded_orders.placed_at, sharded_orders.status
   Remote SQL: SELECT id, placed_at, status FROM public.orders WHERE ((customer_id = 42))
 Query Identifier: 6590819321667672244
(4 rows)

Time: 5.003 ms

market=# EXPLAIN (VERBOSE, COSTS OFF) SELECT id, placed_at, status FROM sharded_orders WHERE seller_id = 42;
                                          QUERY PLAN                                          
----------------------------------------------------------------------------------------------
 Append
   ->  Foreign Scan on public.sharded_orders_1
         Output: sharded_orders_1.id, sharded_orders_1.placed_at, sharded_orders_1.status
         Remote SQL: SELECT id, placed_at, status FROM public.orders WHERE ((seller_id = 42))
   ->  Foreign Scan on public.sharded_orders_2
         Output: sharded_orders_2.id, sharded_orders_2.placed_at, sharded_orders_2.status
         Remote SQL: SELECT id, placed_at, status FROM public.orders WHERE ((seller_id = 42))
 Query Identifier: 5612305663916782031
(8 rows)

Time: 0.845 ms

market=# SELECT count(*) FROM sharded_orders WHERE customer_id = 42;
 count 
-------
    16
(1 row)

Time: 39.265 ms

market=# SELECT count(*) FROM sharded_orders WHERE seller_id = 42;
 count 
-------
  1532
(1 row)

Time: 261.890 ms
```

For customer 42, the plan has **one** `Foreign Scan`, on `sharded_orders_1`. The coordinator
pruned the other partition the way lesson 18 prunes a local one, and the `WHERE` travels inside the
remote SQL, so the shard uses its own index and sends back 16 rows. For seller 42 there is an
`Append` over **both** shards, each sent the same `WHERE seller_id = 42`. Neither shard has an
index on `seller_id`, so each reads its whole table, and the answer took **262 milliseconds**
against **39**. Lesson 1 section 05 measured this same count at 0.8 ms with an index on one server;
here it is the price of asking by a column that is not the key.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three panels, each with the coordinator above two shards. Asking for customer 42, the coordinator sends the query to shard 1 only and 16 rows come back in 39 milliseconds. Asking for seller 42, it sends the query to both shards, each reads its whole table, and the answer takes 262 milliseconds. Counting orders by status, both shards send back every row&#x27;s status, two million values, and the answer takes 2961 milliseconds.\"><rect x=\"8\" y=\"8\" width=\"224\" height=\"254\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"120\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">customer_id = 42</text><rect x=\"58\" y=\"44\" width=\"124\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"61\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">coordinator</text><rect x=\"22\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"66\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">shard1</text><path d=\"M100 78 L58 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M58.0 150.0 L57.6 142.8 L64.5 146.8 Z\" fill=\"var(--amber)\"></path><path d=\"M74 150 L112 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M112.0 78.0 L112.7 85.2 L105.7 81.4 Z\" fill=\"var(--phosphor)\"></path><rect x=\"130\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"174\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">shard2</text><text x=\"120\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">16 rows back</text><text x=\"120\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--amber)\">39 ms</text><rect x=\"248\" y=\"8\" width=\"224\" height=\"254\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"360\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">seller_id = 42</text><rect x=\"298\" y=\"44\" width=\"124\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"61\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">coordinator</text><rect x=\"262\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"306\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">shard1</text><path d=\"M340 78 L298 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M298.0 150.0 L297.6 142.8 L304.5 146.8 Z\" fill=\"var(--amber)\"></path><path d=\"M314 150 L352 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M352.0 78.0 L352.7 85.2 L345.7 81.4 Z\" fill=\"var(--phosphor)\"></path><rect x=\"370\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"414\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">shard2</text><path d=\"M380 78 L406 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M406.0 150.0 L400.2 145.7 L407.7 143.0 Z\" fill=\"var(--amber)\"></path><path d=\"M422 150 L392 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M392.0 78.0 L398.0 82.0 L390.6 85.1 Z\" fill=\"var(--phosphor)\"></path><text x=\"360\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">both read every row</text><text x=\"360\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--amber)\">262 ms</text><rect x=\"488\" y=\"8\" width=\"224\" height=\"254\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"600\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">GROUP BY status</text><rect x=\"538\" y=\"44\" width=\"124\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"61\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">coordinator</text><rect x=\"502\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"546\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">shard1</text><path d=\"M580 78 L538 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M538.0 150.0 L537.6 142.8 L544.5 146.8 Z\" fill=\"var(--amber)\"></path><path d=\"M554 150 L592 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M592.0 78.0 L592.7 85.2 L585.7 81.4 Z\" fill=\"var(--phosphor)\"></path><rect x=\"610\" y=\"150\" width=\"88\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"654\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">shard2</text><path d=\"M620 78 L646 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M646.0 150.0 L640.2 145.7 L647.7 143.0 Z\" fill=\"var(--amber)\"></path><path d=\"M662 150 L632 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M632.0 78.0 L638.0 82.0 L630.6 85.1 Z\" fill=\"var(--phosphor)\"></path><text x=\"600\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">2,000,000 values back</text><text x=\"600\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--amber)\">2961 ms</text></svg>", "caption": "What one query costs depends on whether it names the shard key, and on what the shards have to send back."}
```

## A total across every shard

The operations screen's question, how many orders are in each status, has nothing to do with any
one customer:

```
market=# EXPLAIN (VERBOSE, COSTS OFF) SELECT status, count(*) FROM sharded_orders GROUP BY status;
                         QUERY PLAN                         
------------------------------------------------------------
 HashAggregate
   Output: sharded_orders.status, count(*)
   Group Key: sharded_orders.status
   ->  Append
         ->  Foreign Scan on public.sharded_orders_1
               Output: sharded_orders_1.status
               Remote SQL: SELECT status FROM public.orders
         ->  Foreign Scan on public.sharded_orders_2
               Output: sharded_orders_2.status
               Remote SQL: SELECT status FROM public.orders
 Query Identifier: -6308360315943311234
(11 rows)

Time: 5.791 ms

market=# SELECT status, count(*) FROM sharded_orders GROUP BY status;
  status   |  count  
-----------+---------
 pending   |    7319
 shipped   |   43422
 cancelled |   58372
 delivered | 1890887
(4 rows)

Time: 2961.308 ms (00:02.961)

market=# SELECT status, count(*) FROM orders GROUP BY status;
  status   |  count  
-----------+---------
 cancelled |   58372
 delivered | 1890887
 pending   |    7319
 shipped   |   43422
(4 rows)

Time: 564.862 ms
```

The remote SQL is `SELECT status FROM public.orders`, with no `GROUP BY`: **every shard sends every
row's status to the coordinator**, two million values in all, and the coordinator counts them.
**2961 milliseconds**, against **565** for the same count on the one local table. Nothing about the
answer needed the rows to travel; the coordinator simply could not ask each shard for its four
numbers and add them up.

It can when the grouping is by the shard key. Lesson 18 met `enable_partitionwise_aggregate`; here
it decides whether the aggregate runs on the shards:

```
market=# SELECT customer_id, count(*) FROM sharded_orders GROUP BY customer_id ORDER BY 2 DESC LIMIT 3;
 customer_id | count 
-------------+-------
       70802 |    27
      147415 |    27
      152389 |    27
(3 rows)

Time: 5172.718 ms (00:05.173)

market=# SET enable_partitionwise_aggregate = on;
SET
Time: 0.185 ms

market=# EXPLAIN (VERBOSE, COSTS OFF) SELECT customer_id, count(*) FROM sharded_orders GROUP BY customer_id ORDER BY 2 DESC LIMIT 3;
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Limit
   Output: sharded_orders.customer_id, (count(*))
   ->  Sort
         Output: sharded_orders.customer_id, (count(*))
         Sort Key: (count(*)) DESC
         ->  Append
               ->  Foreign Scan
                     Output: sharded_orders.customer_id, (count(*))
                     Relations: Aggregate on (public.sharded_orders_1 sharded_orders)
                     Remote SQL: SELECT customer_id, count(*) FROM public.orders GROUP BY 1
               ->  Foreign Scan
                     Output: sharded_orders_1.customer_id, (count(*))
                     Relations: Aggregate on (public.sharded_orders_2 sharded_orders_1)
                     Remote SQL: SELECT customer_id, count(*) FROM public.orders GROUP BY 1
 Query Identifier: -3135224596345591721
(15 rows)

Time: 2.346 ms

market=# SELECT customer_id, count(*) FROM sharded_orders GROUP BY customer_id ORDER BY 2 DESC LIMIT 3;
 customer_id | count 
-------------+-------
      152389 |    27
       70802 |    27
      147415 |    27
(3 rows)

Time: 1972.322 ms (00:01.972)
```

With the setting on, each `Foreign Scan` is now **`Aggregate on`** a shard, and the remote SQL
carries the `GROUP BY`. The shards each count their own customers, and only one row per customer
comes back: **5173 milliseconds became 1972**. It works here because every customer lives on exactly
one shard, so each shard's count for a customer is already final. Grouping by `status` cannot be
done that way, because each shard holds part of every status, and the coordinator in PostgreSQL 16
does not send partial aggregates to be combined: that plan pulled the rows. **Group by the key and
the work stays where the data is; group by anything else and the data comes to the work.**

## What a single server did for you, and a shard does not

Three things you have relied on since the first lesson stop working, and each fails differently.

**A unique constraint across shards.** Each shard can guarantee its own `id`s are unique. Nothing
can guarantee it across both:

```
market=# CREATE UNIQUE INDEX ON sharded_orders (id);
ERROR:  cannot create unique index on partitioned table "sharded_orders"
DETAIL:  Table "sharded_orders" contains partitions that are foreign tables.
Time: 4.323 ms

market=# INSERT INTO sharded_orders VALUES (1, 3, 7, now(), 'pending', 1990);
INSERT 0 1
Time: 42.124 ms

market=# SELECT tableoid::regclass AS shard, id, customer_id FROM sharded_orders WHERE id = 1;
      shard       | id | customer_id 
------------------+----+-------------
 sharded_orders_1 |  1 |      144681
 sharded_orders_2 |  1 |           3
(2 rows)

Time: 30.329 ms
```

PostgreSQL refuses the index outright. The `INSERT` of order 1 for customer 3 succeeds, because it
was routed to the shard that does not hold order 1. **Two orders now have the id 1**, one on each
shard, and every system that joins to an order by its id has just become ambiguous.

**A transaction across shards.** The coordinator opens a transaction on each shard it touches and,
at `COMMIT`, commits them **one after the other**. To see what that means, give both shards a
constraint that is only checked at commit time, and make one transaction break it on each side:

```
ana@vm:~$ for s in shard1 shard2; do psql $s -c 'ALTER TABLE orders ADD CONSTRAINT one_order_per_instant UNIQUE (customer_id, placed_at) DEFERRABLE INITIALLY DEFERRED'; done
ALTER TABLE
Time: 1225.333 ms (00:01.225)
ALTER TABLE
Time: 1388.368 ms (00:01.388)
market=# BEGIN;
BEGIN
Time: 0.237 ms

market=*# INSERT INTO sharded_orders VALUES (2000001, 1, 7, now(), 'pending', 1990);
INSERT 0 1
Time: 45.638 ms

market=*# INSERT INTO sharded_orders SELECT 2000002, customer_id, 7, placed_at, 'pending', 1990 FROM sharded_orders WHERE customer_id = 3 ORDER BY id LIMIT 1;
INSERT 0 1
Time: 30.251 ms

market=*# COMMIT;
ERROR:  duplicate key value violates unique constraint "one_order_per_instant"
DETAIL:  Key (customer_id, placed_at)=(3, 2023-04-06 02:16:12.841473+00) already exists.
CONTEXT:  remote SQL command: COMMIT TRANSACTION
Time: 9.517 ms

market=# BEGIN;
BEGIN
Time: 0.112 ms

market=*# INSERT INTO sharded_orders VALUES (2000003, 3, 7, now(), 'pending', 1990);
INSERT 0 1
Time: 96.317 ms

market=*# INSERT INTO sharded_orders SELECT 2000004, customer_id, 7, placed_at, 'pending', 1990 FROM sharded_orders WHERE customer_id = 1 ORDER BY id LIMIT 1;
INSERT 0 1
Time: 415.017 ms

market=*# COMMIT;
ERROR:  duplicate key value violates unique constraint "one_order_per_instant"
DETAIL:  Key (customer_id, placed_at)=(1, 2024-06-06 22:04:01.455383+00) already exists.
CONTEXT:  remote SQL command: COMMIT TRANSACTION
Time: 1.510 ms

market=# SELECT tableoid::regclass AS shard, id, customer_id FROM sharded_orders WHERE id > 2000000;
      shard       |   id    | customer_id 
------------------+---------+-------------
 sharded_orders_1 | 2000001 |           1
(1 row)

Time: 136.903 ms
```

Both `COMMIT`s report the same error, and on the coordinator both transactions look failed. They
are not the same. In the first, shard 1 had already committed order 2000001 when shard 2 refused
its half, and **order 2000001 is still there**: half a transaction, committed, with an error on the
screen. In the second, shard 2 happened to be asked first, refused, and nothing was written. Which
shard is committed first is the coordinator's choice, not yours. A real database cluster closes this
gap with **two-phase commit**, preparing every shard before committing any, and `postgres_fdw` in
PostgreSQL 16 does not use it.

**A join.** A join between two sharded tables on their common key can run inside each shard, which
is the reason section 03 co-located `order_lines` with `orders`. A join on anything else, or with
a table that lives on the coordinator, pulls rows across the wire first, exactly as the status
count did. The planner will do it without complaint and without warning; `EXPLAIN (VERBOSE)` and
its remote SQL are how you find out.

Keep the shards for now: section 05 uses them for the bill.
