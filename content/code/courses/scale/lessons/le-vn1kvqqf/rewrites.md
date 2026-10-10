---
title: Changes that rewrite the table
version: 1
---

Once a change has its lock, what matters is how long it keeps it, and that depends on whether
PostgreSQL has to touch every row. A simple way to tell is the table's **filenode**, the name of
the file on disk that holds its rows: a change that rewrites the table writes a new file, and the
filenode changes.

Three changes, each timed, with the filenode checked between them:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT pg_relation_filenode('tickets')"
 pg_relation_filenode 
----------------------
                16395
(1 row)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ADD COLUMN printed boolean NOT NULL DEFAULT false'
Timing is on.
ALTER TABLE
Time: 2.125 ms
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT pg_relation_filenode('tickets')"
 pg_relation_filenode 
----------------------
                16395
(1 row)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ADD COLUMN printed_at timestamptz DEFAULT clock_timestamp()'
Timing is on.
ALTER TABLE
Time: 5405.595 ms (00:05.406)
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT pg_relation_filenode('tickets')"
 pg_relation_filenode 
----------------------
                16418
(1 row)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ALTER COLUMN seat TYPE bigint'
Timing is on.
ALTER TABLE
Time: 5048.176 ms (00:05.048)
```

- **A new column with a constant default**, `printed boolean NOT NULL DEFAULT false`: **2.1 ms**,
  and the filenode is still 16395. Since PostgreSQL 11 a constant default is stored once in the
  catalogue and returned for every old row that lacks the column, so nothing is written.
- **A new column whose default is volatile**, `DEFAULT clock_timestamp()`, a function that returns
  a different value every time it is called: **5.4 seconds**, and the filenode is now 16418. Every
  row needs its own value, so every row was written again, into a new file, with the table locked
  the whole time.
- **A wider type**, `seat` from `int` to `bigint`: **5.0 seconds**, another full rewrite, plus
  rebuilding the unique index that includes the column.

On two million rows each rewrite cost seconds of a table that nobody could read or write. On two
hundred million it is several minutes, and that is an outage with a migration's name on it.

## Sorting the common changes

| change | how long it holds `ACCESS EXCLUSIVE` |
|---|---|
| add a nullable column, or one with a constant default | an instant: catalogue only |
| drop a column | an instant: the column is hidden, its space reclaimed later |
| rename a column or a table | an instant, and it breaks every program using the old name |
| add a column with a volatile default | a full rewrite |
| change a column's type, in most cases | a full rewrite, and its indexes rebuilt |
| `SET NOT NULL` | a full scan, unless a valid `CHECK` proves it, which section 09 uses |
| add a foreign key or a `CHECK` | a full scan, unless added `NOT VALID` first, as in section 09 |

The rule that comes out of the table: **for each change, know whether it is catalogue-only, a scan,
or a rewrite, before running it on a large table.** The test is cheap: run it on a copy of
production with production's size, and time it, as this section did. The ones that rewrite are
done another way, in steps, which is section 07.
