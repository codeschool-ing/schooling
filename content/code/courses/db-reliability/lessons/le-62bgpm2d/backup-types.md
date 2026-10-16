---
title: Full, differential and incremental
version: 1
---

pgBackRest takes three kinds of backup. Start with the one everything else depends on:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main backup --type=full
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: ok
    cipher: none

    db (current)
        wal archive min/max (16): 000000010000000000000002/000000010000000000000004

        full backup: 20261010-162731F
            timestamp start/stop: 2026-10-10 16:27:31-03 / 2026-10-10 16:27:35-03
            wal start/stop: 000000010000000000000003 / 000000010000000000000004
            database size: 33.8MB, database backup size: 33.8MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB
```

`info` is the repository's account of itself. One **full** backup, labelled by the time it started
and ending in `F`. The database is 33.8 MB on disk and the backup **4.4 MB in the repository**,
compressed with zstd. `wal start/stop` are the segments needed to make it consistent, and `wal
archive min/max` the stretch of archived log the stanza holds.

## Differential

Change a thousand orders, and take a **differential** backup, which copies everything that changed
since the last full:

```
ana@vm:~$ psql shop -c "UPDATE orders SET total_cents = total_cents + 1 WHERE id <= 1000"
UPDATE 1000
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info backup --type=diff
2026-10-10 16:27:35.660 P00   INFO: backup command begin 2.50: --compress-type=zst --exec-id=1023-5b94a0ff --log-level-console=info --pg1-path=/var/lib/postgresql/16/main --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --stanza=main --start-fast --type=diff
2026-10-10 16:27:36.372 P00   INFO: last backup label = 20261010-162731F, version = 2.50
2026-10-10 16:27:36.372 P00   INFO: execute non-exclusive backup start: backup begins after the requested immediate checkpoint completes
2026-10-10 16:27:37.074 P00   INFO: backup start archive = 000000010000000000000006, lsn = 0/6000028
2026-10-10 16:27:37.074 P00   INFO: check archive for prior segment 000000010000000000000005
2026-10-10 16:27:38.544 P00   INFO: execute non-exclusive backup stop and wait for all WAL segments to archive
2026-10-10 16:27:38.744 P00   INFO: backup stop archive = 000000010000000000000006, lsn = 0/6000100
2026-10-10 16:27:38.746 P00   INFO: check archive for segment(s) 000000010000000000000006:000000010000000000000006
2026-10-10 16:27:38.753 P00   INFO: new backup label = 20261010-162731F_20261010-162736D
2026-10-10 16:27:38.780 P00   INFO: diff backup size = 5MB, file total = 1271
2026-10-10 16:27:38.780 P00   INFO: backup command end: completed successfully (3121ms)
2026-10-10 16:27:38.780 P00   INFO: expire command begin 2.50: --exec-id=1023-5b94a0ff --log-level-console=info --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --stanza=main
2026-10-10 16:27:38.782 P00   INFO: expire command end: completed successfully (2ms)
```

This time the log is shown, and it tells the whole story of a backup: an immediate checkpoint, the
start segment, a check that the segment before it is in the archive, the copy, the stop segment, a
wait until every segment the backup needs has arrived, and a label made of the full's label and its
own, ending in `D`. Then `expire` runs, as it does after every backup, and finds nothing to delete.

`diff backup size = 5MB` for a thousand rows changed. **By default pgBackRest decides what changed
file by file**: the table's data file was modified, so all of it was copied, along with its
indexes. Two settings, `repo-bundle` and `repo-block`, make it split files into blocks and copy
only the blocks that changed. They are off by default, and this course leaves them off so that the
arithmetic stays visible.

## Incremental

An **incremental** copies what changed since the last backup of any kind. Add one order, and take
one:

```
ana@vm:~$ psql shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (1, 700, '2026-09-01 11:00-03')"
INSERT 0 1
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main backup --type=incr
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: ok
    cipher: none

    db (current)
        wal archive min/max (16): 000000010000000000000002/000000010000000000000008

        full backup: 20261010-162731F
            timestamp start/stop: 2026-10-10 16:27:31-03 / 2026-10-10 16:27:35-03
            wal start/stop: 000000010000000000000003 / 000000010000000000000004
            database size: 33.8MB, database backup size: 33.8MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB

        diff backup: 20261010-162731F_20261010-162736D
            timestamp start/stop: 2026-10-10 16:27:36-03 / 2026-10-10 16:27:38-03
            wal start/stop: 000000010000000000000006 / 000000010000000000000006
            database size: 33.9MB, database backup size: 5MB
            repo1: backup set size: 4.4MB, backup size: 854.5KB
            backup reference list: 20261010-162731F

        incr backup: 20261010-162731F_20261010-162739I
            timestamp start/stop: 2026-10-10 16:27:39-03 / 2026-10-10 16:27:41-03
            wal start/stop: 000000010000000000000008 / 000000010000000000000008
            database size: 33.9MB, database backup size: 4.5MB
            repo1: backup set size: 4.4MB, backup size: 817.9KB
            backup reference list: 20261010-162731F, 20261010-162731F_20261010-162736D
```

Three backups now, and the bottom of each says what it needs. The differential refers to the full;
the incremental refers to the full **and** the differential. To restore the incremental, pgBackRest
takes the unchanged files from the full, the ones the differential copied from it, and the ones the
incremental copied itself. One order, and still 4.5 MB of files, because it went into the same
3 MB table file the thousand changes had already touched.

## Which to take when

The three trade the time and space a backup takes against what a restore depends on:

| | copies | a restore needs |
|---|---|---|
| **full** | everything | that backup alone |
| **differential** | what changed since the last full | that backup and its full |
| **incremental** | what changed since the last backup of any kind | that backup, its full, and every backup in between |

A common rhythm is **a full weekly, a differential daily**, and incrementals more often if the
database changes a lot. Every backup a restore depends on is one more thing that has to be intact:
a damaged full makes every differential and incremental built on it unusable, which the last
section of this lesson shows. Long chains of incrementals are cheap to take and fragile to rely on.
