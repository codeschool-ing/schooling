---
title: Four formats, and the one to use
version: 1
---

`pg_dump` writes four kinds of file, chosen with `-F`. Make one of each from the same database:

```
ana@vm:~$ pg_dump -Fp -f shop-plain.sql shop
ana@vm:~$ pg_dump -Fc -f shop.dump shop
ana@vm:~$ pg_dump -Fd -f shop.dir shop
ana@vm:~$ pg_dump -Ft -f shop.tar shop
ana@vm:~$ ls -l shop-plain.sql shop.dump shop.tar shop.dir
-rw-r--r-- 1 ana ana 1937458 Oct 10 04:06 shop-plain.sql
-rw-r--r-- 1 ana ana  539121 Oct 10 04:06 shop.dump
-rw-r--r-- 1 ana ana 1946112 Oct 10 04:06 shop.tar

shop.dir:
total 532
-rw-r--r-- 1 ana ana   4880 Oct 10 04:06 3401.dat.gz
-rw-r--r-- 1 ana ana 529447 Oct 10 04:06 3403.dat.gz
-rw-r--r-- 1 ana ana   4088 Oct 10 04:06 toc.dat
```

| | flag | what it is | restored with |
|---|---|---|---|
| **plain** | `-Fp` | a SQL script, readable in any editor | `psql -f` |
| **custom** | `-Fc` | one compressed archive, with a table of contents | `pg_restore` |
| **directory** | `-Fd` | a directory: one compressed file per table, plus the contents | `pg_restore` |
| **tar** | `-Ft` | the directory format packed in a tar file, uncompressed | `pg_restore` |

The plain file is 1.9 MB and the custom one 0.5 MB, because custom compresses by default. The
directory shows where the space goes: one file per table's data, named after its entry number, and
the orders are nearly all of it.

**Plain SQL is the one people reach for and the weakest.** It is restored by running it, top to
bottom, all or nothing: to get one table back you edit the file, and if it is 40 GB you are editing
40 GB. It cannot be restored in parallel. Its one virtue is that a person can read it.

**Custom is the default worth having.** It is compressed, and it carries a table of contents that
`pg_restore` can list, filter and reorder:

```
ana@vm:~$ pg_restore -l shop.dump
;
; Archive created at 2026-10-10 04:06:18 -03
;     dbname: shop
;     TOC Entries: 16
;     Compression: gzip
;     Dump Version: 1.15-0
;     Format: CUSTOM
;     Integer: 4 bytes
;     Offset: 8 bytes
;     Dumped from database version: 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
;     Dumped by pg_dump version: 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
;
;
; Selected TOC Entries:
;
215; 1259 16386 TABLE public customers shop_owner
3410; 0 0 ACL public TABLE customers shop_owner
217; 1259 16394 TABLE public orders shop_owner
3411; 0 0 ACL public TABLE orders shop_owner
216; 1259 16393 SEQUENCE public orders_id_seq shop_owner
3401; 0 16386 TABLE DATA public customers shop_owner
3403; 0 16394 TABLE DATA public orders shop_owner
3412; 0 0 SEQUENCE SET public orders_id_seq shop_owner
3253; 2606 16392 CONSTRAINT public customers customers_pkey shop_owner
3256; 2606 16399 CONSTRAINT public orders orders_pkey shop_owner
3254; 1259 16405 INDEX public orders_customer shop_owner
3257; 2606 16400 FK CONSTRAINT public orders orders_customer_id_fkey shop_owner
```

Each line is one thing the restore will do, with its kind (`TABLE`, `TABLE DATA`, `INDEX`,
`FK CONSTRAINT`, `ACL` for the grants) and its owner. Save this list to a file, delete or comment
out lines, and `pg_restore -L file` restores exactly what is left. The selective restore two
sections on is built on that.

**Directory is custom split across files**, and it is the only format `pg_dump` can write in
parallel, with `-j`. It is the one to use for a large database. **Tar** exists for tools that want a
single file; nothing in this course needs it.

So: custom for everyday copies, directory once the database is large enough that a dump's
duration matters, and plain only when somebody has to read the result.
