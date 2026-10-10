---
title: CREATE INDEX CONCURRENTLY, and the IF NOT EXISTS that lies
version: 1
---

A new index has the same problem as a rebuilt one. **A plain `CREATE INDEX` takes `ShareLock` on
the table**, the lock the `REINDEX` in terminal 1 held: reads carry on, and every insert, update
and delete waits until the build is finished. On a table that is written all day, that is the
outage again, and `CREATE INDEX CONCURRENTLY` is the same answer: the same steps as the figure in
the previous section, without the swap, under the weaker lock, slower, and outside any transaction
block.

It fails the same way too, and a unique index is the usual way. Every customer in `shop` has twenty
orders, so an index promising one order per customer cannot be built:

```
shop=# CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS orders_one_per_customer ON orders (customer_id);
ERROR:  could not create unique index "orders_one_per_customer"
DETAIL:  Key (customer_id)=(16120) is duplicated.
CONTEXT:  parallel worker

shop=# CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS orders_one_per_customer ON orders (customer_id);
NOTICE:  relation "orders_one_per_customer" already exists, skipping
CREATE INDEX

shop=# SELECT indexrelid::regclass, indisvalid, indisready FROM pg_index WHERE indrelid = 'orders'::regclass;
       indexrelid        | indisvalid | indisready 
-------------------------+------------+------------
 orders_pkey             | t          | t
 orders_customer_id      | t          | t
 orders_created_at       | t          | t
 orders_one_per_customer | f          | f
(4 rows)

shop=# DROP INDEX CONCURRENTLY orders_one_per_customer;
DROP INDEX
```

The first attempt read the table, found a duplicate and stopped; `CONTEXT: parallel worker` says
that one of the processes helping with the build found it. A plain `CREATE UNIQUE INDEX` failing
like that leaves nothing, because the whole statement is one transaction and rolls back. **The
concurrent one leaves the index it had started, invalid**, for the reason the figure gives: its
first step was already committed.

The second attempt is the trap. **`IF NOT EXISTS` looks at the name and nothing else**, finds an
index called `orders_one_per_customer`, says it is skipping, and reports `CREATE INDEX` as if it had
succeeded. A migration tool that runs its statements with `IF NOT EXISTS` so it can be run twice
will report success on the second run, with no usable index and nothing in its own output saying
so. Only `pg_index` tells the truth: `indisvalid` is `f`, so no query will use it.

`indisready` says whether the index is being kept up to date by writes. This one failed during the
build and never got that far, so it costs nothing but its name and its disk. A concurrent build that
fails later, in the validation step, leaves an index with `indisready` true: maintained on every
write and used by no query, the worst of both.

**After any statement with `CONCURRENTLY` in it fails, look in `pg_index` before running it again**,
and drop what it left. Then fix the cause — here, the data, or the idea that customers order once —
and run the statement without `IF NOT EXISTS`, so a leftover makes it fail loudly instead of skip
quietly.

A unique index built this way can then carry a constraint without another scan of the table, which
is how a primary key or a unique constraint is added to a live table. Lesson 22 does that, with the
other changes to a live table's schema.
