---
title: The quiet hour, and archive_timeout
version: 1
---

A segment is archived when it is finished, and it is finished when it is full. On a busy database
that is every few seconds. On a quiet one, a segment can take hours to fill, and **every change in
it exists only on the server until it does.**

Here is a quiet shop. One order arrives, and the segment it lands in is not full:

```
shop=# SELECT last_archived_wal, last_archived_time FROM pg_stat_archiver;
    last_archived_wal     |      last_archived_time      
--------------------------+------------------------------
 00000001000000000000000C | 2026-10-10 04:34:18.84311-03
(1 row)

shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (7, 1250, now());
INSERT 0 1

shop=# SELECT pg_walfile_name(pg_current_wal_lsn()), now();
     pg_walfile_name      |              now              
--------------------------+-------------------------------
 00000001000000000000000D | 2026-10-10 04:35:24.554325-03
(1 row)
shop=# SELECT last_archived_wal, last_archived_time, now() FROM pg_stat_archiver;
    last_archived_wal     |      last_archived_time      |             now              
--------------------------+------------------------------+------------------------------
 00000001000000000000000C | 2026-10-10 04:34:18.84311-03 | 2026-10-10 04:35:55.24353-03
(1 row)
```

The order went into segment `0D`. Thirty seconds later the archive still ends at `0C`, archived a
minute before the order existed. If the server's disk died now, the backup would end at `0C`, and
that order would be gone. On a shop that takes one order an hour, a 16 MB segment can stay open
for days, and so can the gap.

`archive_timeout` closes a segment after a set time **if anything was written to it**, so an idle
server does not churn out empty segments, and a quiet one never leaves a change unarchived for
longer than the timeout:

```
shop=# ALTER SYSTEM SET archive_timeout = '60s';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (8, 990, now());
INSERT 0 1

shop=# SELECT pg_walfile_name(pg_current_wal_lsn()), now();
     pg_walfile_name      |              now              
--------------------------+-------------------------------
 00000001000000000000000E | 2026-10-10 04:35:56.850466-03
(1 row)
shop=# SELECT last_archived_wal, last_archived_time FROM pg_stat_archiver;
    last_archived_wal     |      last_archived_time       
--------------------------+-------------------------------
 00000001000000000000000E | 2026-10-10 04:36:56.347137-03
(1 row)
```

Something happened before the new order was even typed. Segment `0D` had been open for more than a
minute with a change in it, so the moment the setting arrived, the server closed it and archived
it; the new order went into `0E`. Sixty seconds later, by `last_archived_time`, `0E` was closed and
archived too, a few kilobytes of log in a 16 MB file.

That is the trade. **Every closed segment costs 16 MB of archive space**, however little is in it,
so a timeout of a minute on a quiet server can write up to 23 GB a day of mostly empty files. They
compress to almost nothing, which is one more reason lesson 5 replaces `cp`. A timeout of one to
five minutes is common; the right one is a number lesson 8 derives from how much loss is acceptable.
