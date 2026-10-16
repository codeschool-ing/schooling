---
title: When the archive command fails
version: 1
---

An archive fails in ordinary ways: a network share goes away, a disk fills, a credential expires,
somebody changes a directory's permissions. Do the last one, make the server finish a segment, and
watch:

```
ana@vm:~$ sudo chmod 500 /var/lib/postgresql/wal-archive
shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50000

shop=# SELECT pg_switch_wal();
 pg_switch_wal 
---------------
 0/64E8FB8
(1 row)
shop=# SELECT archived_count, last_archived_wal, failed_count, last_failed_wal FROM pg_stat_archiver;
 archived_count |    last_archived_wal     | failed_count |     last_failed_wal      
----------------+--------------------------+--------------+--------------------------
              1 | 000000010000000000000004 |            5 | 000000010000000000000005
(1 row)
ana@vm:~$ sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log
cp: cannot create regular file '/var/lib/postgresql/wal-archive/000000010000000000000005': Permission denied
2026-10-10 04:34:13.007 -03 [8697] LOG:  archive command failed with exit code 1
2026-10-10 04:34:13.007 -03 [8697] DETAIL:  The failed archive command was: test ! -f /var/lib/postgresql/wal-archive/000000010000000000000005 && cp pg_wal/000000010000000000000005 /var/lib/postgresql/wal-archive/000000010000000000000005
2026-10-10 04:34:13.007 -03 [8697] WARNING:  archiving write-ahead log file "000000010000000000000005" failed too many times, will try again later
```

`failed_count` is 5 already, for one segment: the server retries a failing segment a few times in
a row, gives up for a minute, and tries again, counting every attempt. `last_failed_wal` names the
segment that will not go. The log says why in the words of the command itself (`cp: cannot create
regular file … Permission denied`), then shows the exact command that failed, which is the line you
copy into a terminal to reproduce the problem.

Nothing else happened. **No query failed, no client was told, the database carried on.** That is
correct behaviour, because the alternative is a database that stops whenever its backups have a
problem. It is also what makes this failure dangerous: the only places it shows are a log line and
a counter.

## What the server does with segments it cannot archive

It keeps them. A segment is not recycled until it is archived, so every segment written while the
archive is broken stays in `pg_wal`. Each one is marked by a file in `archive_status`, `.ready` for
waiting and `.done` for archived:

```
ana@vm:~$ sudo ls /var/lib/postgresql/16/main/pg_wal/archive_status
000000010000000000000004.done
000000010000000000000005.ready
000000010000000000000006.ready
ana@vm:~$ for i in 1 2 3 4 5 6; do psql -q shop -c "UPDATE orders SET total_cents = total_cents + 1" -c "SELECT pg_switch_wal()" > /dev/null; done
ana@vm:~$ sudo ls /var/lib/postgresql/16/main/pg_wal/archive_status | grep -c ready
8
ana@vm:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
145M	/var/lib/postgresql/16/main/pg_wal
```

Six more updates, and eight segments waiting, **145 MB of log the server must keep** and cannot get
rid of. The arithmetic of a real failure is the same with bigger numbers: a database writing 2 GB of
log an hour, with an archive that broke on Friday evening, has 120 GB of `pg_wal` by Monday morning.
When the disk holding `pg_wal` fills, the server cannot write the log, and a server that cannot
write the log **stops accepting writes and shuts down**. A backup problem that nobody saw becomes an
outage that everybody sees.

## Fixing it, and watching it catch up

Put the permission back, and give the server a minute to retry:

```
ana@vm:~$ sudo chmod 700 /var/lib/postgresql/wal-archive
shop=# SELECT archived_count, last_archived_wal, failed_count FROM pg_stat_archiver;
 archived_count |    last_archived_wal     | failed_count 
----------------+--------------------------+--------------
              9 | 00000001000000000000000C |           13
(1 row)
ana@vm:~$ sudo ls /var/lib/postgresql/16/main/pg_wal/archive_status | grep -c ready
0
```

Nine archived, nothing waiting. The server archived the backlog in order, oldest first, and from
here recycles those segments normally. `failed_count` stays at 13: it counts attempts since the
statistics were last reset, not current trouble, which is why an alert has to compare it with its
previous value rather than with zero.

## What to alert on

Three conditions cover every way archiving goes wrong, and each one is a query on `pg_stat_archiver`
or a look at a directory:

- **`failed_count` went up** since the last check. Something failed, even if it recovered.
- **`last_archived_time` is older than it should be.** On a busy server, more than a few minutes;
  on a quiet one, more than `archive_timeout`, which the next section sets. This catches the command
  that hangs instead of failing.
- **The number of `.ready` files keeps growing**, or `pg_wal` is above its usual size. This is the
  one that predicts the outage, and the one to page somebody for.
