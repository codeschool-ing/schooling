---
title: What bloat is
version: 1
---

**Bloat is space inside a table's or an index's files that holds no live row.** Some of it is
normal and useful: the free space VACUUM records is where the next `UPDATE` puts its new version.
It becomes a problem when there is far more of it than the table's own traffic will ever reuse,
because every sequential scan reads it, every backup copies it and the disk holds it.

The cause is the one lesson 14 showed: an `UPDATE` writes a new version, VACUUM frees the old one,
and **nothing returns the space to the operating system**. A copy of `orders` with the same three
indexes shows it in four statements. Updating every row once is the extreme case, and it happens:
a backfill of a new column, a correction applied to every order, a migration that touches the
whole table.

```
shop=# CREATE TABLE orders_copy AS SELECT * FROM orders;
SELECT 1000000

shop=# ALTER TABLE orders_copy ADD PRIMARY KEY (id);
ALTER TABLE

shop=# CREATE INDEX orders_copy_customer_id ON orders_copy (customer_id);
CREATE INDEX

shop=# CREATE INDEX orders_copy_created_at ON orders_copy (created_at);
CREATE INDEX

shop=# VACUUM ANALYZE orders_copy;
VACUUM

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS table_size, pg_size_pretty(pg_indexes_size('orders_copy')) AS indexes;
 table_size | indexes 
------------+---------
 66 MB      | 37 MB
(1 row)

shop=# UPDATE orders_copy SET total_cents = total_cents + 1;
UPDATE 1000000

shop=# VACUUM orders_copy;
VACUUM

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS table_size, pg_size_pretty(pg_indexes_size('orders_copy')) AS indexes;
 table_size | indexes 
------------+---------
 130 MB     | 75 MB
(1 row)

shop=# SELECT count(*) FROM orders_copy;
  count  
---------
 1000000
(1 row)
```

The table went from 66 MB to 130 MB and its indexes from 37 MB to 75 MB, for the same million rows.
Each updated row needed room for its new version, the old pages were full of versions the `UPDATE`
had not finished with yet, and so every new version went to the end of the file. VACUUM then freed
the whole first half. It is free, it is inside the file, and the file has the size it had at its
fullest.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Four rows of squares, each square a group of pages of the copy of orders. Loaded: eight groups full of live rows. After updating every row: the same eight groups now hold only dead versions, and eight new groups hold the live ones; the file has doubled. After VACUUM: the first eight groups are free space, still inside the file, and the size has not changed. After VACUUM FULL: the live rows are written into a new file of eight groups, and the free space is gone.\"><text x=\"16\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">loaded</text><rect x=\"200\" y=\"24\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"226\" y=\"24\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"252\" y=\"24\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"278\" y=\"24\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"304\" y=\"24\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"330\" y=\"24\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"356\" y=\"24\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"382\" y=\"24\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"704\" y=\"35\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">66 MB</text><text x=\"16\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">UPDATE of every row</text><rect x=\"200\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"226\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"252\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"278\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"304\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"330\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"356\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"382\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"408\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"434\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"460\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"486\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"512\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"538\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"564\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"590\" y=\"70\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"704\" y=\"81\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">130 MB</text><text x=\"16\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">VACUUM</text><rect x=\"200\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"226\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"252\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"278\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"304\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"330\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"356\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"382\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"408\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"434\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"460\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"486\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"512\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"538\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"564\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"590\" y=\"116\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"704\" y=\"127\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">130 MB</text><text x=\"16\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">VACUUM FULL</text><rect x=\"200\" y=\"162\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"226\" y=\"162\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"252\" y=\"162\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"278\" y=\"162\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"304\" y=\"162\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"330\" y=\"162\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"356\" y=\"162\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"382\" y=\"162\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"704\" y=\"173\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">smaller again</text><rect x=\"200\" y=\"214\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"220\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">live rows</text><rect x=\"330\" y=\"214\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dead versions</text><rect x=\"480\" y=\"214\" width=\"14\" height=\"14\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"500\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">free space in the file</text></svg>", "caption": "Bloat is the third row: a file twice the size of what it holds, every byte of the difference reusable and none of it returned."}
```

## The one thing VACUUM does give back

There is an exception, and it explains why a plain VACUUM sometimes does shrink a table. **Empty
pages at the very end of the file are cut off.** The new versions went to the end in order of `id`,
so the highest ids live in the last pages:

```
shop=# DELETE FROM orders_copy WHERE id > 900000;
DELETE 100000

shop=# VACUUM orders_copy;
VACUUM

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS table_size, pg_size_pretty(pg_indexes_size('orders_copy')) AS indexes;
 table_size | indexes 
------------+---------
 130 MB     | 75 MB
(1 row)

shop=# DELETE FROM orders_copy WHERE id > 800000;
DELETE 100000

shop=# VACUUM orders_copy;
VACUUM

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS table_size, pg_size_pretty(pg_indexes_size('orders_copy')) AS indexes;
 table_size | indexes 
------------+---------
 117 MB     | 75 MB
(1 row)
```

Deleting the top 100,000 ids emptied the last twentieth of the file, since the file holds every row twice over, and VACUUM left it alone. Deleting
the next 100,000 took the table to 117 MB. VACUUM truncates only when the empty tail is at least
1,000 pages or a sixteenth of the table, because cutting needs a moment of exclusive lock on the
table, and it will not take one to save a few pages. A twentieth of this file is under 1,000 pages and
under a sixteenth; a tenth is over both. Free space anywhere else in the file, which is almost all of it, stays.

The copy now holds 800,000 live rows in 117 MB, with its indexes still at 75 MB. The rest of this
lesson measures that and fixes it.
