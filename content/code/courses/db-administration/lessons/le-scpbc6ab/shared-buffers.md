---
title: shared_buffers and the cache underneath it
version: 1
---

**`shared_buffers` is PostgreSQL's own cache of table and index pages**, and every read and write
goes through it: a query that needs a page looks there first, and only on a miss asks the
operating system for the 8 kB from the file. The common belief is that this cache should be as
large as the machine allows, the way a cache usually should. It should not, because it is not the
only cache: **the operating system keeps its own copy of recently read file blocks** in the page
cache, the `buff/cache` column of `free`. A page PostgreSQL asks for is often already there, and
memory given to one of the two caches is taken from the other.

That is why the usual starting point is **a quarter of the machine's memory**. The PostgreSQL
documentation suggests 25% on a dedicated server and says more than 40% is unlikely to beat a
smaller value. The rest goes to the processes' private memory and to the page cache, which then
holds most of what `shared_buffers` does not.

## What the cache holds

`pg_buffercache` is an extension that ships with the server and shows the cache from the inside.
Restart first, so the cache starts empty, and then read the whole of `orders`:

```
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ psql shop
shop=# CREATE EXTENSION pg_buffercache;
CREATE EXTENSION

shop=# SELECT buffers_used, buffers_unused FROM pg_buffercache_summary();
 buffers_used | buffers_unused 
--------------+----------------
          257 |          16127
(1 row)

shop=# SELECT pg_size_pretty(pg_relation_size('orders')) AS size,
shop-#        pg_relation_size('orders') / 8192 AS pages;
 size  | pages 
-------+-------
 65 MB |  8334
(1 row)

shop=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=102.672..106.803 rows=1 loops=1)
   Buffers: shared read=8334
   ->  Gather (actual time=102.657..106.791 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared read=8334
         ->  Partial Aggregate (actual time=89.550..89.552 rows=1 loops=3)
               Buffers: shared read=8334
               ->  Parallel Seq Scan on orders (actual time=0.019..55.617 rows=333333 loops=3)
                     Buffers: shared read=8334
 Planning:
   Buffers: shared hit=69 read=19 dirtied=2
 Planning Time: 0.619 ms
 Execution Time: 106.895 ms
(14 rows)

shop=# SELECT c.relname, count(*) AS buffers
shop-#   FROM pg_buffercache b
shop-#   JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
shop-#  WHERE b.reldatabase = (SELECT oid FROM pg_database WHERE datname = current_database())
shop-#  GROUP BY c.relname ORDER BY buffers DESC LIMIT 3;
   relname    | buffers 
--------------+---------
 orders       |      96
 pg_attribute |      31
 pg_proc      |      16
(3 rows)

shop=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=112.746..114.307 rows=1 loops=1)
   Buffers: shared hit=96 read=8238
   ->  Gather (actual time=112.737..114.299 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=96 read=8238
         ->  Partial Aggregate (actual time=95.500..95.502 rows=1 loops=3)
               Buffers: shared hit=96 read=8238
               ->  Parallel Seq Scan on orders (actual time=0.031..62.150 rows=333333 loops=3)
                     Buffers: shared hit=96 read=8238
 Planning Time: 0.096 ms
 Execution Time: 114.343 ms
(12 rows)

shop=# \q
```

The cache has 16384 buffers, one per 8 kB page, and the restart left all but a few hundred
unused. `orders` is 8334 pages. `BUFFERS` adds a line to every step of the plan: **`hit` is a page
found in `shared_buffers`, `read` is one that had to be asked for**. Reading EXPLAIN properly is
db-performance lesson 3; here only that one line matters. The first count read all 8334.

Then the surprise. The table is 65 MB and the cache 128 MB, so the whole table ought to be in it
now, and **only 96 of its pages are**. The second count found those 96 and read the other 8238
again. This is deliberate: a sequential scan of a table larger than a quarter of
`shared_buffers` gets a small ring of 32 buffers instead of the whole cache, so that one big scan
cannot throw out every other table's pages. Three processes scanned it in parallel, the
`Workers Launched: 2` plus the one that started them, and 3 rings of 32 is the 96.

The `read` pages were not slow, either: both counts took a fraction of a second, because
**every page was in the operating system's page cache**, warm from the last time the table was
read, so "read" meant a copy from one part of memory to another. That is the double caching the first
paragraph described, seen from the outside: the server's cache missed and the machine's did not.

## A quarter of the virtual machine

On the virtual machine lesson 3 recommends, a quarter of 4 GB is 1 GB. Put it in a file in
`conf.d`, as lesson 5 did, and restart, because `shared_buffers` is a `postmaster` parameter:

```
ana@db:~$ echo 'shared_buffers = 1GB' | sudo tee /etc/postgresql/16/main/conf.d/10-memory.conf
shared_buffers = 1GB
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ psql shop
shop=# SELECT name, setting, unit FROM pg_settings
shop-#  WHERE name IN ('shared_buffers', 'shared_memory_size');
        name        | setting | unit 
--------------------+---------+------
 shared_buffers     | 131072  | 8kB
 shared_memory_size | 1074    | MB
(2 rows)

shop=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=114.404..117.692 rows=1 loops=1)
   Buffers: shared read=8334
   ->  Gather (actual time=109.975..117.674 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared read=8334
         ->  Partial Aggregate (actual time=104.727..104.729 rows=1 loops=3)
               Buffers: shared read=8334
               ->  Parallel Seq Scan on orders (actual time=0.017..79.448 rows=333333 loops=3)
                     Buffers: shared read=8334
 Planning:
   Buffers: shared hit=82 read=17
 Planning Time: 0.439 ms
 Execution Time: 117.749 ms
(14 rows)

shop=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM orders;
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Finalize Aggregate (actual time=107.340..114.517 rows=1 loops=1)
   Buffers: shared hit=8334
   ->  Gather (actual time=101.944..114.499 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=8334
         ->  Partial Aggregate (actual time=98.267..98.268 rows=1 loops=3)
               Buffers: shared hit=8334
               ->  Parallel Seq Scan on orders (actual time=0.012..65.756 rows=333333 loops=3)
                     Buffers: shared hit=8334
 Planning Time: 0.090 ms
 Execution Time: 114.562 ms
(12 rows)

shop=# SELECT buffers_used, buffers_unused FROM pg_buffercache_summary();
 buffers_used | buffers_unused 
--------------+----------------
         8569 |         122503
(1 row)

shop=# \q
```

`131072` pages of 8 kB is the 1 GB, and the whole shared segment grew to 1074 MB with it. The
extension survived the restart, because it lives in the database; the cache it shows did not.
Now the table is smaller than a quarter of the cache, the scan used ordinary buffers, and **the
second count was all hits, `hit=8334`**, with every page of `orders` in the 8569 buffers in use.

The time barely moved, and that is the honest result on this machine: the page cache was already
serving the misses from memory. The difference shows on a machine whose working set does not fit
in memory twice over, where a miss in both caches is a real read from the disk, and on queries
that touch the same pages over and over, such as an index walked by thousands of lookups.

## Settled at start, gone at a restart

Three consequences of the cache being one block of shared memory:

- **Changing it costs a restart**, and the restart empties it. The first minutes afterwards run
  against a cold cache, which is one more reason restarts are scheduled (lesson 5).
- **It is allocated whether or not it is used.** The 122503 unused buffers above are memory the
  machine cannot give to anything else.
- **On Linux it can sit in huge pages**, 2 MB pages instead of 4 kB ones, which saves the kernel
  work on a large cache. `huge_pages = try`, the default, uses them only if the kernel has some
  reserved, and reserving them is a kernel setting (`vm.nr_hugepages`) that a server with a cache
  of several gigabytes is worth the trouble for and a 4 GB virtual machine is not.

Leave `10-memory.conf` in place for now. The next two sections use the default `work_mem` and
`maintenance_work_mem` with this cache, and the last one removes the file.
