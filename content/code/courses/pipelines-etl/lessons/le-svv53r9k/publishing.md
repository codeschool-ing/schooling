---
title: What readers see while you load
version: 1
---

A load writes to a table people are reading. **Which statement it uses decides whether they notice.**
Two ways of replacing a small table's contents, each held open for five seconds by `pg_sleep`, as a
slow load would be, with a reader arriving during it:

First, `TRUNCATE` and refill:

```sql
BEGIN; TRUNCATE marts.dim_shop; INSERT INTO marts.dim_shop SELECT * FROM raw.shops; SELECT pg_sleep(5); COMMIT;
```

Then `DELETE` and refill:

```sql
BEGIN; DELETE FROM marts.dim_shop; INSERT INTO marts.dim_shop SELECT * FROM raw.shops; SELECT pg_sleep(5); COMMIT;
```

The reader, with a two-second limit on how long it will wait for a lock, tried once during each:

```
ana@vm:~/etl$ psql -d wh -c "SET lock_timeout = '2s'" -c "SELECT count(*) FROM marts.dim_shop"
SET
ERROR:  canceling statement due to lock timeout
LINE 1: SELECT count(*) FROM marts.dim_shop
                             ^
ana@vm:~/etl$ psql -d wh -c "SET lock_timeout = '2s'" -c "SELECT count(*) FROM marts.dim_shop"
SET
 count 
-------
     7
(1 row)
```

**`TRUNCATE` locked the reader out.** It takes the strongest lock PostgreSQL has, because it does
not delete rows — it throws the table's files away — and nobody may read a table whose files are
being thrown away. The reader waited, ran out of patience and failed; a dashboard would have hung.

**`DELETE` let the reader in, and showed it the old rows.** Each row is marked deleted by the
loading transaction, and until that transaction commits, everybody else still sees them. The
reader got seven shops, the table as it was before the load began.

## Choosing

| | `TRUNCATE` + insert | `DELETE` + insert |
|---|---|---|
| readers during the load | wait, or fail | see the old rows |
| speed on a large table | fast: no row is touched | slower: every row is marked, then cleaned up later |
| left behind | nothing | dead rows, until `VACUUM` reclaims them |

For a table of seven shops, `DELETE` costs nothing and keeps readers happy. For a table of a hundred
million rows, neither is right: the load builds a **new table** beside the old one, and swaps
them with two `ALTER TABLE ... RENAME` statements in one transaction, which holds the strong lock for
milliseconds rather than for the whole load. Lesson 19 measures what a large load costs, and that
is where the swap pays for itself.
