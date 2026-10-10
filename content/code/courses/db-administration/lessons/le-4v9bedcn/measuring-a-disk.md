---
title: Measuring a disk the way a database uses it
version: 1
---

The number on a disk's box, and the one a file copy shows, is **throughput**: megabytes per second
of large writes. A database committing transactions does something else. Every commit waits until
its write-ahead log record is on stable storage, which lesson 8 showed is a flush, and **the
question is how many flushes per second the disk can do**, each of a few kilobytes. A disk can be
superb at the first and poor at the second, and the second is what a busy server waits on.

PostgreSQL ships a tool that asks exactly that question, `pg_test_fsync`. On Ubuntu it is in
`/usr/lib/postgresql/16/bin`, which is not on your `PATH`. Run it as `postgres`, on the
filesystem you want to measure, which here is the one holding the data directory. `-s 2` makes
each test last two seconds instead of five:

```
ana@db:~$ sudo -u postgres /usr/lib/postgresql/16/bin/pg_test_fsync -s 2 -f /var/lib/postgresql/fsync-test
2 seconds per test
O_DIRECT supported on this platform for open_datasync and open_sync.

Compare file sync methods using one 8kB write:
(in wal_sync_method preference order, except fdatasync is Linux's default)
        open_datasync                      2373.314 ops/sec     421 usecs/op
        fdatasync                          2191.845 ops/sec     456 usecs/op
        fsync                              1839.771 ops/sec     544 usecs/op
        fsync_writethrough                              n/a
        open_sync                          1721.142 ops/sec     581 usecs/op

Compare file sync methods using two 8kB writes:
(in wal_sync_method preference order, except fdatasync is Linux's default)
        open_datasync                       474.004 ops/sec    2110 usecs/op
        fdatasync                           921.902 ops/sec    1085 usecs/op
        fsync                              2034.403 ops/sec     492 usecs/op
        fsync_writethrough                              n/a
        open_sync                           488.275 ops/sec    2048 usecs/op

Compare open_sync with different write sizes:
(This is designed to compare the cost of writing 16kB in different write
open_sync sizes.)
         1 * 16kB open_sync write          1019.868 ops/sec     981 usecs/op
         2 *  8kB open_sync writes          683.440 ops/sec    1463 usecs/op
         4 *  4kB open_sync writes          475.429 ops/sec    2103 usecs/op
         8 *  2kB open_sync writes          206.482 ops/sec    4843 usecs/op
        16 *  1kB open_sync writes           96.756 ops/sec   10335 usecs/op

Test if fsync on non-write file descriptor is honored:
(If the times are similar, fsync() can sync data written on a different
descriptor.)
        write, fsync, close                1934.621 ops/sec     517 usecs/op
        write, close, fsync                1863.918 ops/sec     537 usecs/op

Non-sync'ed 8kB writes:
        write                           2865449.796 ops/sec       0 usecs/op
```

**These are the recording machine's numbers and yours will be different.** That machine is a
container on a virtual disk shared with other machines, so its results move from one run to the
next, and a second run would not print this table again. Measure your own disk; never plan from
somebody else's.

## Reading it

Each row is one way of asking the kernel to make a write durable, and the names are the values of
the parameter `wal_sync_method`. The row to read first is **`fdatasync`, Linux's default and what
your server uses**: 921.902 flushes a second, about a millisecond each, on this machine. One
session committing one transaction at a time can therefore never commit faster than that, whatever
the processor does. Many sessions do better together, because one flush can carry several
transactions' records at once.

The last row is the contrast. **A write that is not flushed lands in the kernel's memory**, and
2,865,449 of them fit in a second. Every row above it is slower by that whole distance because it
waits for the disk. A different `wal_sync_method` can be faster on some hardware, and the first
table is how you would find out; leave the default unless the tool shows a large and repeatable
difference.

## A disk that says yes too quickly

A flush is a promise that the data will survive a power cut, and some storage makes the promise
without keeping it: a disk or controller with a write cache that answers "done" as soon as the
data reaches that cache. The way to recognise one is that its numbers are too good. Here is the
same test on a filesystem that lives entirely in memory, a `tmpfs`, which can never keep the
promise:

```
ana@db:~$ sudo mkdir /mnt/ram && sudo mount -t tmpfs -o size=64M tmpfs /mnt/ram && sudo chmod 1777 /mnt/ram
ana@db:~$ sudo -u postgres /usr/lib/postgresql/16/bin/pg_test_fsync -s 2 -f /mnt/ram/fsync-test | head -10
2 seconds per test
O_DIRECT supported on this platform for open_datasync and open_sync.

Compare file sync methods using one 8kB write:
(in wal_sync_method preference order, except fdatasync is Linux's default)
        open_datasync                   2255872.487 ops/sec       0 usecs/op
        fdatasync                       1867611.442 ops/sec       1 usecs/op
        fsync                           1943467.909 ops/sec       1 usecs/op
        fsync_writethrough                              n/a
        open_sync                       2561443.833 ops/sec       0 usecs/op
```

Nearly two million flushes a second is what a flush to nowhere looks like. **A real disk
that reports numbers in that range is keeping its promise in volatile memory**, and a power cut
there loses committed transactions with nothing in the log to say so. The legitimate version is a
controller whose cache has a battery or capacitor behind it, which is fast because it can finish
the write after the power is gone. Without that, the fix is to turn the disk's write cache off,
and the price is the slower number, which was the true one all along.

Unmount the test filesystem when you are done:

```
ana@db:~$ sudo umount /mnt/ram && sudo rmdir /mnt/ram
```
