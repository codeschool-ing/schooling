---
title: Partitioning one big table
version: 1
---

**Partitioning splits one table into several, by the value of one column, while the program keeps
seeing one table.** It does not add a server and does not divide the load between machines. What
it divides is the work of each query, and the work of throwing data away.

The box office's `tickets` table grows by every sale and never shrinks. After two years, most of
its rows describe concerts that are over, and most queries ask about the last few weeks. Every
index on it covers all two years, and every query that is not answered by an index reads through
all of them.

PostgreSQL's **declarative partitioning** declares a parent table with a **partition key**, and
child tables that each own a range of that key. A row inserted into the parent goes into the child
whose range contains it; a query against the parent reads only the children that could hold
matching rows. That second part is **partition pruning**, and it is most of the point.

Here is a table of sales partitioned by month, January to June 2026, filled with 1.2 million
generated rows spread over those six months:

```sql
-- partitions.sql
CREATE TABLE sales (
  event_id int         NOT NULL,
  sold_at  timestamptz NOT NULL,
  cents    int         NOT NULL
) PARTITION BY RANGE (sold_at);

CREATE TABLE sales_2026_01 PARTITION OF sales FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE sales_2026_02 PARTITION OF sales FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE sales_2026_03 PARTITION OF sales FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE sales_2026_04 PARTITION OF sales FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE sales_2026_05 PARTITION OF sales FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE sales_2026_06 PARTITION OF sales FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

INSERT INTO sales (event_id, sold_at, cents)
SELECT 1 + n % 100,
       '2026-01-01'::timestamptz + (n % 181) * interval '1 day' + (n % 86400) * interval '1 second',
       5000 + n % 20000
FROM generate_series(1, 1200000) AS n;
```

Each `CREATE TABLE … PARTITION OF` names a range, from its first moment to the first moment of the
next month, and the upper bound is excluded, so the months do not overlap. **A row whose date falls
in no partition is refused**: inserting a sale for July before `sales_2026_07` exists is an error,
which is the reason a partitioned table needs someone, or a scheduled job, to create next month's
partition before next month starts.

## Loading it

The file goes into the container and runs there:

```
ana@lab:~/tickets$ docker compose cp partitions.sql db:/tmp/partitions.sql
 tickets-db-1 Copying partitions.sql to tickets-db-1:/tmp/partitions.sql
 tickets-db-1 Copied partitions.sql to tickets-db-1:/tmp/partitions.sql
ana@lab:~/tickets$ docker compose exec db psql -U tickets -f /tmp/partitions.sql
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 1200000
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT tableoid::regclass AS partition, count(*) FROM sales GROUP BY 1 ORDER BY 1'
   partition   | count  
---------------+--------
 sales_2026_01 | 205529
 sales_2026_02 | 185640
 sales_2026_03 | 205530
 sales_2026_04 | 198900
 sales_2026_05 | 205530
 sales_2026_06 | 198871
(6 rows)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "EXPLAIN (COSTS OFF) SELECT count(*) FROM sales WHERE sold_at >= '2026-06-01'"
                                         QUERY PLAN                                          
---------------------------------------------------------------------------------------------
 Finalize Aggregate
   ->  Gather
         Workers Planned: 1
         ->  Partial Aggregate
               ->  Parallel Seq Scan on sales_2026_06 sales
                     Filter: (sold_at >= '2026-06-01 00:00:00+00'::timestamp with time zone)
(6 rows)
```

The parent and six children, 1 200 000 rows, and the count per partition shows where they went:
`tableoid::regclass` names the child table each row is stored in. February has fewer because it
has 28 days.

The plan for a query about June is the point of the whole exercise. **It reads `sales_2026_06`
and nothing else.** The filter on `sold_at` let the planner rule out five of the six partitions
before reading a row, so the query does a sixth of the work it would do on one big table, and
the indexes it would use are a sixth of the size.

## Choosing the key

Pruning only happens when the query filters on the partition key. A query for "every sale of show
42", on a table partitioned by month, has to read all six partitions, and is slightly slower than
on one table, because there are six plans instead of one. So the key is chosen by **the filter
most queries already carry**:

- **Time** (range partitioning) for anything that is mostly asked about recently and kept for a
  fixed period: sales, logs, events, measurements. It is by far the most common.
- **A list of values** (list partitioning) when a column has a few values that split the queries:
  a country, a region, a tenant.
- **A hash of a value** (hash partitioning) to split a table into equal pieces when no filter is
  common, which helps maintenance more than queries.

Partitioning is still one server. It makes a big table cheaper to query and to maintain; it does
not let it grow past what one machine can store or write. That is sharding, in section 09.
