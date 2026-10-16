---
title: The clustering key orders the rows inside a partition
version: 1
---

The partition key says **where** a partition lives. The clustering columns say **in what order its
rows are kept** once you are there, and that order is on disk, not computed when you ask. A common
first reading of `PRIMARY KEY (customer, ordered_at, order_id)` is "a composite key, like SQL's".
It is three different jobs in one line:

| part | in `orders_by_customer` | what it decides |
| --- | --- | --- |
| partition key | `customer` | which nodes hold the rows; a query must name it with `=` or `IN` |
| first clustering column | `ordered_at` | the order of rows inside the partition, and the ranges you can ask for |
| next clustering column | `order_id` | the order among rows with the same `ordered_at`, and what makes each row unique |

`order_id` is in the key for the last reason. **An `INSERT` whose full primary key already exists
overwrites that row without an error**, so a key of `(customer, ordered_at)` alone would let two
orders placed by one customer in the same millisecond become one. Adding the order's own id costs
nothing and closes that door.

## Asking one partition

`WITH CLUSTERING ORDER BY (ordered_at DESC, order_id ASC)` stores each customer's newest order
first. Ask for Ana's partition, then a range of it, then the newest one, then the oldest first:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com';

 order_id | ordered_at                      | total
----------+---------------------------------+---------
   A-1006 | 2026-04-08 12:30:00.000000+0000 | 1499.00
   A-1004 | 2026-03-20 00:02:00.000000+0000 |  189.00
   A-1001 | 2026-03-02 13:15:00.000000+0000 |  349.90

(3 rows)
cqlsh> SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' AND ordered_at >= '2026-03-01' AND ordered_at < '2026-04-01';

 order_id | ordered_at                      | total
----------+---------------------------------+--------
   A-1004 | 2026-03-20 00:02:00.000000+0000 | 189.00
   A-1001 | 2026-03-02 13:15:00.000000+0000 | 349.90

(2 rows)
cqlsh> SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' LIMIT 1;

 order_id | ordered_at                      | total
----------+---------------------------------+---------
   A-1006 | 2026-04-08 12:30:00.000000+0000 | 1499.00

(1 rows)
cqlsh> SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' ORDER BY ordered_at ASC;

 order_id | ordered_at                      | total
----------+---------------------------------+---------
   A-1001 | 2026-03-02 13:15:00.000000+0000 |  349.90
   A-1004 | 2026-03-20 00:02:00.000000+0000 |  189.00
   A-1006 | 2026-04-08 12:30:00.000000+0000 | 1499.00

(3 rows)
cqlsh> SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' ORDER BY total DESC;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Order by is currently only supported on the clustered columns of the PRIMARY KEY, got total"
cqlsh> exit
```

Four things in that transcript are worth naming:

- **The first query has no `ORDER BY` and comes back newest first.** That is the stored order,
  read from the top. A table created without `DESC` would return the oldest first.
- **The range on `ordered_at` is a slice of the partition**, not a filter over it. Because the rows
  are sorted by date, March is one contiguous stretch: Cassandra finds where it starts and reads
  until it ends.
- **`LIMIT 1` is "Ana's latest order"**, the most common question a shop asks about a customer, and
  it reads exactly one row. The `DESC` in the table definition is what makes it the latest rather
  than the first she ever placed.
- **`ORDER BY ordered_at ASC` works and `ORDER BY total` is refused.** Reading a partition backwards
  is cheap, so you may reverse the clustering order. Sorting by anything else would mean reading
  every row and sorting in memory, and Cassandra refuses rather than do that quietly: `Order by is
  currently only supported on the clustered columns of the PRIMARY KEY`.

## What a range may and may not do

The clustering columns form a sorted path, and a range is only cheap along it. `ordered_at >=
'2026-03-01'` is a range on the first clustering column, so it is a slice. A condition on `total`
or `status`, which are not in the key at all, is not a stretch of anything: the next section shows
Cassandra refusing it. The order of the clustering columns is therefore a decision about **which ranges the
application will need**, made when the table is created and fixed for its life. Changing it means
a new table and a copy of the data.

That is the shape of the next section. Every question the application asks has to be answerable as
"one partition, then a slice of its sorted rows", and when a question is not, the answer is
another table rather than a cleverer query.
