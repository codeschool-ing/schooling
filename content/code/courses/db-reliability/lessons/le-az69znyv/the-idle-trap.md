---
title: Two measurements that lie when nothing happens
version: 1
---

When `pgbench` has finished and nobody writes, ask the same question again:

```
shop=# SELECT application_name, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS behind, write_lag, flush_lag, replay_lag FROM pg_stat_replication;
 application_name |  behind  |    write_lag    |    flush_lag    |   replay_lag    
------------------+----------+-----------------+-----------------+-----------------
 standby1         | 40 bytes | 00:00:00.000312 | 00:00:00.000797 | 00:00:00.002042
(1 row)
shop=# SELECT now() - pg_last_xact_replay_timestamp() AS since_last_replay;
 since_last_replay 
-------------------
 00:00:00.629138
(1 row)
shop=# SELECT now() - pg_last_xact_replay_timestamp() AS since_last_replay;
 since_last_replay 
-------------------
 00:00:21.356942
(1 row)
shop=# SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();
 pg_last_wal_receive_lsn | pg_last_wal_replay_lsn 
-------------------------+------------------------
 0/F6377C8               | 0/F6377C8
(1 row)
shop=# SELECT pg_current_wal_lsn();
 pg_current_wal_lsn 
--------------------
 0/F6377C8
(1 row)
```

The `_lag` columns still show milliseconds. They are **the last measurement**, kept until there is a
new one, and they do not grow while nothing is sent, so they say nothing about how long ago that
measurement was made. A standby that stopped receiving five minutes into a quiet night can show the
same small numbers until somebody writes.

The opposite mistake is the more common one. On the standby, `now() - pg_last_xact_replay_timestamp()`
is often recommended as "the lag in seconds", and above it went from 0.6 seconds to **21 seconds** in
twenty seconds of quiet. The standby was not behind at all: it had received and replayed everything up
to `0/F6377C8`, which is exactly where the primary was. The query measures the time since the last
**transaction**, which on an idle primary is the time since anybody wrote. An alert built on it fires
every quiet night and is switched off within a week.

The rule both mistakes lead to: **compare positions, and use time only where something is moving.**
Bytes behind is never wrong about an idle primary, and a time measurement is only meaningful beside it.
