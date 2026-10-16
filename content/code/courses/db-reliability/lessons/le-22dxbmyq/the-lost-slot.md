---
title: Capping a slot, and the standby that pays for it
version: 1
---

`max_slot_wal_keep_size` sets how much log any slot may hold. Past it, the primary stops keeping its
promise: the slot is marked **lost**, and the segments are recycled like any others. The default is
`-1`, no limit, which is the setting that turns a forgotten standby into an outage. Set a small one,
to see what happens:

```
shop=# ALTER SYSTEM SET max_slot_wal_keep_size = '32MB';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT slot_name, active, wal_status, pg_size_pretty(pg_current_wal_lsn() - restart_lsn) AS held FROM pg_replication_slots;
 slot_name | active | wal_status | held 
-----------+--------+------------+------
 standby1  | f      | lost       | 
(1 row)
ana@vm:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
81M	/var/lib/postgresql/16/main/pg_wal
```

`wal_status: lost`, and nothing held. The primary has decided, on the standby's behalf, that the
primary's disk matters more than the standby, which is the right decision. `pg_wal` did not shrink at
once, because PostgreSQL keeps recycled segment files around to reuse rather than deleting them; what
changed is that nothing now has to keep them.

The cost lands on the standby. Start it again:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby start
ana@vm:~$ sudo tail -n 3 /var/log/postgresql/postgresql-16-standby.log
2026-10-15 22:03:07.381 -03 [8967] LOG:  started streaming WAL from primary at 0/4000000 on timeline 1
2026-10-15 22:03:07.381 -03 [8967] FATAL:  could not receive data from WAL stream: ERROR:  requested WAL segment 000000010000000000000004 has already been removed
2026-10-15 22:03:07.381 -03 [8951] LOG:  waiting for WAL to become available at 0/4002000
```

It connected, asked for the log from `0/4000000`, and was told **`requested WAL segment
000000010000000000000004 has already been removed`**. It will wait for that log for ever. A standby
in this state is rebuilt from a new base backup, which on a large database takes hours, during which
there is no standby.

Two things soften that, and real setups use both:

- **A cap sized for the outage you want to survive.** If a standby must survive a four-hour network
  outage and the primary writes 5 GB of log an hour, the cap is at least 20 GB, and the primary's disk
  has room for it.
- **An archive beside the slot.** A standby with a `restore_command` pointing at lesson 5's repository
  fetches the segments the primary no longer has from the archive, and then goes back to streaming. The
  slot keeps the recent log close; the archive keeps everything else. Lesson 13 builds that.
