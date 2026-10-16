---
title: The arithmetic, on two machines
version: 1
---

Sizing memory is not a search for the best value of each parameter. It is **a budget: the
machine's memory, divided between the shared cache, the processes' private work, and the
operating system**, with the private part sized against the worst moment rather than the average
one. The method takes five minutes and fits on a card, and the result for your virtual machine is
different from the result for the computer these transcripts came from.

## What the server does not check

One of the parameters is pure belief, and the server will believe anything:

```
ana@db:~$ psql shop
shop=# SET effective_cache_size = '1TB';
SET

shop=# SHOW effective_cache_size;
 effective_cache_size 
----------------------
 1TB
(1 row)

shop=# RESET effective_cache_size;
RESET

shop=# SELECT name, setting FROM pg_settings
shop-#  WHERE name IN ('max_connections', 'autovacuum_max_workers',
shop(#                 'max_parallel_workers_per_gather');
              name               | setting 
---------------------------------+---------
 autovacuum_max_workers          | 3
 max_connections                 | 100
 max_parallel_workers_per_gather | 2
(3 rows)

shop=# \q
```

A terabyte, on a machine with 15 GB, accepted without a word. **`effective_cache_size` allocates
nothing**; it is the planner's estimate of how much of the data is likely to be in memory, in
`shared_buffers` and the page cache together, and it makes index scans look cheaper when it is
large. Set it to what is true, about three quarters of the machine on a dedicated server, and
nothing is spent.

The other three are the multipliers of the budget. `max_connections` is how many processes might
each be running a sort at once. `autovacuum_max_workers` is how many vacuums might each hold
`maintenance_work_mem`. `max_parallel_workers_per_gather` is how many helpers one query may add,
each with its own `work_mem` per step, and on a virtual machine with 2 processors, two helpers and
the process that started them are already more processes than processors.

## The budget, worked for both machines

Four shares, in this order:

1. **`shared_buffers`, a quarter of the memory.** The section on it says why not more.
2. **The operating system and the server's own processes**, half a gigabyte on the small machine
   and a gigabyte on the large one: the kernel, systemd, the postmaster and its workers, each
   connection's process before it sorts anything.
3. **Page cache to keep**, a quarter again. It is what made every `read` in this lesson cheap,
   and a budget that spends it on `work_mem` makes the cache misses real.
4. **What is left is for sorts and hashes**, and `work_mem` is that divided by the number of
   operations that might run at once: `max_connections` times two, as a working guess that a
   typical query has one or two memory-hungry steps.

| | the recommended virtual machine | the recording machine |
|---|---|---|
| memory | 4 GB = 4096 MB | 15 GB = 15360 MB |
| `shared_buffers`, a quarter | 1024 MB | 3840 MB |
| operating system and processes | 512 MB | 1024 MB |
| page cache to keep, a quarter | 1024 MB | 3840 MB |
| left for sorts and hashes | 1536 MB | 6656 MB |
| divided by 100 connections × 2 | 7.7 MB | 33.3 MB |
| **`work_mem`, rounded** | **8MB** | **32MB** |
| `maintenance_work_mem`, four at once | 128MB, 512 MB at most | 512MB, 2 GB at most |
| `effective_cache_size`, three quarters | 3GB | 11GB |

The `maintenance_work_mem` line is the same idea for maintenance: three autovacuum workers and one
index build, four allowances that can coincide, kept inside the share for sorts and hashes.

As files in `conf.d`, the two results are these. Each is the budget above and nothing else:

```ini
# /etc/postgresql/16/main/conf.d/10-memory.conf, for 4 GB of memory
shared_buffers = 1GB
work_mem = 8MB
maintenance_work_mem = 128MB
effective_cache_size = 3GB
```

```ini
# /etc/postgresql/16/main/conf.d/10-memory.conf, for 15 GB of memory
shared_buffers = 3840MB
work_mem = 32MB
maintenance_work_mem = 512MB
effective_cache_size = 11GB
```

## The worst case

The budget assumes two sorts per connection. Nothing enforces that. Take one ordinary report:
two hash joins and a sort, planned in parallel with the two default helpers. Each of the three
processes may use `work_mem` twice over for each hash and once for the sort:

> 3 processes × (2 hashes × 2 + 1 sort) = **15 × `work_mem`**

At 8 MB that is 120 MB for one query, comfortably inside the virtual machine's 1536 MB. Now let
twenty people open that report at the same moment, which is what a dashboard on a Monday morning
does: 2400 MB, more than the whole share, taken from the page cache first and then from nowhere.
**`work_mem` is a ceiling on each step, never a limit on the total**, and the total is decided by
how many connections are busy at once.

When the machine really runs out, Linux's out-of-memory killer picks a process and kills it,
usually the one using the most memory: here, one of the twenty running the report. The postmaster cannot know what state a killed process left shared
memory in, so it **ends every connection and restarts the server** to be safe. One runaway report
becomes an outage for everybody. PostgreSQL's documentation recommends setting the kernel's
`vm.overcommit_memory` to 2 on a dedicated server, so that an allocation that cannot be met fails
inside the one query that asked, and lesson 9 returns to the kernel settings with the disk.

The defences that work are outside the memory parameters. One is **fewer busy connections**,
which is lesson 10 and a connection pooler. The other is a larger `work_mem` given with
`ALTER ROLE … SET` to the roles that need it, instead of to everybody.

## Putting it back

Lesson 7 starts from the same server this lesson started from. Drop the extension and remove the
file:

```
ana@db:~$ psql shop
shop=# DROP EXTENSION pg_buffercache;
DROP EXTENSION

shop=# \q
ana@db:~$ sudo rm /etc/postgresql/16/main/conf.d/10-memory.conf
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ psql shop
shop=# SELECT name, setting, unit, source FROM pg_settings
shop-#  WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem')
shop-#     OR pending_restart;
         name         | setting | unit |       source       
----------------------+---------+------+--------------------
 maintenance_work_mem | 65536   | kB   | default
 shared_buffers       | 16384   | 8kB  | configuration file
 work_mem             | 4096    | kB   | default
(3 rows)

shop=# \dx
                 List of installed extensions
  Name   | Version |   Schema   |         Description          
---------+---------+------------+------------------------------
 plpgsql | 1.0     | pg_catalog | PL/pgSQL procedural language
(1 row)

shop=# \q
```

**Back to 128 MB of `shared_buffers` and the defaults, with nothing pending and no extension but
the one every database has.** The `10-memory.conf` above is what this server would carry in
production; the course leaves the defaults in place because the lessons after this one were recorded against
them.
