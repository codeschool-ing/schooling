---
title: The other index types, and the problem each one is for
version: 1
---

Everything so far has been the B-tree, which is the default and is the right answer for nearly
every index you will ever create. The others exist because there are questions a sorted list cannot
answer, and it is worth knowing which questions those are — mostly so that you recognise a problem
as solvable rather than as slow.

## Hash

```sql
CREATE INDEX ON sessions USING hash (token);
```

Stores a hash of the value. Answers `=` and nothing else: no ranges, no ordering, no prefix `LIKE`,
no help with `ORDER BY`.

It can be smaller than a B-tree on a long text column, which is the one argument for it. Against
that, a B-tree answers equality perfectly well and also answers everything else. PostgreSQL's hash
indexes were not written to the write-ahead log before version 10, so they could not survive a
crash and were widely advised against; that is fixed, and the advice outlived the problem.

**Reach for a B-tree unless you have measured a reason not to.**

## GIN — for values that contain many things

A row's `tags` column holds `{'sql', 'databases', 'beginner'}`. A B-tree could index the whole array
as one value, which lets you find rows whose tags are exactly that. It cannot find rows whose tags
*include* `'sql'`.

GIN — a generalised inverted index — indexes the **elements**, with a list of rows for each:

```sql
CREATE INDEX ON articles USING gin (tags);
SELECT * FROM articles WHERE tags @> ARRAY['sql'];
```

The same structure serves three things you will actually meet:

```sql
CREATE INDEX ON documents USING gin (payload jsonb_path_ops);  -- keys inside a JSON column
CREATE INDEX ON articles  USING gin (to_tsvector('english', body));  -- full-text search
CREATE INDEX ON customers USING gin (name gin_trgm_ops);       -- and the one from earlier
```

That last line is the fix for `LIKE '%ana%'`. The `pg_trgm` extension breaks each string into
three-character pieces and indexes those, so a substring becomes a set of trigrams to look up
rather than a scan. It also powers fuzzy matching by similarity.

The trade: GIN is **slower to update** than a B-tree, sometimes considerably, because one row
produces many entries. It is a search structure, and it suits data that is read far more than it is
written.

## GiST — for things that are not points on a line

Ranges and shapes do not sort. Two date ranges can overlap without either being "less than" the
other, so no sorted list arranges them usefully. GiST is a framework for indexes over that kind of
value:

```sql
CREATE INDEX ON reservations USING gist (during);
```

It is what PostGIS is built on for geographic data, and it is what lesson 8's exclusion constraint
requires:

```sql
ALTER TABLE reservations ADD CONSTRAINT no_overlap
EXCLUDE USING gist (room_id WITH =, during WITH &&);
```

So this index type is not only a performance tool — it is the mechanism by which a correctness rule
about overlaps can be enforced at all.

## BRIN — tiny, for enormous ordered tables

A B-tree on a billion-row table is large. BRIN stores, per block range, only the minimum and maximum
value found in it:

```sql
CREATE INDEX ON events USING brin (created_at);
```

Kilobytes rather than gigabytes. A query for a date range skips every block range whose min and max
cannot contain it, and reads the rest.

It works only when **the column correlates with the physical order of the rows**, which is exactly
the case for an append-only log with a timestamp: rows written in March sit together because they
were written together. Shuffle the table, or index a column with no relation to insert order, and
every block range spans everything and BRIN eliminates nothing.

For a large, append-only, time-ordered table it is one of the best trades available: a negligible
index that removes most of the reads.

## What the other engines have

**MySQL and MariaDB**: B-tree for InnoDB, plus `FULLTEXT` for text search and `SPATIAL` for
geometry. Hash indexes exist in the in-memory engine. There is no GIN and no BRIN; MySQL 8.0.17
added multi-valued indexes for arrays inside JSON, which covers a slice of what GIN does.

**SQLite**: B-tree, and that is the list. Full-text search is a virtual table module, FTS5, rather
than an index type.

## The honest summary

| type | for | where |
|---|---|---|
| **B-tree** | equality, ranges, ordering, prefixes | everywhere, and nearly always the answer |
| **GIN** | elements inside a value: arrays, JSON, text, trigrams | PostgreSQL |
| **GiST** | overlaps and shapes, and exclusion constraints | PostgreSQL |
| **BRIN** | huge tables whose order matches the column | PostgreSQL |
| **hash** | equality on a long value, and nothing else | PostgreSQL, rarely worth it |

The useful takeaway is not the table. It is that **`LIKE '%…%'`, searching inside a JSON column,
and "no two bookings may overlap" are all solvable** — and that if you are on MySQL or SQLite, two
of them are solvable differently and one of them is not, which is a thing to know before you design
the feature rather than afterwards.
