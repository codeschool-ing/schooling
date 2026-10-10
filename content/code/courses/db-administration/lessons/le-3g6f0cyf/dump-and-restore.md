---
title: Dump and restore
version: 1
---

The oldest way across is also the simplest: write the database out as SQL with the old server
running, and load it into the new one. Nothing about the old cluster's files matters, so it works
between any two versions, between two machines, and between two operating systems. Its cost is
**time proportional to the data**, and downtime to match: anything written after the dump began is
not in it, so the application stops writing when the dump starts and starts again on the new server
when the restore ends.

This section copies `shop` from `main`, which is still 16, into the empty `17/main` that the package
created. Reading from `main` is all it does there.

## The newer pg_dump

**Dump with the new version's `pg_dump`, not the old one's.** A newer `pg_dump` reads older servers
and knows what the new version needs; the reverse is not promised. The wrapper does not choose it for
you, because without `-p` it picks the version of the cluster on 5432:

```
ana@db:~$ pg_dump --version
pg_dump (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@db:~$ /usr/lib/postgresql/17/bin/pg_dump --version
pg_dump (PostgreSQL) 17.10
```

So give the full path. `-Fc` writes the **custom format**: compressed, and readable only by
`pg_restore`, which in exchange can restore in parallel and pick out single tables:

```
ana@db:~$ time /usr/lib/postgresql/17/bin/pg_dump -Fc -f shop.dump shop

real	0m3.882s
user	0m1.714s
sys	0m0.081s
ana@db:~$ ls -lh shop.dump
-rw-rw-r-- 1 ana ana 14M Oct 10 16:41 shop.dump
```

The `orders` table and its indexes alone take 107 MB on `main`, and the whole dump is 14 MB. The rows
compress well, and the indexes are not in it at all:
a dump carries the `CREATE INDEX` statement and the restore builds the index again.

## Roles first

`pg_dump` copies one database, and **roles belong to the cluster, not to a database**, so a dump of
`shop` does not contain `ana`. `pg_dumpall --globals-only` writes the roles and tablespaces alone:

```
ana@db:~$ sudo -u postgres /usr/lib/postgresql/17/bin/pg_dumpall --globals-only | sudo -u postgres psql -q -p 5434
ERROR:  role "postgres" already exists
```

The same expected error as in the rehearsal: `postgres` exists already.

## The restore

```
ana@db:~$ createdb -p 5434 shop
ana@db:~$ time pg_restore -p 5434 -d shop -j 4 shop.dump

real	0m4.543s
user	0m0.202s
sys	0m0.046s
```

`-j 4` runs four jobs at once, loading tables and building indexes side by side; it works only with
the custom and directory formats, which is another reason to use `-Fc`. On a real database the
restore is the long half, and the index builds are most of it, so the number of jobs is worth
rehearsing: up to the number of processors the server has.

```
ana@db:~$ psql -p 5434 shop
psql (17.10)
Type "help" for help.

shop=# SELECT count(*) FROM orders;
  count  
---------
 1000000
(1 row)

shop=# SELECT pg_size_pretty(pg_table_size('orders')) AS orders, pg_size_pretty(pg_indexes_size('orders')) AS its_indexes;
 orders | its_indexes 
--------+-------------
 66 MB  | 37 MB
(1 row)

shop=# \q
ana@db:~$ psql -c "SELECT pg_size_pretty(pg_table_size('orders')) AS orders, pg_size_pretty(pg_indexes_size('orders')) AS its_indexes;" shop
 orders | its_indexes 
--------+-------------
 65 MB  | 42 MB
(1 row)
```

The million rows arrived. The table is the same size within a megabyte, and **the indexes are
smaller**, 37 MB against 42 MB on `main`. `shop.sql` created its indexes before it loaded the rows,
so each one grew page split by page split as rows arrived; the restore built every index in one pass
over finished data, packed tight. A database that has lived for years carries more than that — the
dead space updates and deletes leave behind, which lesson 15 measured — and none of it survives a
dump. That is one reason people choose this method when they could have used `pg_upgrade`.

## When dump and restore is the right choice

- The database is small enough that the downtime is acceptable — tens of gigabytes rather than
  terabytes, depending on the hardware and on how long the business can stop writing.
- Something else changes at the same time: a new machine, another processor architecture, a
  different encoding or locale for the cluster. `pg_upgrade` needs both clusters on one machine with
  compatible settings; a dump does not care.
- The old server must stay exactly as it was, readable, as the way back.

`pg_upgradecluster` without `-m upgrade` runs this same method for every database of the cluster,
roles included, with the new version's tools. **It is the convenient form of dump and restore on
Ubuntu** when the cluster stays on the same machine.
