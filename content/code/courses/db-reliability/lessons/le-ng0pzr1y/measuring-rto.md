---
title: Measuring how long the way back takes
version: 1
---

A restore's time has a part that grows with the size of the database and a part that grows with how
much has happened since the last backup. Lesson 7's drill measured the first: a few seconds to copy
files back. The second is the replay, and it is the one that surprises people, because it depends on
how busy the database was rather than how big it is.

Make the shop's bigger sibling busy. Two updates of every one of its three million orders, with the
log position recorded before:

```
bigshop=# SELECT pg_current_wal_lsn() AS before \gset
bigshop=# \timing on
Timing is on.

bigshop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 3000000
Time: 32822.988 ms (00:32.823)

bigshop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 3000000
Time: 37569.963 ms (00:37.570)

bigshop=# \timing off
Timing is off.

bigshop=# SELECT pg_size_pretty(pg_current_wal_lsn() - :'before');
 pg_size_pretty 
----------------
 2411 MB
(1 row)
```

**2411 MB of write-ahead log** in about seventy seconds of work, more than seven times the size of
the data it changed, for the reasons lesson 4 gave. A full backup was taken before those updates, so
a restore to now has to replay all of it. Lesson 7's drill does exactly that, and its line says how
long each phase took:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main check
ana@vm:~$ ./restore-drill.sh
2026-10-10 22:48:28,20261010-224434F,4.2,55.3,9.2,79.7,ok
```

**4.2 seconds to copy the files back, 55.3 seconds to replay**, and 9.2 to prove the result. The
replay is where the time went: about **44 MB of log a second**, on this machine, fetched from the
repository, decompressed and applied. That rate is the number that turns a log volume into a time.

## From one measurement to the promise

Suppose the real shop writes 20 GB of log on a busy day, and takes a full backup on Sundays only. A
disk failure on Saturday evening means replaying nearly a week of it:

| | log to replay | at 44 MB/s |
|---|---|---|
| full backup weekly, nothing else | up to about 140 GB | about 54 minutes |
| plus a differential every night | up to about 20 GB | about 8 minutes |

The first row on its own may already be more than an RTO of one hour leaves room for, once
noticing, deciding and reconnecting are added. The second row comes from one line of the nightly job.
Neither number is a guess: the volume comes from the database's own log positions, and the rate from
a timed replay of real log on real hardware.

Two cautions about the arithmetic. **Measure on the hardware that will restore**, since a restore
server smaller than the one being replaced replays more slowly. And **measure on a busy day**, because
an RTO is promised for the worst day, not the average one.
