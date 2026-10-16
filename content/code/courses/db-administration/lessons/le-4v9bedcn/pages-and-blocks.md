---
title: Pages over blocks
version: 1
---

A table is not stored as rows laid end to end. **PostgreSQL reads and writes its files in pages
of 8192 bytes**, every table and every index is a whole number of them, and a row lives inside
one page. The size is fixed when PostgreSQL is compiled, and both the data files and the
write-ahead log use it:

```
shop=# SHOW block_size;
 block_size 
------------
 8192
(1 row)

shop=# SHOW wal_block_size;
 wal_block_size 
----------------
 8192
(1 row)

shop=# SELECT relpages, pg_relation_size('customers') AS bytes,
shop-#        pg_relation_size('customers') / relpages AS bytes_per_page
shop-#   FROM pg_class WHERE relname = 'customers';
 relpages |  bytes  | bytes_per_page 
----------+---------+----------------
      568 | 4653056 |           8192
(1 row)
```

`relpages` is the page count `ANALYZE` recorded when lesson 4 loaded the table, and the file is
exactly that many pages long. PostgreSQL calls the setting `block_size`, which is a source of
confusion, because **the filesystem under it has blocks of its own, and they are smaller**:

```
ana@db:~$ stat --file-system --format="%T, block size %S" /var/lib/postgresql/16/main
ext2/ext3, block size 4096
```

`stat` names the ext family by its oldest members; the filesystem is ext4, as the next section
shows. Its block is 4096 bytes, and under it the disk has its own unit again, the sector, of 512
bytes on many disks and 4096 on newer ones.

## Why the mismatch matters

When PostgreSQL writes a page, the kernel turns one 8 kB write into two 4 kB block writes, and
the disk turns those into sector writes. **Nothing guarantees they all land, or that they land
together.** If the power goes between the first block and the second, the file holds a page whose
first half is new and whose second half is old. That is a **torn page**, and no row in it can be
trusted.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 690 200\" role=\"img\" aria-label=\"An 8192-byte PostgreSQL page sits on two 4096-byte filesystem blocks, which sit on sixteen 512-byte disk sectors. A dashed line through the middle marks a power failure after the first block was written: the first half of the page is new, the second half is still old.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL page</text><rect x=\"150\" y=\"24\" width=\"520\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one page: 8192 bytes, written as a unit by PostgreSQL</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">filesystem block</text><rect x=\"150\" y=\"76\" width=\"256.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">4096 bytes: new</text><rect x=\"414.0\" y=\"76\" width=\"256.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">4096 bytes: still old</text><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">disk sectors</text><rect x=\"151.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"183.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"216.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"248.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"281.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"313.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"346.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"378.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"411.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"443.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"476.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"508.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"541.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"573.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"606.0\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"638.5\" y=\"130\" width=\"30.5\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"166.25\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">512</text><line x1=\"410.0\" y1=\"18\" x2=\"410.0\" y2=\"166\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></line><text x=\"410.0\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">power lost here: the page is half new and half old, a torn page</text></svg>", "caption": "A page is the unit PostgreSQL writes, and it is two of the units the filesystem writes. Nothing makes the two blocks land together."}
```

PostgreSQL cannot stop this from happening, so it arranges to repair it. The first time a page is
changed after a checkpoint, the whole page goes into the write-ahead log, and crash recovery
writes that copy back over whatever half-written page it finds. That is `full_page_writes`,
which lesson 8 measured and which is the reason it stays on. A filesystem that never tears a
write, such as ZFS with its copy-on-write design, is the one case where it is safe to switch off, and even then
only with that filesystem's own documentation open.

## The setting you do not change

`block_size` can only be changed by compiling PostgreSQL yourself and creating a new cluster with
the result. A different page size makes every data file incompatible with every normal build, so
no packaged server, managed service or extension author expects it. **Treat 8192 as a fact about
PostgreSQL rather than a parameter.** What you choose is the disk and the filesystem it sits on,
which is the rest of this lesson.
