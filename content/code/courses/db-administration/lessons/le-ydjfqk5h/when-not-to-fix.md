---
title: When to leave it alone
version: 1
---

A rebuilt table looks like a win on a graph of disk usage, and for a table that is updated all day
it is a win that undoes itself. **A table with steady traffic settles at a size of its own**, larger
than its rows, and stays there. The free space is where each day's updates land. Take it away and
the next updates have to grow the file again to find room.

The compact copy from the previous section shows it. Update a fifth of its rows, vacuum, and look;
then do it twice more, with a different fifth each time:

```
shop=# UPDATE orders_copy SET total_cents = total_cents + 1 WHERE id % 5 = 0;
UPDATE 160000

shop=# VACUUM orders_copy;
VACUUM

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS table_size, pg_size_pretty(pg_indexes_size('orders_copy')) AS indexes;
 table_size | indexes 
------------+---------
 63 MB      | 56 MB
(1 row)

shop=# UPDATE orders_copy SET total_cents = total_cents + 1 WHERE id % 5 = 1;
UPDATE 160000

shop=# VACUUM orders_copy;
VACUUM

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS table_size, pg_size_pretty(pg_indexes_size('orders_copy')) AS indexes;
 table_size | indexes 
------------+---------
 63 MB      | 56 MB
(1 row)

shop=# UPDATE orders_copy SET total_cents = total_cents + 1 WHERE id % 5 = 2;
UPDATE 160000

shop=# VACUUM orders_copy;
VACUUM

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS table_size, pg_size_pretty(pg_indexes_size('orders_copy')) AS indexes;
 table_size | indexes 
------------+---------
 63 MB      | 57 MB
(1 row)
```

The first round grew the table from 52 MB to 63 MB, because a compact table has nowhere to put new
versions except the end. **The second round did not grow it at all**: VACUUM had freed the first
round's old versions, and the second round's new versions went into that space. Nor did the third.
That is the shape of a healthy table under load, and 63 MB is this table's working size for this
traffic. Rebuilding it to 52 MB again would buy back 11 MB until the next batch of updates.

The indexes moved further, from 31 MB to 56 MB in the first round, and stayed within a megabyte of
that. Their
compact size after a rebuild was only true until the first wave of updates.

So the useful question is not "how much free space is there" but **whether the free space is larger
than the traffic will ever use**. Some cases where it is:

- a one-off: a backfill, a mass correction or a purge of old rows, like the update of every row at
  the start of this lesson. The space it left will not be reused at the rate it was made;
- the disk is running out and the space is needed elsewhere now;
- sequential scans of the table are a problem, and `pgstattuple` says most of what they read is
  empty.

And some where it is not: a table that grows back to the same size within days of a rebuild, a
free percentage that is steady from week to week, a table nobody scans in full. For a table with
many updates you can even ask for more free space on purpose. `ALTER TABLE ... SET (fillfactor =
90)` makes inserts leave a tenth of each page empty, so that an update finds room on the same page
and can be HOT, with no new index entries at all.

## Putting shop back

The copy, and the two extensions in `shop`, were for this lesson. The package stays installed;
removing it is not needed.

```
shop=# DROP TABLE orders_copy;
DROP TABLE

shop=# DROP EXTENSION pg_repack;
DROP EXTENSION

shop=# DROP EXTENSION pgstattuple;
DROP EXTENSION
```
