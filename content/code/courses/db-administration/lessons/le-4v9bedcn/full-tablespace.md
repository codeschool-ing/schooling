---
title: A full tablespace
version: 1
---

Lesson 4 made a tablespace on the same disk as everything else. This one gets a filesystem of
64 MB, made the same way as the log's, so it can be filled in a second:

```
ana@db:~$ sudo truncate -s 64M /srv/small.img
ana@db:~$ sudo mkfs.ext4 -q /srv/small.img
ana@db:~$ sudo mkdir /srv/small
ana@db:~$ sudo mount -o loop /srv/small.img /srv/small
ana@db:~$ df -h /srv/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop1       56M   24K   52M   1% /srv/small
ana@db:~$ sudo tune2fs -l /srv/small.img | grep -E "^(Block count|Reserved block count|Block size)"
Block count:              16384
Reserved block count:     819
Block size:               4096
```

**`df` says 56 MB in size and 52 MB available, with nothing used.** The missing four are mostly
the reserve that `tune2fs` shows: 819 blocks of 4096 bytes, five per cent of the filesystem,
which ext4 keeps for the root user so that a full disk still leaves an administrator room to
work. PostgreSQL runs as `postgres`, not as root, so for the database this filesystem is full at
52 MB. Remember the reserve; it is about to matter.

Give `postgres` a directory on it, make the tablespace, and put a table there:

```
ana@db:~$ sudo install -d -o postgres -g postgres -m 700 /srv/small/pg
```

```
shop=# CREATE TABLESPACE small LOCATION '/srv/small/pg';
CREATE TABLESPACE

shop=# CREATE TABLE filler (id bigint, pad text) TABLESPACE small;
CREATE TABLE

shop=# INSERT INTO filler SELECT i, repeat('x', 500) FROM generate_series(1, 200000) AS i;
ERROR:  could not extend file "pg_tblspc/16424/PG_16_202307071/16386/16425": No space left on device
HINT:  Check free disk space.

shop=# SELECT count(*) FROM filler;
 count 
-------
     0
(1 row)

shop=# SELECT pg_size_pretty(pg_relation_size('filler'));
 pg_size_pretty 
----------------
 51 MB
(1 row)

shop=# SELECT count(*) FROM orders;
  count  
---------
 1000000
(1 row)
```

`install -d` made the directory with its owner and mode in one command. The insert wanted about
100 MB and the filesystem had 52.

## What the error tells you

**`could not extend file` is an `ERROR`, the severity that ends one statement.** The insert was
rolled back, the table has no rows, and the server carried on: the next query read a million
orders from the other disk without noticing anything. The path is the table's file, relative to
the data directory, and `pg_tblspc/16424` is the tablespace's link, as lesson 4 showed, which is how you
know which filesystem to look at. The log has the same lines, with the statement that caused them:

```
ana@db:~$ df -h /srv/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop1       56M   52M     0 100% /srv/small
ana@db:~$ sudo tail -n 3 /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:41:15.038 -03 [498] ana@shop ERROR:  could not extend file "pg_tblspc/16424/PG_16_202307071/16386/16425": No space left on device
2026-10-10 16:41:15.038 -03 [498] ana@shop HINT:  Check free disk space.
2026-10-10 16:41:15.038 -03 [498] ana@shop STATEMENT:  INSERT INTO filler SELECT i, repeat('x', 500) FROM generate_series(1, 200000) AS i;
```

**The rollback gave nothing back.** The table holds no rows and its file is still 51 MB, because a
rolled-back insert leaves its rows behind as dead tuples in pages that now exist; lesson 14 is
about what removes them. The filesystem stays full, and the next statement that needs a page on it
fails the same way.

## Getting out

`VACUUM` is what removes dead rows, and when a table's last pages are empty it hands them back to
the filesystem. So it should fix this:

```
shop=# VACUUM filler;
ERROR:  could not extend file "pg_tblspc/16424/PG_16_202307071/16386/16425_vm": No space left on device
HINT:  Check free disk space.
CONTEXT:  while scanning block 0 of relation "public.filler"
```

**The tool that frees the space needs a little space to run.** The `_vm` file is the table's
visibility map, a small companion file `VACUUM` creates as it goes, and there was not one free
block to create it in. This is the usual shape of a full-disk emergency: every way out writes
something first.

This is what ext4's reserve is for. `tune2fs -m 0` hands the five per cent to everybody, on the
mounted device, which `findmnt` names:

```
ana@db:~$ sudo tune2fs -m 0 "$(findmnt --noheadings --output SOURCE /srv/small)"
tune2fs 1.47.0 (5-Feb-2023)
Setting reserved blocks percentage to 0% (0 blocks)
ana@db:~$ df -h /srv/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop1       56M   52M  3.2M  95% /srv/small
```

```
shop=# VACUUM filler;
VACUUM

shop=# SELECT pg_size_pretty(pg_relation_size('filler'));
 pg_size_pretty 
----------------
 0 bytes
(1 row)
```

```
ana@db:~$ df -h /srv/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop1       56M   60K   52M   1% /srv/small
ana@db:~$ sudo tune2fs -m 5 "$(findmnt --noheadings --output SOURCE /srv/small)"
tune2fs 1.47.0 (5-Feb-2023)
Setting reserved blocks percentage to 5% (819 blocks)
```

With 3.2 MB to work in, `VACUUM` found every page empty and cut the file to nothing. **Then the
reserve goes back**, because it is only worth anything while it is unused.

That worked because the dead rows were all there was. On a real server the full filesystem holds
rows somebody needs, and the ways out are the ones that do not depend on luck:

- **give the filesystem more room**, which the next section does to the log's;
- **move a table to a tablespace that has room**, with `ALTER TABLE ... SET TABLESPACE`, which
  copies it and locks it against every query while it does;
- **remove what can be removed**: `TRUNCATE` or `DROP TABLE` on something disposable frees its
  space the moment the transaction commits, where `DELETE` frees none.

**Never delete files under the data directory or a tablespace by hand.** The numbered files belong
to tables, and a missing one is a table that errors on every read from then on.
