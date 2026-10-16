---
title: Measuring the loss you are exposed to now
version: 1
---

The RPO a setup achieves for a lost server is simple to state: **everything written since the last
segment reached the archive.** Lesson 4's `pg_stat_archiver` has both halves of that, the time of the
last archived segment and its name, and one query turns them into the two numbers worth watching.
Save it as `rpo.sql`:

```schooling-example
{"language": "sql", "file": "rpo.sql", "parts": [{"code": "-- rpo.sql: what this server would lose if its disk died now\nSELECT now() - last_archived_time AS since_last_archive,", "note": "How long since a finished segment last reached the archive: everything written since then exists only on this server."}, {"code": "       pg_size_pretty(pg_current_wal_lsn()\n         - ('0/0'::pg_lsn + ((pg_split_walfile_name(left(last_archived_wal, 24))).segment_number + 1) * 16777216))\n         AS not_yet_archived,", "note": "How much log has been written past the end of the last archived segment. The name is cut to its first 24 characters because, just after a backup, the last thing archived is a backup history file whose name carries a suffix."}, {"code": "       current_setting('archive_timeout') AS archive_timeout\nFROM pg_stat_archiver;", "note": "And the setting that puts an upper bound on the first number when the server is quiet."}]}
```

The second column is lesson 4's LSN arithmetic: the end of the last archived segment is its number
plus one, times 16 MB, and the current position minus that is the log that exists only here.

Run it straight after the setup of lesson 5, with a full backup just taken, and again after three
orders and forty quiet seconds:

```
ana@vm:~$ psql -X shop -f rpo.sql
 since_last_archive | not_yet_archived | archive_timeout 
--------------------+------------------+-----------------
 00:00:00.383811    | 0 bytes          | 0
(1 row)

ana@vm:~$ psql -X shop -f rpo.sql
 since_last_archive | not_yet_archived | archive_timeout 
--------------------+------------------+-----------------
 00:00:40.665245    | 1716 kB          | 0
(1 row)
```

The first run is the best moment a server ever has: the backup has just switched and archived the
log, and nothing is outstanding. Forty seconds and three orders later, **1716 kB of log and forty
seconds of work exist only on this machine**, and with `archive_timeout` at 0 nothing bounds how long
that lasts on a quiet afternoon. That is the measured RPO, and it gets worse every second until a
segment fills.

Lesson 4's setting puts a ceiling on it:

```
shop=# ALTER SYSTEM SET archive_timeout = '60s';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
ana@vm:~$ psql -X shop -f rpo.sql
 since_last_archive | not_yet_archived | archive_timeout 
--------------------+------------------+-----------------
 00:00:11.321607    | 0 bytes          | 1min
(1 row)
```

Eleven seconds since the last archive, and a promise that it will never pass about a minute while
anything is written. **The achieved RPO of this setup, for a lost server, is now about a minute.**
Put `rpo.sql` on a schedule and alert when `since_last_archive` passes twice `archive_timeout`: that
one alert covers a broken archive, a hung command and a full repository, because each of them shows up
first as the archive falling behind.
