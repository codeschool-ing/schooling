---
title: Full-page writes, and what checkpoints cost
version: 1
---

Lesson 7 found that the first change to a page after a checkpoint carries a copy of the whole page,
so that recovery can repair a page the power cut tore in half. **Every checkpoint restarts that
rule for every page**, which is the hidden price of having many of them. The previous section ran
40,000 transactions with checkpoints falling due every 32 MB of log. Put `max_wal_size` back, zero
the counters, and run exactly the same work:

```
bench=# ALTER SYSTEM RESET max_wal_size;
ALTER SYSTEM

bench=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

bench=# CHECKPOINT;
CHECKPOINT

bench=# SELECT pg_stat_reset_shared('bgwriter'), pg_stat_reset_shared('wal');
 pg_stat_reset_shared | pg_stat_reset_shared 
----------------------+----------------------
                      | 
(1 row)
ana@db:~$ pgbench -n -c 4 -t 10000 bench | tail -n 1
tps = 2648.746484 (without initial connection time)
bench=# SELECT checkpoints_timed, checkpoints_req FROM pg_stat_bgwriter;
 checkpoints_timed | checkpoints_req 
-------------------+-----------------
                 0 |               0
(1 row)

bench=# SELECT wal_records, wal_fpi, pg_size_pretty(wal_bytes) AS wal FROM pg_stat_wal;
 wal_records | wal_fpi |  wal   
-------------+---------+--------
      251257 |   27489 | 224 MB
(1 row)
```

`ALTER SYSTEM RESET` removes the line from `postgresql.auto.conf`, so the server is back on the
1 GB in `postgresql.conf`. Side by side, the two runs did the same 40,000 transactions:

| | `max_wal_size = 64MB` | default, 1 GB |
| --- | --- | --- |
| checkpoints during the run | 14 | 0 |
| WAL records (`wal_records`) | 269350 | 251257 |
| full-page images (`wal_fpi`) | 59334 | 27489 |
| WAL written | 461 MB | 224 MB |
| transactions per second | 2597 | 2648 |

**The frequent checkpoints wrote twice the log for the same work**, and nearly all of the extra is
page images: the number of records barely moved, the number of images more than doubled. Each
checkpoint made every page the workload touched pay for a fresh image on its next change. Even
the quiet run took 27489 images, because it started straight after a `CHECKPOINT` and every page
it touched paid once.

The speed hardly moved on this machine, and that is the trap. The cost lands as WAL: twice the
disk writes, twice the traffic to every replica, twice the segments to archive. Nothing on the
application's side would have noticed.

## Why it stays on

The setting is `full_page_writes`, and it is on:

```
bench=# SHOW full_page_writes;
 full_page_writes 
------------------
 on
(1 row)

bench=# SHOW wal_compression;
 wal_compression 
-----------------
 off
(1 row)
```

Turning it off removes the images and most of the volume the table shows. **It also removes the
only repair for a torn page.** After a power cut in the middle of writing a page, recovery would
replay a small record onto a page that is half old and half new, and the result is a corrupt page
that nothing reports until a query reads it. The setting exists for storage that can promise a
page is never torn — a filesystem such as ZFS, which never overwrites a block in place — and on
ext4 or XFS, which lesson 9 looks at, it stays on.

The levers that are safe are the ones already met: **fewer checkpoints**, by a `max_wal_size` that
fits the load, and smaller images, with `wal_compression`, which trades processor time for
log volume and is worth measuring on a server that writes a lot.
