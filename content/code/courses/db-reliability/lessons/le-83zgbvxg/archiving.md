---
title: Archiving: a copy of every segment, as it is finished
version: 1
---

Left alone, the server recycles old segments: once a checkpoint has made them unnecessary for its
own crash recovery, their files are renamed and overwritten. **Continuous archiving** asks the
server to hand each finished segment to a command first, and not to recycle it until that command
has succeeded. The command copies it somewhere safe, and the collection of copies is the
**archive**.

Two settings turn it on. `archive_mode` makes the server keep track of which segments have been
archived; `archive_command` is a shell command the server runs once per finished segment, with `%p`
replaced by the segment's path and `%f` by its file name.

The archive needs a home the server's user can write to. In this lab it is a directory on the same
machine, which is the wrong place for a real archive and the right place to learn the mechanism;
lesson 9 moves it.

```
ana@vm:~$ sudo -u postgres mkdir /var/lib/postgresql/wal-archive
ana@vm:~$ sudo -u postgres chmod 700 /var/lib/postgresql/wal-archive
```

Now the settings. `ALTER SYSTEM` writes them to `postgresql.auto.conf` in the data directory, a file
the server reads after its main configuration, and `archive_mode` only takes effect on a restart:

```
shop=# ALTER SYSTEM SET archive_mode = on;
ALTER SYSTEM

shop=# ALTER SYSTEM SET archive_command = 'test ! -f /var/lib/postgresql/wal-archive/%f && cp %p /var/lib/postgresql/wal-archive/%f';
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main restart
shop=# SHOW archive_mode;
 archive_mode 
--------------
 on
(1 row)

shop=# SELECT archived_count, last_archived_wal, failed_count FROM pg_stat_archiver;
 archived_count | last_archived_wal | failed_count 
----------------+-------------------+--------------
              0 |                   |            0
(1 row)
```

Read the command before trusting it. `test ! -f …/%f` succeeds only if no file of that name is in
the archive yet, and `&&` runs the copy only if it did. That guard is not decoration: **an
archive_command must never overwrite a segment that is already archived**, because a second server
misconfigured to archive into the same place would otherwise replace your history with its own,
silently. With the guard, the copy fails, the failure is counted, and somebody notices.

`pg_stat_archiver` is the server's own account of how archiving is going, and right after the
restart it has nothing to report. Give it a segment:

```
shop=# SELECT pg_switch_wal();
 pg_switch_wal 
---------------
 0/40000B8
(1 row)
shop=# SELECT archived_count, last_archived_wal, last_archived_time, failed_count FROM pg_stat_archiver;
 archived_count |    last_archived_wal     |      last_archived_time       | failed_count 
----------------+--------------------------+-------------------------------+--------------
              1 | 000000010000000000000004 | 2026-10-10 04:34:04.840024-03 |            0
(1 row)
ana@vm:~$ sudo ls -l /var/lib/postgresql/wal-archive
total 16384
-rw------- 1 postgres postgres 16777216 Oct 10 04:34 000000010000000000000004
```

**`archived_count` 1, `failed_count` 0**, and the segment is in the archive with its full 16 MB.
Those two numbers, and the time beside the last archived segment, are the three things to watch on
every server that archives. The next section breaks the command and shows why.

`cp` is the simplest command that works, and it is not a good one for production: it does not make
sure the copy reached the disk before reporting success, and a power cut a moment later can leave a
segment the server believes is safe and the disk never kept. Lesson 5's tool replaces it with one
that does. The mechanism, the guard against overwriting and the statistics stay the same.
