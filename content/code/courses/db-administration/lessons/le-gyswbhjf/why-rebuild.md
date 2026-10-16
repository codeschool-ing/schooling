---
title: Why an index is ever rebuilt
version: 1
---

An index looks like part of the table, and it is easy to think of it as something that is either
there or not. **It is a second copy of some of the table's data, sorted, kept in its own files**,
and a copy can drift from what it copies. `REINDEX` throws the copy away and builds it again from
the table. There are three reasons to want that, and they are very different in how urgent they
are.

**Bloat.** Lesson 15 measured it with `pgstatindex`: after many updates and deletes an index can be
mostly empty pages, and a rebuild packs it tight again. It is the common reason and the least
urgent, because a bloated index still gives right answers.

**Corruption.** A failing disk, a controller that lied about a write, a kernel or PostgreSQL bug.
The index no longer matches the table, and a query that uses it can return rows that do not
satisfy it or miss rows that do. The amcheck section of this lesson shows how to look for it.

**A change in the rules the index was sorted by.** This one is the least obvious, it happens
during routine maintenance of the operating system, and it gives wrong answers with nothing in
the log.

## The order of text belongs to the operating system

An index on a text column keeps its entries in the order the column's **collation** says. With
the libc provider, the default one, that order comes from the C library of the machine, glibc on
Ubuntu, and different collations order the same strings differently:

```
ana@db:~$ ldd --version | head -1
ldd (Ubuntu GLIBC 2.39-0ubuntu8) 2.39
ana@db:~$ printf 'B\na\n11\n1-1\n' | LC_COLLATE=C sort
1-1
11
B
a
ana@db:~$ printf 'B\na\n11\n1-1\n' | LC_COLLATE=en_US.UTF-8 sort
1-1
11
a
B
```

`C` compares bytes, so `B` comes before `a`. `en_US.UTF-8` follows a language's rules, and `a`
comes first. Both are right, by their own rules. The trouble is that **the rules of one collation
have changed between versions of glibc**, and the big change came in glibc 2.28: on 2.27 and
earlier, `en_US.UTF-8` put `11` before `1-1`, and from 2.28 on it puts `1-1` first, as above. That
older result is quoted from the PostgreSQL wiki's page on locale data changes and was not run
here; this machine has glibc 2.39. Ubuntu 18.04 shipped 2.27 and 20.04 shipped 2.31, so an upgrade
between the two crossed the line.

An index built under the old rules has its entries in the old order. After the upgrade,
PostgreSQL searches it with the new ones. The search walks down the tree comparing keys, takes a
wrong turn wherever the two orders disagree, and **finds nothing where the row is sitting in the
index all along**. A unique index stops seeing the duplicate it is there to refuse. Nothing
errors.

## PostgreSQL records the version, and warns

Since PostgreSQL 15, each database records the version of the collation library it was created
with, and compares it at every connection.

```
shop=# SELECT datname, datcollate, datcollversion FROM pg_database WHERE datname = 'shop';
 datname | datcollate | datcollversion 
---------+------------+----------------
 shop    | C.UTF-8    | 
(1 row)

shop=# CREATE DATABASE coll_check TEMPLATE template0 LOCALE 'en_US.UTF-8';
CREATE DATABASE

shop=# SELECT datname, datcollate, datcollversion FROM pg_database WHERE datname = 'coll_check';
  datname   | datcollate  | datcollversion 
------------+-------------+----------------
 coll_check | en_US.UTF-8 | 2.39
(1 row)
```

The recording machine's cluster was created under `C.UTF-8`, which compares code points and has
no version to record, so `datcollversion` is empty for `shop`. A server installed from Ubuntu's
installer in English usually has `en_US.UTF-8`, and yours may well show a version beside `shop`.
The throwaway database `coll_check` is made with `en_US.UTF-8` to have one: glibc 2.39.

This machine has only one glibc, so to see the warning the next step **cheats**: it edits the
recorded version by hand, to the one an Ubuntu 18.04 server would have written. Never do this to
a database anybody keeps; on `coll_check`, which is dropped two lines later, it shows exactly what
the server says after a real upgrade:

```
shop=# UPDATE pg_database SET datcollversion = '2.27' WHERE datname = 'coll_check';
UPDATE 1

shop=# \c coll_check
WARNING:  database "coll_check" has a collation version mismatch
DETAIL:  The database was created using collation version 2.27, but the operating system provides version 2.39.
HINT:  Rebuild all objects in this database that use the default collation and run ALTER DATABASE coll_check REFRESH COLLATION VERSION, or build PostgreSQL with the right library version.
You are now connected to database "coll_check" as user "ana".

coll_check=# REINDEX DATABASE coll_check;
REINDEX

coll_check=# ALTER DATABASE coll_check REFRESH COLLATION VERSION;
NOTICE:  changing version from 2.27 to 2.39
ALTER DATABASE

coll_check=# \c shop
You are now connected to database "shop" as user "ana".

shop=# DROP DATABASE coll_check;
DROP DATABASE
```

The `WARNING` names the problem and the `HINT` names the cure, in that order: **rebuild what uses
the collation, then tell the database the new version is the one it now has**. `REINDEX DATABASE`
rebuilds every index in it, which on an empty database is instant and on a large one is the
long part. Refreshing the version first would only silence the warning and leave the indexes as
they were.

Two things follow for an administrator. Before moving a server to a new release of its operating
system, check whether glibc crosses a change, and plan the reindex as part of the move. And know
which upgrade paths carry the old index files across: `pg_upgrade` and a physical replica on the
new system both do, while a dump and restore or logical replication build every index again on
the new machine. Lesson 20 performs the upgrades; this is the question to ask before choosing one.
