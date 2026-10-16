---
title: The write-ahead log, seen as files
version: 1
---

Lessons 2 and 3 ended on the same limit: a backup is one moment, and everything written after it is
outside the backup. The way past that limit was already running on your server before you
installed anything. Every change PostgreSQL makes is first written to the **write-ahead log**, a
sequential record of what is about to happen to the data files, and lesson 7 of the administration
course explained why: after a crash, the log is how the server repairs the files. This lesson keeps
that log. A base backup plus every log record written since is the database at any moment you
like.

## Segments

On disk the log is a directory of files of exactly 16 MB each, called **segments**:

```
ana@vm:~$ sudo ls -l /var/lib/postgresql/16/main/pg_wal
total 32772
-rw------- 1 postgres postgres 16777216 Oct 10 04:33 000000010000000000000001
-rw------- 1 postgres postgres 16777216 Oct 10 04:33 000000010000000000000002
drwx------ 2 postgres postgres     4096 Oct 10 04:33 archive_status
shop=# SELECT pg_current_wal_lsn(), pg_walfile_name(pg_current_wal_lsn());
 pg_current_wal_lsn |     pg_walfile_name      
--------------------+--------------------------
 0/212D3E8          | 000000010000000000000002
(1 row)
```

The names are not arbitrary. `000000010000000000000002` is three numbers of eight hexadecimal digits:
the **timeline** (`00000001`, which lesson 6 explains) and then where in the log the segment
sits. Segments are written in order and named in order, and an archive of them sorts the way the
history happened.

A position inside the log is a **log sequence number**, an LSN, written as two hexadecimal numbers
separated by a slash. `0/212D3E8` is a byte position, and `pg_walfile_name` says which segment holds
it. Two LSNs can be subtracted, and the answer is how many bytes of log were written between them,
which is the most honest measure there is of how much a statement changed:

```
shop=# SELECT pg_current_wal_lsn() AS before \gset
shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50000

shop=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before'));
 pg_size_pretty 
----------------
 15 MB
(1 row)
```

`\gset` stored the first answer in a `psql` variable called `before`, and the last query subtracted
it from the new position. **Updating fifty thousand rows wrote 15 MB of log**, nearly a whole
segment, for a table whose data is about 3 MB. Every row updated is a new version of the row,
logged with the index entries pointing at it, and the first change to each 8 kB page after a
checkpoint logs the whole page, so that a crash halfway through writing it can be repaired. Remember that ratio when lesson 8 asks how much
log a day of a real database produces.

## A segment is finished when it is full, or when asked

The server writes into one segment until its 16 MB are used, then moves to the next. A finished
segment is the unit everything in this lesson works on, so it matters that a segment can also be
finished early, on request:

```
shop=# SELECT pg_walfile_name(pg_current_wal_lsn());
     pg_walfile_name      
--------------------------
 000000010000000000000003
(1 row)

shop=# SELECT pg_switch_wal();
 pg_switch_wal 
---------------
 0/302B1C8
(1 row)
```

`pg_switch_wal()` closes the current segment where it is and starts the next one, and answers with
the position where the old one ended. Segment 3 was finished at that moment, about 170 kB into its
16 MB, and the rest of the file is never used. You will use it all through this lesson to make the server hand over a segment now,
rather than when it fills.
