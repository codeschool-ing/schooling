---
title: How big pg_wal gets, and what keeps it big
version: 1
---

Lesson 4 found `pg_wal` larger than the data and promised to say what bounds it. Two wrong pictures
are common: that the directory grows for ever until somebody cleans it, and that it is a fixed
allowance the server never passes. **The log is trimmed at every checkpoint, to a size the
settings steer but do not cap.**

## Recycled, not deleted

Once a checkpoint has finished, every segment older than the point it started from is no longer
needed for crash recovery. The server then deals with each one: it **recycles** it, renaming the
file to a name the log will reach later so that it can be overwritten instead of created, or it
**removes** it. The settings that steer that choice:

```
shop=# SELECT name, setting, unit FROM pg_settings
shop-#  WHERE name IN ('max_wal_size', 'min_wal_size', 'wal_keep_size',
shop(#                 'max_slot_wal_keep_size', 'wal_segment_size');
          name          | setting  | unit 
------------------------+----------+------
 max_slot_wal_keep_size | -1       | MB
 max_wal_size           | 1024     | MB
 min_wal_size           | 80       | MB
 wal_keep_size          | 0        | MB
 wal_segment_size       | 16777216 | B
(5 rows)
```

| setting | here | what it decides |
| --- | --- | --- |
| `max_wal_size` | 1 GB | how large the log may grow before the server forces a checkpoint to bring it down. A target, not a wall: a burst of writes, or one of the things below, takes `pg_wal` past it, and lesson 8 shows what happens when it is set too small |
| `min_wal_size` | 80 MB | the least the server keeps for recycling, so that a quiet hour does not delete files a busy one will have to create again |
| `wal_keep_size` | 0 | extra log kept for replicas that might fall behind; zero keeps none |
| `max_slot_wal_keep_size` | -1 | how much replication slots may hold, and -1 means no limit. The rest of this section is about this one |

The previous section's two big updates left the directory larger than lesson 4 found it. Measure
it, ask for a checkpoint, read the line the checkpoint logged, and measure again:

```
ana@db:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
417M	/var/lib/postgresql/16/main/pg_wal
shop=# CHECKPOINT;
CHECKPOINT
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:26:48.342 -03 [102] LOG:  checkpoint complete: wrote 7 buffers (0.0%); 0 WAL file(s) added, 0 removed, 25 recycled; write=0.453 s, sync=0.305 s, total=1.220 s; sync files=8, longest=0.203 s, average=0.039 s; distance=414064 kB, estimate=414064 kB; lsn=0/3489B300, redo lsn=0/3489B2C8
ana@db:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
417M	/var/lib/postgresql/16/main/pg_wal
```

**`25 recycled`, and the directory is exactly as big as before.** Twenty-five old segments were
renamed and wait to be written over; none was removed, because the server has just seen it needs
about that much between checkpoints — that is the `estimate` near the end of the line. If the next
hours are quiet, later checkpoints remove the spares down towards `min_wal_size`. So a large
`pg_wal` after a burst is normal, and it is bounded by the burst. Lesson 8 reads the rest of that
log line.

## The slot nobody is reading

A replica that streams the log can ask the primary to keep every segment it has not received yet,
so that a replica switched off for a night can catch up in the morning. That promise is a
**replication slot**, and it holds the log from its position onwards **whether or not anything is
connected to it**. Make one by hand, with nothing behind it, the way a replica that was later
removed leaves one behind:

```
shop=# SELECT pg_create_physical_replication_slot('forgotten', true);
 pg_create_physical_replication_slot 
-------------------------------------
 (forgotten,0/3489B2C8)
(1 row)

shop=# CREATE TABLE orders_copy AS SELECT * FROM orders;
SELECT 1000000

shop=# UPDATE orders_copy SET total_cents = total_cents + 1;
UPDATE 1000000

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT slot_name, active, wal_status,
shop-#        pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS held
shop-#   FROM pg_replication_slots;
 slot_name | active | wal_status |  held  
-----------+--------+------------+--------
 forgotten | f      | reserved   | 260 MB
(1 row)
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:26:52.231 -03 [102] LOG:  checkpoint complete: wrote 15937 buffers (97.3%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.056 s, sync=0.126 s, total=0.188 s; sync files=24, longest=0.110 s, average=0.006 s; distance=266516 kB, estimate=399309 kB; lsn=0/44CE06E8, redo lsn=0/44CE06B0
```

The `true` asks the slot to start holding the log at once. `active` is `f`, nothing is connected,
and the slot is holding 260 MB. **The checkpoint recycled nothing**: `0 removed, 0 recycled`, because
every segment since the slot was made is promised to a reader that does not exist. Nothing else
happens. No error, no warning in the log, and the server keeps working perfectly until the disk is
full, at which point it stops.

Drop the slot and checkpoint again:

```
shop=# SELECT pg_drop_replication_slot('forgotten');
 pg_drop_replication_slot 
--------------------------
 
(1 row)

shop=# CHECKPOINT;
CHECKPOINT
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:26:54.232 -03 [102] LOG:  checkpoint complete: wrote 0 buffers (0.0%); 0 WAL file(s) added, 0 removed, 16 recycled; write=0.001 s, sync=0.001 s, total=0.013 s; sync files=0, longest=0.000 s, average=0.000 s; distance=0 kB, estimate=359378 kB; lsn=0/44CE0798, redo lsn=0/44CE0760
```

**`16 recycled` the moment the promise is gone.** On a real server that slot might have been
holding for weeks. Two habits follow. Check `pg_replication_slots` for a slot that is not `active`
whenever `pg_wal` is larger than you expect; lesson 24 builds that check into the runbook for a
full disk. And consider setting `max_slot_wal_keep_size`, which lets the server give up on a slot
that holds more than that much: the replica behind it then has to be rebuilt, which is the
trade db-reliability's lessons on replication weigh.

Clean up what this lesson made:

```
shop=# DROP TABLE orders_copy;
DROP TABLE

shop=# DROP TABLE notes;
DROP TABLE
```
