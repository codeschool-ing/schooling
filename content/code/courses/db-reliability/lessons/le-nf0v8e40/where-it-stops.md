---
title: Where a logical backup stops being enough
version: 1
---

A dump is a fine backup for the shop. The question is at what size, and for what loss, it stops
being one, and both have answers you can measure.

## The cost grows with the size

Build a bigger shop beside the real one: the same script, and then nearly three million more
orders. Save this as `more-orders.sql`:

```sql
-- more-orders.sql: grow a copy of the shop to three million orders
INSERT INTO orders (customer_id, total_cents, placed_at)
SELECT 1 + (i::bigint * 7919) % 1000,
       500 + (i::bigint * 104729) % 20000,
       timestamptz '2026-01-01 09:00-03' + i * interval '5 seconds'
FROM generate_series(50001, 3000000) AS i;
```

Load both into a new database and see how big it is. The two `NOTICE` lines are `shop.sql` finding no tables to drop in a database that is new:

```
ana@vm:~$ createdb bigshop
ana@vm:~$ psql -q bigshop -f shop.sql
psql:shop.sql:2: NOTICE:  table "orders" does not exist, skipping
psql:shop.sql:2: NOTICE:  table "customers" does not exist, skipping
ana@vm:~$ psql bigshop -f more-orders.sql
INSERT 0 2950000
ana@vm:~$ psql -X -A -t bigshop -c "SELECT pg_size_pretty(pg_database_size('bigshop'))"
268 MB
```

**268 MB**, with sixty times as many orders as the shop. Dump it, and restore it into the second server, with the
shell's `time` in front of each:

```
ana@vm:~$ time pg_dump -Fc -f bigshop.dump bigshop

real	0m4.350s
user	0m4.095s
sys	0m0.118s
ana@vm:~$ ls -lh bigshop.dump
-rw-r--r-- 1 ana ana 30M Oct 10 04:06 bigshop.dump
ana@vm:~$ createdb -p 5433 bigshop
ana@vm:~$ time pg_restore -p 5433 -d bigshop bigshop.dump

real	0m7.256s
user	0m0.515s
sys	0m0.251s
```

`real` is the time on the wall clock, the one that matters to somebody waiting. **4.4 seconds to
dump and 7.3 to restore**, on the machine this course was recorded on, which has four processors
and a fast disk; yours will be slower. The restore took longer than the dump because it does more
work: every row inserted, then an index and two keys built over three million rows, then checked.

The directory format can use more than one process. Try two, the number lesson 1 gave your
machine:

```
ana@vm:~$ time pg_dump -Fd -j 2 -f bigshop.dir bigshop

real	0m4.022s
user	0m3.837s
sys	0m0.072s
ana@vm:~$ dropdb -p 5433 bigshop
ana@vm:~$ createdb -p 5433 bigshop
ana@vm:~$ time pg_restore -p 5433 -j 2 -d bigshop bigshop.dir

real	0m5.837s
user	0m0.581s
sys	0m0.047s
```

The dump hardly moved, from 4.4 to 4.0 seconds, because **parallel dumping works per table** and
nearly all the data is in one: two workers, one of them with almost nothing to do. The restore
improved, from 7.3 to 5.8, because the indexes and keys are separate pieces of work and the two
workers built them side by side. A database with many large tables gains more; a database that is
one huge table gains little.

## The arithmetic of a big database

At this machine's rate, a restore takes about 7.3 seconds per 268 MB. Multiply that out to a
database of one terabyte and it is **nearly eight hours**, and the real figure is worse, because
building an index grows faster than the number of rows and a server runs out of memory for sorting
long before it runs out of disk. Eight hours during which the application is down, assuming
nothing goes wrong on the first try.

That is the first limit: **a logical restore takes time in proportion to the data, and then some.**
Lesson 3's physical backup copies files instead of rebuilding them, and is restored at the speed
of copying.

## The loss is everything since the dump

The second limit is in what the dump holds. It is the database at one instant, the moment its
snapshot was taken. A nightly dump at two in the morning, and a disk that fails at six in the
evening, lose **sixteen hours of orders**, and no amount of care in the restore brings them back,
because they were never in the file.

Taking dumps more often only narrows that. A dump every hour on a database that takes forty minutes
to dump is a server that spends two thirds of its time dumping. What closes the gap is something
different in kind: a record of every change, kept continuously, which lesson 4 builds out of the
write-ahead log.

## What logical backups remain good for

Neither limit makes them useless, and every serious setup keeps them alongside the physical kind:

- **Moving data between versions and machines**, which a physical copy cannot do: it only restores
  into the same major version on the same kind of processor.
- **Getting one table back**, as the last section did, without restoring a whole server.
- **A second, independent kind of copy.** A bug that corrupts data files is copied faithfully by a
  file-level backup. A dump has to read every row through the database to write it, so a damaged
  page makes the dump fail loudly instead of copying the damage.
- **Small databases**, which restore in less time than this sentence takes to read.
