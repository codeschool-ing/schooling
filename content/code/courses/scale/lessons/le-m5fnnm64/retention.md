---
title: Throwing old data away
version: 1
---

The second thing partitions are good at is deleting. A sales table that keeps eighteen months has
to lose a month of rows every month, and there are two ways to do it.

On one big table, it is a `DELETE` with a date in the `WHERE`. On a partitioned table, the oldest
partition can be detached and dropped instead. This script times both, on the table of the last
section; the `DELETE` runs inside a transaction that is rolled back, so that the rows are still
there for the second way:

```sql
-- retention.sql
\timing on
BEGIN;
DELETE FROM sales WHERE sold_at < '2026-02-01';
ROLLBACK;
ALTER TABLE sales DETACH PARTITION sales_2026_01;
DROP TABLE sales_2026_01;
```

```
ana@lab:~/tickets$ docker compose cp retention.sql db:/tmp/retention.sql
 tickets-db-1 Copying retention.sql to tickets-db-1:/tmp/retention.sql
 tickets-db-1 Copied retention.sql to tickets-db-1:/tmp/retention.sql
ana@lab:~/tickets$ docker compose exec db psql -U tickets -f /tmp/retention.sql
Timing is on.
BEGIN
Time: 0.225 ms
DELETE 205529
Time: 198.865 ms
ROLLBACK
Time: 0.189 ms
ALTER TABLE
Time: 6.859 ms
DROP TABLE
Time: 3.539 ms
```

The `DELETE` took **199 ms** for 205 529 rows, and the detach and the drop **under 11 ms
together**. The numbers are small because the table is small, and the ratio is what grows: a
`DELETE`'s cost is proportional to the rows it removes, while dropping a partition costs about the
same for a thousand rows or a billion, because it removes files rather than rows.

What the timing does not show is worse for the `DELETE`:

- **Every deleted row is a change in the log.** It is written to the WAL, sent to every replica,
  and applied there too, so a big delete is a burst of replication lag on every replica at once.
- **Deleted rows are not gone.** PostgreSQL marks them dead and leaves them in place until
  `VACUUM` reclaims the space, so the table stays the same size on disk for a while and the
  indexes still carry their entries.
- **It holds locks on every row it deletes** until it commits, and a long one competes with the
  sales still arriving.

`DETACH PARTITION` takes the child out of the parent, after which it is an ordinary table that
queries on `sales` no longer see. That is a useful moment to pause: the old month can be copied to
cheaper storage, or kept for a while in case someone asks, before `DROP TABLE` removes it. On a
busy table, `DETACH PARTITION … CONCURRENTLY` does the same without blocking queries on the
parent, at the price of being slower and not running inside a transaction.
