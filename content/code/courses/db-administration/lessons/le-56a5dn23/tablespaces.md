---
title: Tablespaces, and why you will rarely make one
version: 1
---

A **tablespace** is a second place to keep files: a directory outside the data directory that the
server is allowed to put tables and indexes in. Every cluster has two already, `pg_default` (which is
`base/`) and `pg_global` (which is `global/`), and you can add more. The idea is old and sound —
put the busiest table on the fastest disk — and on most modern servers it no longer pays for what it
costs. Making one shows you both halves.

The directory has to exist, be empty, and belong to `postgres` with nobody else allowed in. On your
server it is simply another directory on the same disk, which is enough to see how it works:

```
ana@db:~$ sudo mkdir -p /srv/pg/fast
ana@db:~$ sudo chown postgres:postgres /srv/pg/fast
ana@db:~$ sudo chmod 700 /srv/pg/fast
shop=# CREATE TABLESPACE fast LOCATION '/srv/pg/fast';
CREATE TABLESPACE

shop=# \db
         List of tablespaces
    Name    |  Owner   |   Location   
------------+----------+--------------
 fast       | ana      | /srv/pg/fast
 pg_default | postgres | 
 pg_global  | postgres | 
(3 rows)

shop=# ALTER TABLE customers SET TABLESPACE fast;
ALTER TABLE

shop=# SELECT pg_relation_filepath('customers');
            pg_relation_filepath             
---------------------------------------------
 pg_tblspc/16428/PG_16_202307071/16386/16429
(1 row)
```

**`ALTER TABLE … SET TABLESPACE` copies the whole table** to the new place and holds a lock that
blocks every read and write of it until the copy is done. For 4.5 MB that is nothing; for a table of
200 GB it is an outage, and lesson 22 is about not causing those. Notice also that only the table
moved: its indexes stayed where they were, and each one is moved with its own `ALTER INDEX`.

The new path starts with `pg_tblspc`, and that directory in the cluster is how the server finds its
tablespaces again after a restart:

```
ana@db:~$ sudo ls -l /var/lib/postgresql/16/main/pg_tblspc
total 0
lrwxrwxrwx 1 postgres postgres 12 Oct 10 04:11 16428 -> /srv/pg/fast
ana@db:~$ sudo find /srv/pg/fast -maxdepth 3
/srv/pg/fast
/srv/pg/fast/PG_16_202307071
/srv/pg/fast/PG_16_202307071/16386
/srv/pg/fast/PG_16_202307071/16386/16429
/srv/pg/fast/PG_16_202307071/16386/16431
/srv/pg/fast/PG_16_202307071/16386/16430
/srv/pg/fast/PG_16_202307071/16386/16429_fsm
```

A **symbolic link**, named by the tablespace's oid, pointing at the directory. Inside it the server
made `PG_16_202307071`, a subdirectory named after the major version and the catalogue version, so
two major versions could share one location during an upgrade; then the database's oid, `16386`,
and then the table's files, exactly as under `base/`. Two of the other numbers are the TOAST table
`customers` carries for long values and its index.

## What it costs

A tablespace is part of the cluster and **cannot be backed up, restored or moved on its own**. A
backup tool has to know to follow the link, a restore has to recreate the directory first, and a
cluster whose tablespace disk did not mount at boot starts with tables that are simply missing.
Losing the disk under a tablespace loses those tables, and the rest of the cluster cannot be
trusted afterwards either, because the catalogue still says they exist.

What it buys is less than it used to be. On a server with one fast disk, or on cloud storage where
every volume is the same network-attached kind, there is no faster place to put anything. The cases
left are real but narrow: a table too big for the main disk while a larger one is being arranged, or
temporary files for big sorts (`temp_tablespaces`) on a scratch disk nobody needs to back up.

**Put it back before going on**, so your `shop` matches the course again:

```
shop=# ALTER TABLE customers SET TABLESPACE pg_default;
ALTER TABLE

shop=# DROP TABLESPACE fast;
DROP TABLESPACE
```

A tablespace with anything still in it cannot be dropped, which is why the table had to move first.
`/srv/pg/fast` is left empty; `sudo rmdir /srv/pg/fast /srv/pg` removes it.
