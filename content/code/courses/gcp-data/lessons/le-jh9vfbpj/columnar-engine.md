---
title: The columnar engine, and the query it is for
version: 1
---

**The columnar engine is a second copy of chosen columns, kept in the instance's memory in a column
format, which the planner uses for queries that read many rows and few columns.** The tables on the
storage layer stay exactly as PostgreSQL stores them, row by row. What AlloyDB adds is an in-memory
column store beside them, filled from those tables and kept up to date as they change, and a scan the
planner can choose instead of reading the rows. It is the one thing AlloyDB changes inside the engine
rather than below it.

**The wrong idea is that it makes the database faster.** It makes one shape of query faster: the
report that adds up a column across months of orders. The checkout, which reads one order by its key
and writes one row, gains nothing, because a row store is already the right shape for it. So the
honest way to see what the engine is for is to measure that one shape on an ordinary PostgreSQL, see
where the time goes, and then read what AlloyDB does about it.

**Everything this section runs is plain PostgreSQL 16, not AlloyDB.** There is no columnar engine on
this laptop. The measurement shows what a row store reads for an analytical query, which is the
problem the columnar engine exists to remove; what AlloyDB then does is taught from its
documentation, "About the columnar engine" at cloud.google.com/alloydb/docs/columnar-engine/about,
and marked where it was not run.

## A PostgreSQL of your own

Ubuntu packages PostgreSQL 16, and AlloyDB offers 16 among its versions:

```sh
sudo apt-get install -y postgresql-16
```

**The package starts a server of its own** on port 5432, for the system's use, and this lesson leaves
it alone. You run a second one in `~/gcp`, the way the emulators run: its files in a directory of
yours, in the foreground of a terminal of its own, stopped with `Ctrl+C`. First the directory, once:

```sh
export PATH="/usr/lib/postgresql/16/bin:$PATH"
initdb -D ~/gcp/pg -U quitanda --auth=trust > /dev/null
```

`-U quitanda` names the superuser, and `--auth=trust` lets anyone on this computer connect without a
password, which is acceptable only because the server will listen on no network address at all. Then,
in a terminal of its own:

```sh
cd ~/gcp && export PATH="/usr/lib/postgresql/16/bin:$PATH"
postgres -D ~/gcp/pg -k /tmp -p 5433 -c listen_addresses=''
```

**`listen_addresses=''` is what makes `trust` safe**: the server answers only on a socket file in
`/tmp`, which `-k` names, on port number 5433 so that it never meets the system's server. In the
terminal you type into, four variables tell `psql` where it is:

```sh
export PGHOST=/tmp PGPORT=5433 PGUSER=quitanda PGDATABASE=postgres
```

## Two million orders

`orders.sql`:

```sql
SELECT setseed(0.17);
CREATE TABLE orders (
  order_id     bigint PRIMARY KEY,
  customer_id  integer NOT NULL,
  day          date NOT NULL,
  district     text NOT NULL,
  status       text NOT NULL,
  total_cents  integer NOT NULL,
  address      text NOT NULL,
  notes        text NOT NULL
);
INSERT INTO orders
SELECT n,
       1 + floor(random() * 200000)::int,
       date '2026-01-01' + floor(random() * 304)::int,
       (ARRAY['Pinheiros','Mooca','Lapa','Tatuapé','Santana','Butantã'])[1 + floor(random() * 6)::int],
       (ARRAY['delivered','delivered','delivered','cancelled','pending'])[1 + floor(random() * 5)::int],
       500 + floor(random() * 30000)::int,
       'Rua ' || md5(n::text) || ', ' || floor(random() * 2000)::int,
       repeat(md5((n * 7)::text), 3)
FROM generate_series(1, 2000000) AS n;
VACUUM ANALYZE orders;
```

**Quitanda's orders from January to October 2026, two million of them**, with what an orders table
carries: a customer, a day, a district of São Paulo, a status, a total in integer cents, and the two
wide text columns every real one has, the delivery address and the courier's notes. `setseed` makes
every run write the same rows. `VACUUM ANALYZE` gives the planner its statistics, so the plans below
are the ones a settled table gets.

```
ana@laptop:~/gcp$ psql -q -f orders.sql > /dev/null
ana@laptop:~/gcp$ psql -c "SELECT pg_size_pretty(pg_relation_size('orders')) AS size, pg_relation_size('orders') / 8192 AS pages"
  size  | pages 
--------+-------
 404 MB | 51658
(1 row)
```

**404 MB in 51,658 pages of 8 KiB.** That is the table as a row store holds it: each page carries
whole rows, every column of each one side by side.

## The question the analysts ask

**October's revenue by district** reads three columns, `day`, `district` and `total_cents`, of every
row. The first `SET` keeps the query to one process, so that the count of pages it read is one number
and not three:

```
ana@laptop:~/gcp$ psql -c "SELECT district, count(*), sum(total_cents) FROM orders WHERE day >= '2026-10-01' GROUP BY district ORDER BY district"
 district  | count |    sum    
-----------+-------+-----------
 Butantã   | 33883 | 526003202
 Lapa      | 33605 | 525988004
 Mooca     | 33966 | 524401303
 Pinheiros | 34010 | 525723124
 Santana   | 33972 | 528352923
 Tatuapé   | 34031 | 526205856
(6 rows)

ana@laptop:~/gcp$ psql -c 'SET max_parallel_workers_per_gather = 0' -c "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT district, count(*), sum(total_cents) FROM orders WHERE day >= '2026-10-01' GROUP BY district"
SET
                                QUERY PLAN                                 
---------------------------------------------------------------------------
 HashAggregate (actual time=212.761..212.764 rows=6 loops=1)
   Group Key: district
   Batches: 1  Memory Usage: 24kB
   Buffers: shared hit=14896 read=36762 written=32
   ->  Seq Scan on orders (actual time=0.013..179.844 rows=203467 loops=1)
         Filter: (day >= '2026-10-01'::date)
         Rows Removed by Filter: 1796533
         Buffers: shared hit=14896 read=36762 written=32
 Planning:
   Buffers: shared hit=94
 Planning Time: 0.404 ms
 Execution Time: 212.841 ms
(12 rows)
```

**`Buffers: shared hit=… read=…` is the number to read**: the pages the scan touched, found in
PostgreSQL's cache (`hit`) or fetched from below it (`read`). The two add up to 51,658, the whole
table, for an answer that needed three columns out of eight. The filter on `day` threw away almost
nine rows in ten, `Rows Removed by Filter`, and could not save a single page, because the October
rows are spread through the whole table and every page has to be opened to find them.

**How much of that reading was columns nobody asked for** can be measured with a table that holds
only the three. It is not how anyone should store orders; it is a ruler:

```
ana@laptop:~/gcp$ psql -c 'CREATE TABLE orders_cols AS SELECT day, district, total_cents FROM orders' -c 'VACUUM ANALYZE orders_cols'
SELECT 2000000
VACUUM
ana@laptop:~/gcp$ psql -c "SELECT pg_size_pretty(pg_relation_size('orders_cols')) AS size, pg_relation_size('orders_cols') / 8192 AS pages"
 size  | pages 
-------+-------
 93 MB | 11840
(1 row)

ana@laptop:~/gcp$ psql -c 'SET max_parallel_workers_per_gather = 0' -c "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT district, count(*), sum(total_cents) FROM orders_cols WHERE day >= '2026-10-01' GROUP BY district"
SET
                                  QUERY PLAN                                   
-------------------------------------------------------------------------------
 HashAggregate (actual time=130.354..130.357 rows=6 loops=1)
   Group Key: district
   Batches: 1  Memory Usage: 24kB
   Buffers: shared hit=2080 read=9760
   ->  Seq Scan on orders_cols (actual time=0.030..98.626 rows=203467 loops=1)
         Filter: (day >= '2026-10-01'::date)
         Rows Removed by Filter: 1796533
         Buffers: shared hit=2080 read=9760
 Planning:
   Buffers: shared hit=54
 Planning Time: 0.398 ms
 Execution Time: 130.426 ms
(12 rows)
```

**The same question, a fraction of the pages.** The three columns are 93 MB of the 404, and the
scan that only had them read 11,840 pages instead of 51,658, in 130 milliseconds instead of 212.
Everything else the first scan read was addresses and notes, carried past the query because a row store cannot read part of a row. And even
93 MB is a row store's 93 MB: each of those rows still carries a header of its own, and `district`
spells out `Pinheiros` two million times.

**The checkout is the opposite question**, and the row store's answer to it is hard to beat:

```
ana@laptop:~/gcp$ psql -c 'EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT * FROM orders WHERE order_id = 1234567'
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Index Scan using orders_pkey on orders (actual time=0.052..0.052 rows=1 loops=1)
   Index Cond: (order_id = 1234567)
   Buffers: shared hit=4 read=3
 Planning:
   Buffers: shared hit=114 read=1
 Planning Time: 0.580 ms
 Execution Time: 0.103 ms
(7 rows)
```

**A handful of buffers for a whole order**, every column, through the primary key's index. That is the
work a transactional database does all day, and the columnar engine does not touch it.

## What AlloyDB does about it, not run

**The columnar engine keeps chosen columns in memory, one column at a time, compressed.** A column of
dates is a run of dates, a column with six distinct district names can be held as six names and a
short code per row, and a scan reads only the columns the query names. That removes both costs
the ruler above measured: the columns nobody asked for, and the repetition inside the ones they did.
The scan then processes the values in batches rather than row by row. Google's documentation says the
planner chooses it on cost, like any other plan, and that `EXPLAIN` then shows a columnar scan where
the sequential scan was. **None of that was run here, and no plan from AlloyDB is shown.**

**It is turned on with a database flag and filled in one of two ways.** The flag is
`google_columnar_engine.enabled`, set on the instance, and the memory it may use is a second flag. AlloyDB
can choose the columns itself, from the queries it sees, which its documentation calls
auto-columnarization; or a table is added by hand:

```sql
SELECT google_columnar_engine_add('orders');
```

**Only on AlloyDB.** The PostgreSQL above has never heard of the function:

```
ana@laptop:~/gcp$ psql -c "SELECT google_columnar_engine_add('orders')"
ERROR:  function google_columnar_engine_add(unknown) does not exist
LINE 1: SELECT google_columnar_engine_add('orders')
               ^
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.
```

Two consequences of the design are worth holding before choosing it. The column store is memory,
so it competes with PostgreSQL's own cache for the instance's gigabytes, and a large one may mean a
larger, more expensive machine. And it is a copy: writes to the table have to reach it too, which
AlloyDB does for you, at a cost the analysts' speed is paid with.

**Where it is placed matters as much as whether it is on.** The flag is per instance, so the analysts'
read pool from the previous section can carry a large column store while the primary carries none,
and the checkout never shares its memory with a report. That is the shape Quitanda would build.
