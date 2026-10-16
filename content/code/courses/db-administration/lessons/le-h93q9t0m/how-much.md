---
title: How much log a change costs
version: 1
---

The size of a change in the log is not the size of the change in the table. **Sometimes it is
tiny, and sometimes one changed byte costs a whole page**, and which one you get depends on when
the page was last part of a checkpoint. `pg_wal_lsn_diff` measures it: take the position before,
make the change, and subtract.

## One row, twice

Ask for a checkpoint first, so both updates start from the same place, then change one order's
status and change it back:

```
shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT pg_current_wal_lsn() AS before \gset
shop=# UPDATE orders SET status = 'shipped' WHERE id = 1000000;
UPDATE 1

shop=# SELECT :'before' AS before, pg_current_wal_lsn() AS after,
shop-#        pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') AS bytes;
   before   |   after    | bytes 
------------+------------+-------
 0/1584F320 | 0/158516F8 |  9176
(1 row)

shop=# SELECT pg_current_wal_lsn() AS before \gset
shop=# UPDATE orders SET status = 'paid' WHERE id = 1000000;
UPDATE 1

shop=# SELECT :'before' AS before, pg_current_wal_lsn() AS after,
shop-#        pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') AS bytes;
   before   |   after    | bytes 
------------+------------+-------
 0/158516F8 | 0/15851770 |   120
(1 row)
```

`\gset` is a `psql` command that stores the columns of the last result in variables named after
them, and `:'before'` reads the variable back as a quoted value. The same change, made twice in a
row, wrote **9176 bytes the first time and 120 the second**. `pg_waldump` over the whole range
says where the difference went:

```
ana@db:~$ sudo /usr/lib/postgresql/16/bin/pg_waldump -p /var/lib/postgresql/16/main/pg_wal -s 0/1584F320 -e 0/15851770
rmgr: Heap2       len (rec/tot):     60/  6228, tx:          0, lsn: 0/1584F320, prev 0/1584F2A8, desc: PRUNE snapshotConflictHorizon: 781, nredirected: 3, ndead: 1, blkref #0: rel 1663/16386/2619 blk 18 FPW
rmgr: Heap        len (rec/tot):     65/  2877, tx:        785, lsn: 0/15850B90, prev 0/1584F320, desc: HOT_UPDATE old_xmax: 785, old_off: 40, old_infobits: [], flags: 0x00, new_xmax: 0, new_off: 41, blkref #0: rel 1663/16386/16398 blk 8333 FPW
rmgr: Transaction len (rec/tot):     34/    34, tx:        785, lsn: 0/158516D0, prev 0/15850B90, desc: COMMIT 2026-10-10 04:26:34.355258 -03
rmgr: Heap        len (rec/tot):     78/    78, tx:        786, lsn: 0/158516F8, prev 0/158516D0, desc: HOT_UPDATE old_xmax: 786, old_off: 41, old_infobits: [], flags: 0x60, new_xmax: 0, new_off: 42, blkref #0: rel 1663/16386/16398 blk 8333
rmgr: Transaction len (rec/tot):     34/    34, tx:        786, lsn: 0/15851748, prev 0/158516F8, desc: COMMIT 2026-10-10 04:26:35.572982 -03
```

Look at the two `HOT_UPDATE` records on block 8333 of `orders` (file `16398`). The record itself is
about the same size both times, 65 and 78 bytes. **The first one's total is 2877, and it ends in
`FPW`**: a full-page write, a copy of the whole page attached to the record. The second has none.

The first line is not your update at all. Planning it read the planner's statistics, the catalog
`pg_statistic` (file `2619`), and the server took the chance to tidy old row versions out of one of
its pages. That was also the first change to that page since the checkpoint, so it went into the log
whole too, and it was the largest item in the 9176.

## Why a whole page

A page is 8 kB, and the disk underneath writes in smaller pieces, which lesson 9 is about. **If the
power fails halfway through writing a page, the page on disk is half old and half new**, a
*torn page*. A record that says "in block 8333, replace the row at slot 40" cannot be replayed onto
that, because it assumes the rest of the page is intact.

So the first time any page is changed after a checkpoint, its record carries an image of the whole
page. Recovery always starts from a checkpoint, as lesson 8 shows, so for every page it meets the
image first: it puts the page back exactly, then applies the small records that came after it. The
second change to the same page needs no image, because the first one already guaranteed a good
copy in the log. That is the setting `full_page_writes`, on by default, and lesson 8 explains why it
stays on.

The image leaves out the unused middle of the page, which is why the total was 2877 and not 8192:
block 8333 is the last page of `orders`, and only part of it is full. A packed page costs nearly the
whole 8 kB.

## A whole table

One row is a curiosity. The same arithmetic over a million rows is the reason `pg_wal` grows. Copy
`orders` into a scratch table, so the real one is left alone, and update every row twice:

```
shop=# CREATE TABLE orders_copy AS SELECT * FROM orders;
SELECT 1000000

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy'));
 pg_size_pretty 
----------------
 66 MB
(1 row)

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT pg_current_wal_lsn() AS before \gset
shop=# UPDATE orders_copy SET total_cents = total_cents + 1;
UPDATE 1000000

shop=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before'));
 pg_size_pretty 
----------------
 234 MB
(1 row)

shop=# SELECT pg_current_wal_lsn() AS before \gset
shop=# UPDATE orders_copy SET total_cents = total_cents - 1;
UPDATE 1000000

shop=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before'));
 pg_size_pretty 
----------------
 171 MB
(1 row)

shop=# DROP TABLE orders_copy;
DROP TABLE
```

**Updating a 66 MB table once wrote 234 MB of log.** Every row's update is written down with the
new version of the row and the pages it touched, so even the second pass, with no page images left
to take, wrote 171 MB. Most of the 63 MB between the two is the first pass's images: right after a
checkpoint, nearly every one of the table's original pages was changed for the first time.

Three things follow, and an administrator uses all of them:

- A bulk change writes several times its own size in WAL. Plan disk space and replica traffic
  for the log, not for the table.
- The first minutes after a checkpoint write more log than the minutes before the next one. A
  checkpoint every thirty seconds would keep the whole server in that expensive phase; lesson 8
  measures exactly that.
- `wal_compression` exists for the images. It compresses each page image as it is written, at
  some cost in processor time. It is off by default and was not changed for this lesson.
