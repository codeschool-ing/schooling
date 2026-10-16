---
title: The archive beside the slot
version: 1
---

Lesson 11 capped its slot at 32 MB, lost it, and the standby came back to a primary that no longer had
the log it needed: rebuilt from a new base backup, unless an archive could supply the missing log.
This machine has an archive, lesson 5's pgBackRest repository, receiving every segment the primary
fills. A standby can read from it with a `restore_command`, the setting lessons 5 and 6 found in
every server pgBackRest restored, and then it fetches from the archive whatever the primary no longer
has.

Set one on the standby by hand, as `postgres`, since the standby's configuration belongs to it:

```
ana@vm:~$ sudo -u postgres psql -p 5434 -c "ALTER SYSTEM SET restore_command = 'pgbackrest --stanza=main archive-get %f \"%p\"'"
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 standby restart
```

Now repeat lesson 11's accident: stop the standby, cap the slot, and write enough log to go past it.

```
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
shop=# ALTER SYSTEM SET max_slot_wal_keep_size = '32MB';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT slot_name, wal_status FROM pg_replication_slots;
 slot_name | wal_status 
-----------+------------
 standby1  | lost
(1 row)
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info | grep wal
        wal archive min/max (16): 000000010000000000000002/000000010000000000000014
            wal start/stop: 000000010000000000000003 / 000000010000000000000003
```

The slot is `lost`, and the archive holds everything up to segment `...14`. Start the standby and read
its log:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby start
ana@vm:~$ sudo grep -E "ERROR: \[|FATAL" /var/log/postgresql/postgresql-16-standby.log | tail -n 3
ERROR: [032]: PostgreSQL working directory '/var/lib/postgresql/16/standby' is not the same as option pg1-path '/var/lib/postgresql/16/main'
2026-10-16 00:49:29.113 -03 [2182] FATAL:  could not receive data from WAL stream: ERROR:  requested WAL segment 000000010000000000000012 has already been removed
ERROR: [032]: PostgreSQL working directory '/var/lib/postgresql/16/standby' is not the same as option pg1-path '/var/lib/postgresql/16/main'
```

Two refusals, alternating. The primary has removed segment `...12`, as in lesson 11. And
**pgBackRest refused to fetch it** from the archive: its configuration says the stanza `main` lives in
`/var/lib/postgresql/16/main`, and it checks that the server asking is that one. The standby is another
data directory. The `restore_command` that lesson 5's restore generated carried `--pg1-path` for
exactly this reason; typed by hand, it is the part that gets left out. Add it. `restore_command` can be
changed with a reload:

```
ana@vm:~$ sudo -u postgres psql -p 5434 -c "ALTER SYSTEM SET restore_command = 'pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/standby archive-get %f \"%p\"'"
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 standby reload
ana@vm:~$ sudo grep -E "restored log|FATAL|started streaming" /var/log/postgresql/postgresql-16-standby.log | tail -n 6
2026-10-16 00:49:29.113 -03 [2182] LOG:  started streaming WAL from primary at 0/12000000 on timeline 1
2026-10-16 00:49:29.113 -03 [2182] FATAL:  could not receive data from WAL stream: ERROR:  requested WAL segment 000000010000000000000012 has already been removed
2026-10-16 00:49:29.465 -03 [2120] LOG:  restored log file "000000010000000000000012" from archive
2026-10-16 00:49:29.622 -03 [2120] LOG:  restored log file "000000010000000000000013" from archive
2026-10-16 00:49:29.902 -03 [2120] LOG:  restored log file "000000010000000000000014" from archive
2026-10-16 00:49:30.110 -03 [2220] LOG:  started streaming WAL from primary at 0/15000000 on timeline 1
```

**Three segments restored from the archive, then streaming again**, from where the archive ended.
Nothing was rebuilt. Ask the primary:

```
shop=# SELECT application_name, state, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS behind FROM pg_stat_replication;
 application_name |   state   | behind  
------------------+-----------+---------
 standby1         | streaming | 0 bytes
(1 row)

shop=# SELECT slot_name, active, wal_status FROM pg_replication_slots;
 slot_name | active | wal_status 
-----------+--------+------------
 standby1  | t      | unreserved
(1 row)

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT slot_name, active, wal_status FROM pg_replication_slots;
 slot_name | active | wal_status 
-----------+--------+------------
 standby1  | t      | unreserved
(1 row)
```

Streaming, 0 bytes behind, through the same slot. The slot's status says `unreserved` rather than
`reserved`, and it stayed so after a checkpoint, so it is a poor thing to alert on after an accident like
this one; watch how much the slot holds, as lesson 11 did, and the lag, as this lesson does.

## What each one is for

The slot and the archive do the same job at different distances. **The slot** keeps the recent log
in `pg_wal`, so a standby that drops off for a few minutes resumes from the primary without anything
else involved. **The archive** keeps everything, somewhere else, so a standby that was away longer
than the slot's cap still comes back. A standby with both survives a short outage cheaply and a long one
slowly, and the cap means the slot cannot fill the primary's disk.
