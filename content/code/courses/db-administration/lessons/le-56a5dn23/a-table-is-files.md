---
title: A table is a few files with numbers for names
version: 1
---

Nothing under `base/` is called `shop` or `orders`. Every database and every table has an **oid**,
an object identifier the server assigns, and the files are named by numbers derived from it. The
catalogue says which number is which:

```
shop=# SELECT oid, datname FROM pg_database ORDER BY oid;
  oid  |  datname  
-------+-----------
     1 | template1
     4 | template0
     5 | postgres
 16385 | ana
 16386 | shop
(5 rows)

shop=# SELECT pg_relation_filepath('orders');
 pg_relation_filepath 
----------------------
 base/16386/16398
(1 row)

shop=# SELECT pg_relation_filepath('orders_created_at');
 pg_relation_filepath 
----------------------
 base/16386/16411
(1 row)
```

`shop` is database 16386, so it lives in `base/16386`. The `orders` table is the file `16398` in it,
and its index on `created_at` is a different file, `16411`: **an index is a relation of its own**,
with its own file, and nothing about its name ties it to the table on disk. The three small oids at
the top are the databases every cluster is born with; `template1` is copied each time somebody runs
`createdb`.

Your numbers may differ from these if you created anything before `shop`. That is why
`pg_relation_filepath` exists: never work a file name out by hand.

## One table, three forks

```
ana@db:~$ sudo find /var/lib/postgresql/16/main/base/16386 -name '16398*' -printf '%-10s %f\n'
68272128   16398
40960      16398_fsm
```

`16398` holds the rows, in 68,272,128 bytes. `16398_fsm` is the **free space map**: for every page of
the table, roughly how much room is left in it, so an `INSERT` can find a page with space without
reading the table. PostgreSQL calls these files **forks** of one relation. There is a third, and it
appears after the first `VACUUM`:

```
shop=# VACUUM orders;
VACUUM
ana@db:~$ sudo find /var/lib/postgresql/16/main/base/16386 -name '16398*' -printf '%-10s %f\n'
8192       16398_vm
68272128   16398
40960      16398_fsm
```

`16398_vm` is the **visibility map**: two bits per page, saying whether every row on that page is
visible to every transaction, and whether every row on it is frozen. It is 8192 bytes for a table of
65 MB. Lesson 14 is about why `VACUUM` keeps it and what reads it.

## Pages, segments and the sizes psql reports

```
shop=# SELECT pg_size_pretty(pg_relation_size('orders')) AS main_fork,
shop-#        pg_size_pretty(pg_table_size('orders')) AS table_size,
shop-#        pg_size_pretty(pg_indexes_size('orders')) AS indexes,
shop-#        pg_size_pretty(pg_total_relation_size('orders')) AS total;
 main_fork | table_size | indexes | total  
-----------+------------+---------+--------
 65 MB     | 65 MB      | 42 MB   | 108 MB
(1 row)

shop=# SHOW block_size;
 block_size 
------------
 8192
(1 row)

shop=# SHOW segment_size;
 segment_size 
--------------
 1GB
(1 row)
```

Four functions, four answers, and the difference between them is the difference between the forks:
`pg_relation_size` is the main fork alone, `pg_table_size` adds the free space and visibility maps
(and any TOAST storage for long values), `pg_indexes_size` is every index, and
`pg_total_relation_size` is all of it — **108 MB for a table `\dt+` calls 65 MB**. When somebody asks
how big a table is, the honest answer names which of the four.

Every file is a sequence of **pages** of `block_size` bytes, 8192 here and on almost every
PostgreSQL there is; 68,272,128 bytes is exactly 8,334 pages. A file never grows past
`segment_size`, one gigabyte: a table of 5 GB is five files, `16398`, `16398.1` up to `16398.4`.
Both numbers are fixed when PostgreSQL is compiled, and lesson 9 is about how they meet the disk
underneath.

## The number can change

```
shop=# CREATE TABLE scratch AS SELECT * FROM orders WHERE id <= 1000;
SELECT 1000
```

`TRUNCATE` did not empty the file; it gave the table a **new, empty file** and threw the old one
away, which is why it is instant on a table of any size. `VACUUM FULL`, `CLUSTER` and some kinds of
`ALTER TABLE` do the same. The oid of the table stays; the number on disk, its **relfilenode**,
does not. One more reason a file name is something you look up rather than remember.
