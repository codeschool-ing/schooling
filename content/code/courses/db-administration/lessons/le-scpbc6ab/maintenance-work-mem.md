---
title: maintenance_work_mem and an index build
version: 1
---

`maintenance_work_mem` is `work_mem` for the jobs that are not queries: **`CREATE INDEX`,
`VACUUM`, and adding a foreign key to a table that already has rows**. The default is 64 MB,
sixteen times `work_mem`, and it can afford to be larger because these jobs are few. A server
runs hundreds of sorts a minute and a handful of index builds a month; autovacuum runs at most
`autovacuum_max_workers` vacuums at once, three by default, and each of them takes
`maintenance_work_mem`, because `autovacuum_work_mem` is `-1`.

An index build is a sort: every row's key, in order, written out as the index. So the
interesting question is the same as in the previous section, whether the sort fits.

## One build, two allowances

Build an index on `orders (total_cents)` with almost nothing, then with the default, and drop it
each time. Three settings make the result easy to see. `\timing on` makes `psql` print how long
each statement took. `max_parallel_maintenance_workers = 0` keeps the build in one process, where
the server would otherwise split it across two helpers and divide the memory between them.
`log_temp_files = 0` with `client_min_messages = log` makes the server tell this session about
every temporary file it writes, a superuser's tool that lesson 19 puts in the log for good.

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# SET max_parallel_maintenance_workers = 0;
SET
Time: 0.473 ms

shop=# SET log_temp_files = 0;
SET
Time: 0.212 ms

shop=# SET client_min_messages = log;
SET
Time: 0.290 ms

shop=# SET maintenance_work_mem = '1MB';
SET
Time: 0.307 ms

shop=# CREATE INDEX orders_total_cents ON orders (total_cents);
LOG:  temporary file: path "base/pgsql_tmp/pgsql_tmp299.0", size 20070400
CREATE INDEX
Time: 402.848 ms

shop=# DROP INDEX orders_total_cents;
DROP INDEX
Time: 9.973 ms

shop=# RESET maintenance_work_mem;
RESET
Time: 0.284 ms

shop=# SHOW maintenance_work_mem;
 maintenance_work_mem 
----------------------
 64MB
(1 row)

Time: 0.273 ms

shop=# CREATE INDEX orders_total_cents ON orders (total_cents);
CREATE INDEX
Time: 409.138 ms

shop=# DROP INDEX orders_total_cents;
DROP INDEX
Time: 8.460 ms

shop=# \q
```

With 1 MB, the smallest value the server accepts, **the sort spilled: one temporary file of
20070400 bytes**, about 19 MB, in `base/pgsql_tmp` under the data directory you met in lesson 4.
With the default 64 MB there was no file at all, so the million keys fitted in memory. The server
deletes a temporary file as soon as the operation is done, which is why the log line is the only
trace of it.

Both builds took about half a second on the recording machine, and the two times were close. That
is the same result as the sort in the previous section, for the same reason: 19 MB written and
read back never left the page cache of a machine with 15 GB. **Spilling is cheap while the files
stay in memory, and slow when they have to reach a disk.** On a table
ten or a hundred times the size of `orders`, on a 4 GB virtual machine, the spill no longer fits
in the cache, and every byte of it is written to the disk and read back.

## How to use it

- **Raise it for one build, in the session that runs it.** `SET maintenance_work_mem = '1GB';`
  before a big `CREATE INDEX` and nothing else on the server notices. The default is fine for the
  `shop` tables, as the second build showed.
- **Remember the workers.** A parallel build divides `maintenance_work_mem` among its processes,
  and the server plans fewer workers than `max_parallel_maintenance_workers` when the share each
  would get is too small to be worth it.
- **Count autovacuum.** Three workers, each with `maintenance_work_mem`, can all be running while
  somebody builds an index: four allowances at once. For vacuum, PostgreSQL 16 uses at most 1 GB
  of it whatever the setting says, so a larger value only helps index builds.

`VACUUM` and its workers are lesson 14. What matters here is that the memory they use is this
parameter, multiplied by three on an ordinary server.
