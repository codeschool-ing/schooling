---
title: A cache the database keeps for you
version: 1
---

Everything so far put a second system beside PostgreSQL and made the application responsible for
keeping the two in step. There is a cache that lives **inside** the database, needs no second server
and cannot be forgotten by a code path that writes: the **materialized view**. It is the wrong tool
for a value that must be fresh, and often the right one for a summary that is read all day and may
be a few minutes old, which describes most dashboards.

A view is a stored query: every read runs it again. A materialized view runs the query once, stores
the rows like a table, and serves those rows to every read until somebody tells it to run the query
again. The belief to put down is that it stays in step with its tables, as an index does. **It does
not.** It is a snapshot, refreshed only when asked.

## The dashboard for every seller, once

The seller dashboard asks, per seller, how many orders and how much money each day since 1 December.
Instead of asking it once per seller per refresh, compute it for all sellers at once:

```
market=# SELECT sum(count) FROM (SELECT count(*) FROM orders WHERE seller_id = 42 AND placed_at >= '2025-12-01' GROUP BY date_trunc('day', placed_at)) AS d;
 sum 
-----
  81
(1 row)

Time: 5.667 ms

market=# CREATE MATERIALIZED VIEW seller_days AS SELECT seller_id, date_trunc('day', placed_at)::date AS day, count(*) AS orders, sum(total_cents)::bigint AS total FROM orders WHERE placed_at >= '2025-12-01' GROUP BY 1, 2;
SELECT 27942
Time: 67.329 ms
```

The live query for seller 42 took **5.7 milliseconds** and found **81** orders. The materialized view
computed the same summary for every seller in **67 milliseconds**: **27942** rows, one per seller per
day. That is the whole cost of filling it, paid once, by one statement.

## Refreshing without locking everybody out

A refresh can be done two ways. A plain `REFRESH MATERIALIZED VIEW` rebuilds the view and swaps it
in, holding a lock that **blocks every read of the view** while it works: on a dashboard read all
day, that is a pause for everybody at every refresh. `REFRESH MATERIALIZED VIEW CONCURRENTLY`
computes the new rows beside the old ones and applies only the differences, so readers keep reading
the old rows until it finishes. It needs a way to match a new row with an old one, and says so:

```
market=# REFRESH MATERIALIZED VIEW CONCURRENTLY seller_days;
ERROR:  cannot refresh materialized view "public.seller_days" concurrently
HINT:  Create a unique index with no WHERE clause on one or more columns of the materialized view.
Time: 0.957 ms

market=# CREATE UNIQUE INDEX ON seller_days (seller_id, day);
CREATE INDEX
Time: 17.745 ms
```

**`cannot refresh materialized view "public.seller_days" concurrently`**, with the hint to create a
unique index with no `WHERE` clause. `(seller_id, day)` identifies a row of this view, so that is
the index, and it also serves the dashboard's own lookup by seller.

## Stale until asked, and the cost of asking

Read seller 42 from the view, place an order for seller 42, read again, refresh, read again:

```
market=# SELECT sum(orders) FROM seller_days WHERE seller_id = 42;
 sum 
-----
  81
(1 row)

Time: 0.961 ms

market=# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (42, 42, now(), 'pending', 1990);
INSERT 0 1
Time: 5.647 ms

market=# SELECT sum(orders) FROM seller_days WHERE seller_id = 42;
 sum 
-----
  81
(1 row)

Time: 0.537 ms

market=# REFRESH MATERIALIZED VIEW CONCURRENTLY seller_days;
REFRESH MATERIALIZED VIEW
Time: 318.175 ms

market=# SELECT sum(orders) FROM seller_days WHERE seller_id = 42;
 sum 
-----
  82
(1 row)

Time: 0.972 ms
```

From the view, seller 42's dashboard costs **0.96 milliseconds**, against 5.7 for the live query.
The new order did not appear, **81** before and after it, until the refresh, and then **82**. The
concurrent refresh took **318 milliseconds**, during which every reader went on getting answers.
Compare it with the plain refresh:

```
market=# REFRESH MATERIALIZED VIEW seller_days;
REFRESH MATERIALIZED VIEW
Time: 112.877 ms
```

**113 milliseconds**, about a third of the concurrent one, because it only rebuilds where the
concurrent one also compares old rows with new. Concurrently is slower and does not block readers;
plain is faster and blocks them. For a view read all day, slower and invisible is the better trade.

## When to use which

The refresh is something you schedule: from `cron`, from the application after a batch of writes,
or with an extension such as `pg_cron`. Every refresh recomputes the whole view, so its cost is the
cost of the full query, however few rows changed, and the view is as stale as the time since the
last refresh. That makes the two kinds of cache complements rather than rivals:

| | a materialized view | Redis, cache-aside |
|---|---|---|
| where it lives | inside PostgreSQL | a second server |
| who keeps it in step | a scheduled refresh | every code path that writes |
| how stale | since the last refresh, for every key at once | up to the TTL, per key |
| cost of a refresh or a miss | the whole query, for every seller | one query, for one seller |
| what it saves | the work, but each read is still a query | the work and the trip to the database |

A busy shop often has both: a materialized view so that the expensive summary is computed once a
minute rather than once per seller, and a cache in front of it so that the reads stop reaching
PostgreSQL at all.

## Putting the machine back

Stop Redis, which `apt` set to start at every boot, and put `market` back:

```
ana@vm:~$ sudo systemctl stop redis-server
```

`sudo systemctl disable redis-server` keeps it from starting at the next boot; the lessons after this
one do not use it. The materialized view, its index and the orders this lesson placed go with
`~/reset-market.sh`.
