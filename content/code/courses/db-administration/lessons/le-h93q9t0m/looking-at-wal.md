---
title: Looking at the log
version: 1
---

The write-ahead log is a single stream of bytes that only ever grows, cut into files of 16 MB so
that old pieces can be thrown away. **A position in that stream is a log sequence number, an LSN**,
and every record, every page and every replica in PostgreSQL is placed by one.

## The files

`pg_wal` belongs to `postgres`, like the rest of the data directory, so listing it needs `sudo`.
The last few entries are enough:

```
ana@db:~$ sudo ls -l /var/lib/postgresql/16/main/pg_wal | tail -n 4
-rw------- 1 postgres postgres 16777216 Oct 10 04:26 000000010000000000000013
-rw------- 1 postgres postgres 16777216 Oct 10 04:26 000000010000000000000014
-rw------- 1 postgres postgres 16777216 Oct 10 04:26 000000010000000000000015
drwx------ 2 postgres postgres     4096 Oct 10 03:18 archive_status
ana@db:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
337M	/var/lib/postgresql/16/main/pg_wal
```

**Every segment is exactly 16777216 bytes**, full or not: a new one is created at its final size
and filled from the front. The name is 24 hexadecimal digits in three groups of eight. The first,
`00000001`, is the **timeline**, which changes only when a server is recovered to an earlier point
or a replica is promoted, both of which belong to db-reliability. The other two together
are the segment's number, counting from the start of the cluster's history, so the names sort in
the order they were written. `archive_status` is a directory, used when segments are copied away
for a backup, and empty here.

## Where the server is now

Two functions answer where the log has reached and which file that is:

```
shop=# SELECT pg_current_wal_lsn(), pg_walfile_name(pg_current_wal_lsn());
 pg_current_wal_lsn |     pg_walfile_name      
--------------------+--------------------------
 0/1584F1C0         | 000000010000000000000015
(1 row)
```

**An LSN is a byte offset written in hexadecimal**, as two halves separated by a slash. `0/1584F1C0`
is about 361 million bytes into the cluster's history, almost all of it the loading of `shop`. With
16 MB segments, the digits before the last six give the segment, `15`, and the last six give the
offset inside it — which is why the file is `…15`. You never do that sum by hand;
`pg_walfile_name` does it, and `pg_wal_lsn_diff`, in the next section, subtracts two positions to
give bytes.

## One INSERT, decoded

The log is binary, and PostgreSQL ships a reader for it, `pg_waldump`. Ubuntu does not put it on
your `PATH`, because the commands that are there are wrappers that choose a version; it lives with
the server's own programs in `/usr/lib/postgresql/16/bin`. Note the position, make one small change,
and note the position again:

```
shop=# SELECT pg_current_wal_lsn();
 pg_current_wal_lsn 
--------------------
 0/1584F1C0
(1 row)

shop=# INSERT INTO notes VALUES (2, 'and this one');
INSERT 0 1

shop=# SELECT pg_current_wal_lsn();
 pg_current_wal_lsn 
--------------------
 0/1584F270
(1 row)
```

Then give the two positions to `pg_waldump` with `-s` (start) and `-e` (end), and point it at the
directory with `-p`. Use the numbers your own `psql` printed:

```
ana@db:~$ sudo /usr/lib/postgresql/16/bin/pg_waldump -p /var/lib/postgresql/16/main/pg_wal -s 0/1584F1C0 -e 0/1584F270
rmgr: Heap        len (rec/tot):     72/    72, tx:        784, lsn: 0/1584F1C0, prev 0/1584F198, desc: INSERT off: 2, flags: 0x00, blkref #0: rel 1663/16386/16420 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:        784, lsn: 0/1584F208, prev 0/1584F1C0, desc: INSERT_LEAF off: 2, blkref #0: rel 1663/16386/16425 blk 1
rmgr: Transaction len (rec/tot):     34/    34, tx:        784, lsn: 0/1584F248, prev 0/1584F208, desc: COMMIT 2026-10-10 04:26:32.265684 -03
```

**One `INSERT` of one row is three records.** Read each line by its fields:

| field | what it says |
| --- | --- |
| `rmgr` | the part of the server that knows how to replay the record: `Heap` for table rows, `Btree` for indexes, `Transaction` for commits |
| `len (rec/tot)` | the record's own size, and its total with anything attached to it; the two are equal here |
| `tx` | the transaction that wrote it: all three belong to transaction 784 |
| `lsn`, `prev` | where the record starts, and where the one before it starts |
| `desc` | what happened: the row went in at slot 2 of the page |
| `blkref` | the page it changed: tablespace, database and file, then the block number |

`rel 1663/16386/16420 blk 0` is block 0 of the file `base/16386/16420`, the `notes` table — the
same path `pg_relation_filepath` gave above, with `1663` for the default tablespace in front. The
second record put the new key into the primary key's index, a different file. The third is the
commit itself, and **that record reaching the disk is what made the transaction durable**. Nothing
in the table file had to change for that to be true.

Notice also what the records do not carry: a copy of the whole page. They describe a change to a
page the server expects to find intact. The next section measures what happens when the server
cannot count on that.
