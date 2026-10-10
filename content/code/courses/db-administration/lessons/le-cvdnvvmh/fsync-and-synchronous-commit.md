---
title: fsync, synchronous_commit and the difference between them
version: 1
---

Two settings make a write load faster by weakening the guarantee you have just watched hold, and
they look like two strengths of the same knob. **They are not. `synchronous_commit = off` can lose
the last moment of work and leaves the database correct; `fsync = off` can leave it corrupt.** One
is a decision an application may make for itself, the other is a setting nobody should relax on a
database they want to keep.

```
shop=# SHOW fsync;
 fsync 
-------
 on
(1 row)

shop=# SHOW synchronous_commit;
 synchronous_commit 
--------------------
 on
(1 row)

shop=# SHOW wal_writer_delay;
 wal_writer_delay 
------------------
 200ms
(1 row)
```

## What a commit waits for

`fsync` is the system call that asks the operating system to put a file's data on the disk and not
return until it has. **A commit with `synchronous_commit = on` waits for that call on the log**: the
row in `acked.txt` was printed only after the disk had confirmed the commit record. That wait is
most of the time a small write transaction takes.

With `synchronous_commit = off`, `COMMIT` returns as soon as the record is in the WAL buffers in
memory. The walwriter, lesson 7's background process, flushes them every `wal_writer_delay`, so the
log on disk trails the commits by a fraction of a second; in the worst case about three times that
delay. Measure what the wait costs. `PGOPTIONS` hands a setting to the server for these connections
only, so nothing on the server changes and nothing has to be put back:

```
ana@db:~$ pgbench -n -c 4 -T 30 bench | grep -E 'processed|latency|tps'
number of transactions actually processed: 61073
latency average = 1.964 ms
tps = 2036.258559 (without initial connection time)
ana@db:~$ PGOPTIONS='-c synchronous_commit=off' pgbench -n -c 4 -T 30 bench | grep -E 'processed|latency|tps'
number of transactions actually processed: 127610
latency average = 0.940 ms
tps = 4254.118454 (without initial connection time)
```

`-T 30` runs for thirty seconds instead of a fixed count. **Not waiting for the disk roughly
doubled the work done in the same time** on the recording machine, and halved each transaction's
latency. Take the ratio rather than the numbers: these two runs shared four processors and one
disk with other work, and the next pair would measure differently. The ratio depends on how long
the disk takes to confirm a flush. A slow flush — a spinning disk, a network volume — widens the
gap, and a disk with a battery-backed cache narrows it. Lesson 9 measures your disk's flush with
`pg_test_fsync`.

What it costs is exact. After a crash, the commits of the last moment that had not been flushed are
gone, though their clients were told they succeeded. **What is left is still a consistent
database**: those transactions are absent as a whole, as if the crash had come a fraction of a
second earlier, and recovery runs as in the previous section. That makes it a fair trade for work
that can be lost, such as a page-view counter or a session's last-seen time. And the setting can be
made for one transaction only:

```sql
BEGIN;
SET LOCAL synchronous_commit = off;
UPDATE ... ;
COMMIT;
```

`SET LOCAL` lasts until the end of the transaction, so the payments committed by the next session
still wait for the disk.

## Why fsync = off corrupts

`fsync = off` tells the server never to make that call, for the log or for the table files.
Everything still goes to the operating system, which writes it to the disk when and in whatever
order it likes. Lesson 7's rule was that **no page reaches a table file before its description
reaches the log**; with `fsync` off, nothing enforces that order any more. After a power cut the
disk can hold a page whose log record never arrived, or the log of a checkpoint whose pages never
did. Recovery then replays from a redo point that promised pages were written, onto pages that were
not, and the result is damage that nothing reports until a query reads it.

It was not demonstrated here, and the reason is worth knowing: **a `kill -9` cannot show it**. The
operating system survives the kill with every write still in its cache, writes it out later, and
the database comes back fine. That is how `fsync = off` passes every test that is not a real loss
of power or a crash of the kernel itself. The one defensible use is a database you are prepared to
throw away and build again from scratch, such as the first load of a copy you will discard if
anything goes wrong.

| setting, when off | what a crash can cost | consistent afterwards |
| --- | --- | --- |
| `synchronous_commit` | the last fraction of a second of acknowledged commits | yes |
| `fsync` | anything, including data committed long before | no |

Both are back where they started: `synchronous_commit` was changed only for `pgbench`'s connections,
and `fsync` was never touched. Clean up what this lesson made:

```
shop=# DROP TABLE acks;
DROP TABLE

shop=# DROP TABLE notes;
DROP TABLE
ana@db:~$ dropdb bench
ana@db:~$ rm acked.txt acked.err bench.out
```
