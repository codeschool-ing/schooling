---
title: One order, two tables, in Cassandra
version: 1
---

In Cassandra the copy is not a field, it is **a whole table**. Lesson 3 designed one table per
question, and two questions about orders, "show order 1001" and "Ana's orders, newest first", start
from different keys. So every order is written twice: once into `orders_by_id`, partitioned by the
order number, and once into `orders_by_customer`, partitioned by the customer.

## A logged batch

Two separate `INSERT` statements would work until the day the application dies between them, and
then one table has the order and the other does not. A **logged batch** groups them:

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> USE shop;
cqlsh:shop> CREATE TABLE orders_by_id (order_id int PRIMARY KEY, customer text, ordered_at timestamp, total decimal);
cqlsh:shop> CREATE TABLE orders_by_customer (customer text, ordered_at timestamp, order_id int, total decimal, PRIMARY KEY ((customer), ordered_at, order_id)) WITH CLUSTERING ORDER BY (ordered_at DESC, order_id ASC);
cqlsh:shop> BEGIN BATCH INSERT INTO orders_by_id (order_id, customer, ordered_at, total) VALUES (1001, 'ana@example.com', '2026-09-14 10:22:00-0300', 268.80); INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 1001, 268.80); APPLY BATCH;
cqlsh:shop> SELECT * FROM orders_by_id WHERE order_id = 1001;

 order_id | customer        | ordered_at                      | total
----------+-----------------+---------------------------------+--------
     1001 | ana@example.com | 2026-09-14 13:22:00.000000+0000 | 268.80

(1 rows)
cqlsh:shop> SELECT * FROM orders_by_customer WHERE customer = 'ana@example.com';

 customer        | ordered_at                      | order_id | total
-----------------+---------------------------------+----------+--------
 ana@example.com | 2026-09-14 13:22:00.000000+0000 |     1001 | 268.80

(1 rows)
cqlsh:shop> exit
```

`BEGIN BATCH ... APPLY BATCH` wrapped the two inserts, and each table answered its own question with
the same order. The batch was typed on one line here; across several lines works the same.

## What a logged batch promises

The coordinator, the node that received the batch, first writes the whole batch to a **batch log**
on other nodes, then applies each statement, then deletes the log entry. If the coordinator dies
halfway, another node finds the log entry and replays it. So the promise is:

- **all or nothing, eventually.** Either every statement in the batch is applied, or, if the
  coordinator failed, the batch log applies the rest later.

And what it does not promise, which matters as much:

- **no isolation.** A reader can see the order in `orders_by_id` before it appears in
  `orders_by_customer`. The two writes are not one moment.
- **no speed.** Writing the batch log first is an extra round of writes, so a logged batch is slower
  than the two inserts on their own. A batch is a tool for atomicity across tables, never for
  loading many rows faster.
- **no rollback.** If a statement is invalid the whole batch is refused up front; once accepted, it
  is applied, not undone.

On one node with one copy, as here, there is no second node to take over from a failed
coordinator, so the lab cannot show the replay happening. **This lesson describes it and does not demonstrate it**; lesson 17 has
the three-node cluster where a coordinator can fail.

## A batch is not a transaction

The difference shows the moment a write has to be conditional. Bruno's order should be inserted
only if order 1002 does not exist yet, in both tables:

```
ana@vm:~$ docker exec -it cassandra cqlsh -k shop
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh:shop> BEGIN BATCH INSERT INTO orders_by_id (order_id, customer, ordered_at, total) VALUES (1002, 'bruno@example.com', '2026-09-15 14:05:00-0300', 1499.00) IF NOT EXISTS; INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('bruno@example.com', '2026-09-15 14:05:00-0300', 1002, 1499.00) IF NOT EXISTS; APPLY BATCH;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Batch with conditions cannot span multiple tables"
cqlsh:shop> exit
```

`Batch with conditions cannot span multiple tables`. A condition, `IF NOT EXISTS`, is a lightweight
transaction, and Cassandra can run one only against a single partition of a single table; lesson 17
covers what it costs. So "insert this order exactly once, in both places" is two steps: a
conditional insert into the table that owns the identity, `orders_by_id`, and then, if it
succeeded, an ordinary batch or write into the copy.

The general shape is worth keeping: **one table is the source of truth for a fact, and the others are
copies written after it.** When they disagree, the source wins and the copy is rewritten from it.
