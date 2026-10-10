---
title: The base backup: a copy the server takes part in
version: 1
---

`pg_basebackup` copies a running server properly. It connects to the server over the replication
protocol, tells it a backup is starting, receives every file, and receives **the write-ahead log
written while the copy ran**, so that the copy can be repaired into one consistent moment. Make
one into a directory called `base`:

```
ana@vm:~$ pg_basebackup -D base -X stream -c fast -v
pg_basebackup: initiating base backup, waiting for checkpoint to complete
pg_basebackup: checkpoint completed
pg_basebackup: write-ahead log start point: 0/2C000028 on timeline 1
pg_basebackup: starting background WAL receiver
pg_basebackup: created temporary replication slot "pg_basebackup_4189"
pg_basebackup: write-ahead log end point: 0/2C000100
pg_basebackup: waiting for background process to finish streaming ...
pg_basebackup: syncing data to disk ...
pg_basebackup: renaming backup_manifest.tmp to backup_manifest
pg_basebackup: base backup completed
ana@vm:~$ ls base
PG_VERSION
backup_label
backup_manifest
base
global
pg_commit_ts
pg_dynshmem
pg_logical
pg_multixact
pg_notify
pg_replslot
pg_serial
pg_snapshots
pg_stat
pg_stat_tmp
pg_subtrans
pg_tblspc
pg_twophase
pg_wal
pg_xact
postgresql.auto.conf
```

Each line is one step of the conversation:

1. **A checkpoint.** The server writes every changed page to disk, so recovery of the copy can
   start from a known point. `-c fast` asks for it at once; without it, the server takes its time
   and the backup waits. On a busy server the fast one causes a burst of writes, which is why it is
   not the default.
2. **The start point**, `0/2C000028`, a position in the write-ahead log. Everything the copy might
   be missing was written after it.
3. **A WAL receiver in the background**, through a temporary replication slot. `-X stream` makes
   the backup collect the log over a second connection while the files are copied, and the slot
   stops the server recycling any of it before it has arrived.
4. **The end point**, `0/2C000100`. A copy repaired with the log from the start point to the end
   point is consistent; a copy repaired with less is not.
5. **The manifest**, a list of every file with its size and checksum, used by the section after
   this one.

The result looks like a data directory, because it is one. Two files make it a backup rather than a
server's own directory: `backup_manifest`, and this one:

```
ana@vm:~$ cat base/backup_label
START WAL LOCATION: 0/2C000028 (file 00000001000000000000002C)
CHECKPOINT LOCATION: 0/2C000060
BACKUP METHOD: streamed
BACKUP FROM: primary
START TIME: 2026-10-10 04:14:52 -03
LABEL: pg_basebackup base backup
START TIMELINE: 1
```

`backup_label` is the note the copy carries for whoever starts it. Its first line says **where
recovery must start**, and the WAL segment that position lives in. A server that finds this file in
its data directory knows it is a backup and replays the log from that point, instead of trusting
whatever its control file says, which is the thing the `cp` of the previous section could not do.
The `START TIME` is the moment the copy began, and `-X stream` put the log needed to reach
consistency inside `base/pg_wal`, so this directory is a complete backup on its own.

Lesson 4 drops `-X stream` and keeps the log somewhere else, continuously, which is what turns a
base backup from one moment into any moment. Until then, a base backup with its own log is the
physical equivalent of lesson 2's dump: one consistent instant, restorable on its own.
