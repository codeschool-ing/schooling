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
        open_datasync                      1940.579 ops/sec     515 usecs/op
        fdatasync                           493.815 ops/sec    2025 usecs/op
        fsync                               608.597 ops/sec    1643 usecs/op
        fsync_writethrough                              n/a
        open_sync                          1702.405 ops/sec     587 usecs/op

Compare file sync methods using two 8kB writes:
(in wal_sync_method preference order, except fdatasync is Linux's default)
        open_datasync                       656.037 ops/sec    1524 usecs/op
        fdatasync                           451.037 ops/sec    2217 usecs/op
        fsync                              1250.452 ops/sec     800 usecs/op
        fsync_writethrough                              n/a
        open_sync                          1197.959 ops/sec     835 usecs/op

Compare open_sync with different write sizes:
(This is designed to compare the cost of writing 16kB in different write
open_sync sizes.)
         1 * 16kB open_sync write          1608.762 ops/sec     622 usecs/op
         2 *  8kB open_sync writes           30.327 ops/sec   32974 usecs/op
         4 *  4kB open_sync writes           11.614 ops/sec   86104 usecs/op
         8 *  2kB open_sync writes           79.238 ops/sec   12620 usecs/op
        16 *  1kB open_sync writes           18.046 ops/sec   55414 usecs/op

Test if fsync on non-write file descriptor is honored:
(If the times are similar, fsync() can sync data written on a different
descriptor.)
        write, fsync, close                1760.753 ops/sec     568 usecs/op
        write, close, fsync                 833.372 ops/sec    1200 usecs/op

Non-sync'ed 8kB writes:
        write                           1851597.114 ops/sec       1 usecs/op
```

**These are the recording machine's numbers and yours will be different.** That machine is a
container on a virtual disk shared with other machines, so its results are slow and they move from
one run to the next, which the rows of one table can be seen doing above. Measure your own disk;
never plan from somebody else's.

## Reading it

Each row is one way of asking the kernel to make a write durable, and the names are the values of
the parameter `wal_sync_method`. The row to read first is **`fdatasync`, Linux's default and what
your server uses**: 493.815 flushes a second, about two milliseconds each, on this machine. One
session committing one transaction at a time can therefore never commit faster than that, whatever
the processor does. Many sessions do better together, because one flush can carry several
transactions' records at once.

The last row is the contrast. **A write that is not flushed lands in the kernel's memory**, and
1,851,597 of them fit in a second. Every row above it is slower by that whole distance because it
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
        open_datasync                   1309761.044 ops/sec       1 usecs/op
        fdatasync                        823959.133 ops/sec       1 usecs/op
        fsync                            881695.748 ops/sec       1 usecs/op
        fsync_writethrough                              n/a
        open_sync                       1136757.993 ops/sec       1 usecs/op
```

Hundreds of thousands of flushes a second is what a flush to nowhere looks like. **A real disk
that reports numbers in that range is keeping its promise in volatile memory**, and a power cut
there loses committed transactions with nothing in the log to say so. The legitimate version is a
controller whose cache has a battery or capacitor behind it, which is fast because it can finish
the write after the power is gone. Without that, the fix is to turn the disk's write cache off,
and the price is the slower number, which was the true one all along.

Unmount the test filesystem when you are done:

```
ana@db:~$ sudo umount /mnt/ram && sudo rmdir /mnt/ram
```
