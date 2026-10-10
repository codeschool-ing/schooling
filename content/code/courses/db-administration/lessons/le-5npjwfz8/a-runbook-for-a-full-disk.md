---
title: A runbook for a filling disk
version: 1
---

Here is a complete runbook for one symptom, in the shape of the previous section. It is a
Markdown file, because Markdown reads as plain text in a terminal when nothing renders it, and it
belongs in the same repository as the configuration it is about — lesson 23's `shop-db`, under
`runbooks/disk-filling.md`. Every command in it is one line, so it can be copied whole at an hour
when nobody should be retyping SQL.

```
# Runbook: the disk under PostgreSQL is filling

Applies to: db (PostgreSQL 16 on Ubuntu 24.04, cluster 16/main)
Owner: Ana            Last rehearsed: 2026-10-10

## Symptom
The alert "disk above 85% on /var/lib/postgresql", or clients reporting
errors that contain "No space left on device".

## Impact
Reads and writes still work. At 100% the server can no longer write WAL or
extend a table: writes fail, and the server may stop (lesson 9).
Above 95%, move fast and escalate early.

## Check (read only; write a note after each)
1. How full:            df -h /var/lib/postgresql
2. Where the space is:  sudo du -h -d1 /var/lib/postgresql/16/main | sort -h | tail -4
3. If pg_wal is large, a slot may be holding it:
   psql -c "SELECT slot_name, slot_type, active, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots;"
4. What the server says: sudo tail -n 6 /var/log/postgresql/postgresql-16-main.log
5. If base is large, what grew:
   psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size FROM pg_database ORDER BY pg_database_size(datname) DESC;"
   psql -d DB -c "SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) AS size FROM pg_class WHERE relkind = 'r' ORDER BY pg_total_relation_size(oid) DESC LIMIT 3;"

## Act
A. A slot with active = f retaining WAL (check 3):
   ask the slot's owner whether a replica still uses it. If none does:
   psql -c "SELECT pg_drop_replication_slot('NAME');"
   psql -c "CHECKPOINT;"
B. A table that grew (check 5): delete nothing. Escalate to its owner.
C. Never delete files from pg_wal by hand. The server needs every one it kept.

## Verify
After A: the slot is gone from check 3, and df stops climbing.
pg_wal does NOT shrink at once: the checkpoint recycles old WAL files for
reuse, up to max_wal_size (1GB here). Space comes back only for WAL beyond it.

## Roll back
A cannot be undone. A replica that was using the slot may have to be rebuilt
(db-reliability lessons 11 to 14). This is why A asks first.

## Escalate
Above 95%, or still climbing 30 minutes after an act: call the second line.
Hand over: the incident log, and the output of checks 1 to 3.
```

Two things in it were learnt the hard way rather than designed. **The warning under Verify is
there because the first rehearsal expected `pg_wal` to shrink**, and it did not; the run below
shows why. And **act C is a sentence nobody needs in daylight.** Removing files from `pg_wal`
frees space instantly and leaves a cluster that cannot recover from its next crash. It is also
the most tempting command anybody could type at that hour, which is why the page forbids it
outright.

## Something to find

To run the runbook on your server, give it a problem first: a replication slot that no replica
reads, which keeps every byte of WAL written after it was made, and a table loaded tonight into
the database `ana`:

```sh
psql -c "SELECT pg_create_physical_replication_slot('standby1', true);"
psql -c "CREATE TABLE filler AS SELECT g AS id, repeat('x', 500) AS pad FROM generate_series(1, 600000) AS g;"
```

The `true` makes the slot start holding WAL immediately rather than waiting for a replica to
connect. Then follow the page, check by check.

## Running it

**Check 1**, how full:

```
ana@db:~$ df -h /var/lib/postgresql
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   35G  4.4G  89% /
```

On your virtual machine this is the machine's own disk, and the number is the one the alert
watches. On the recording machine the server's disk is the recording computer's, shared with other
work, so its figures say nothing about PostgreSQL and change from one run to the next. Not at
100%: writes still work, and there is time to look.

**Check 2**, where the space is:

```
ana@db:~$ sudo du -h -d1 /var/lib/postgresql/16/main | sort -h | tail -4
600K	/var/lib/postgresql/16/main/global
467M	/var/lib/postgresql/16/main/base
657M	/var/lib/postgresql/16/main/pg_wal
1.1G	/var/lib/postgresql/16/main
```

`base` is the tables and indexes, and `pg_wal` is larger than all of them together. On a quiet
server the log of changes is a fraction of the data it describes, so this is the finding that
sends you to check 3.

**Check 3**, the slots:

```
ana@db:~$ psql -c "SELECT slot_name, slot_type, active, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots;"
 slot_name | slot_type | active | wal_status | retained 
-----------+-----------+--------+------------+----------
 standby1  | physical  | f      | reserved   | 649 MB
(1 row)
```

**`active = f` with WAL retained is the classic cause.** `restart_lsn` is the oldest point of the
WAL the slot still needs, and `pg_wal_lsn_diff` turns the distance from there to now into bytes:
649 MB that the server must keep for a replica that is not connected. `wal_status` says
`reserved`, which means the retained WAL still fits under `max_wal_size`; it turns to `extended`
past that, and the disk keeps filling for as long as the slot exists. This is the moment act A
says to ask, and the note to write is who you asked.

**Check 4**, what the server says:

```
ana@db:~$ sudo tail -n 6 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:34:08.725 -03 [98] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2026-10-10 04:34:08.728 -03 [104] LOG:  database system was shut down at 2026-10-10 03:18:41 -03
2026-10-10 04:34:08.733 -03 [98] LOG:  database system is ready to accept connections
2026-10-10 04:34:28.499 -03 [102] LOG:  checkpoints are occurring too frequently (20 seconds apart)
2026-10-10 04:34:28.499 -03 [102] HINT:  Consider increasing the configuration parameter "max_wal_size".
2026-10-10 04:34:28.499 -03 [102] LOG:  checkpoint starting: wal
```

No `ERROR`, no `PANIC`, no `No space left on device`: nothing has failed yet. What is there is a
checkpoint started by the amount of WAL written rather than by the clock (`starting: wal`, lesson
8), and the server complaining that it is happening too often. Both say a lot of WAL was written
recently, which agrees with check 2.

**Check 5**, what grew in `base`:

```
ana@db:~$ psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size FROM pg_database ORDER BY pg_database_size(datname) DESC;"
  datname  |  size   
-----------+---------
 ana       | 320 MB
 shop      | 125 MB
 postgres  | 7503 kB
 template1 | 7503 kB
 template0 | 7345 kB
(5 rows)

ana@db:~$ psql -d ana -c "SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) AS size FROM pg_class WHERE relkind = 'r' ORDER BY pg_total_relation_size(oid) DESC LIMIT 3;"
  relname   |  size   
------------+---------
 filler     | 313 MB
 pg_proc    | 1216 kB
 pg_rewrite | 728 kB
(3 rows)
```

The database `ana` is bigger than `shop`, which nobody expected, and one table is almost all of
it. `pg_total_relation_size` counts the table with its indexes and TOAST, which is what occupies
the disk. **Act B says delete nothing**: a table you did not create belongs to somebody, and the
runbook's job is to find it and hand it over. `DB` in the runbook's second command is replaced by
the database the first one pointed at.

## Act, verify

The owner of `standby1` has said no replica uses it any more, so act A:

```
ana@db:~$ psql -c "SELECT pg_drop_replication_slot('standby1');"
 pg_drop_replication_slot 
--------------------------
 
(1 row)

ana@db:~$ psql -c "CHECKPOINT;"
CHECKPOINT
```

And the verify:

```
ana@db:~$ psql -c "SELECT count(*) AS slots FROM pg_replication_slots;"
 slots 
-------
     0
(1 row)

ana@db:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
673M	/var/lib/postgresql/16/main/pg_wal
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:34:33.546 -03 [102] LOG:  checkpoint complete: wrote 1086 buffers (6.6%); 0 WAL file(s) added, 0 removed, 40 recycled; write=0.011 s, sync=0.009 s, total=0.086 s; sync files=5, longest=0.007 s, average=0.002 s; distance=128710 kB, estimate=495458 kB; lsn=0/29E45150, redo lsn=0/29E45118
```

The slot is gone, and **`pg_wal` is no smaller.** The checkpoint's own line says why: `0
removed, 40 recycled`. A WAL file the server no longer needs is renamed and kept for future
writes, as long as `pg_wal` stays under `max_wal_size`, because reusing a file is cheaper than
creating one. All 649 MB the slot held fitted under the 1 GB limit, so all of it was recycled.
What has changed is that nothing is holding WAL any more, so `pg_wal` stops growing. On a real
night the slot would have held far more than `max_wal_size`, and everything beyond it would have
been removed at this checkpoint. A runbook whose verify said "pg_wal shrinks" would send you
looking for a second problem that does not exist, which is why the warning is in the page.

## Putting it back

The slot is gone already. Remove the table you loaded, and your server is as lesson 5 left it:

```
ana@db:~$ psql -c "DROP TABLE filler;"
DROP TABLE
```
