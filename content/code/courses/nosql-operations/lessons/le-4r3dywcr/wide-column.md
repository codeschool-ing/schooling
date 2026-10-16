---
title: A wide-column store, Cassandra
version: 1
---

The name misleads twice. "Wide column" sounds like a table with a great many columns, and it sounds
like the column-oriented storage of analytics engines, which keep each column of a table in its own
file. **It is neither.** A wide-column store groups rows into partitions by a key, keeps the rows of
one partition together and sorted, and answers questions about one partition at a time. A partition
can grow to thousands of rows, and that row of rows is the "wide" in the name.

## A keyspace, a table, and order 1001

In Cassandra a keyspace holds tables, and it is where the number of copies is set. With one node
there can only be one copy, so the keyspace below asks for one; lesson 17 is about choosing more.

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> USE shop;
cqlsh:shop> CREATE TABLE order_lines_by_customer (customer text, ordered_at timestamp, sku text, order_id int, name text, qty int, unit_price decimal, PRIMARY KEY ((customer), ordered_at, sku));
cqlsh:shop> INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 'CB-012', 1001, 'USB-C cable', 2, 39.90);
cqlsh:shop> INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 'MS-204', 1001, 'Wireless mouse', 1, 189.00);
cqlsh:shop> INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('ana@example.com', '2026-08-02 19:40:00-0300', 'KB-101', 987, 'Mechanical keyboard', 1, 349.90);
cqlsh:shop> INSERT INTO order_lines_by_customer (customer, ordered_at, sku, order_id, name, qty, unit_price) VALUES ('bruno@example.com', '2026-09-15 14:05:00-0300', 'MN-330', 1002, '27-inch monitor', 1, 1499.00);
cqlsh:shop> SELECT ordered_at, sku, order_id, qty, unit_price FROM order_lines_by_customer WHERE customer = 'ana@example.com';

 ordered_at                      | sku    | order_id | qty | unit_price
---------------------------------+--------+----------+-----+------------
 2026-08-02 22:40:00.000000+0000 | KB-101 |      987 |   1 |     349.90
 2026-09-14 13:22:00.000000+0000 | CB-012 |     1001 |   2 |      39.90
 2026-09-14 13:22:00.000000+0000 | MS-204 |     1001 |   1 |     189.00

(3 rows)
cqlsh:shop> SELECT customer, sku, unit_price FROM order_lines_by_customer WHERE unit_price > 500;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
cqlsh:shop> SELECT customer, sku, unit_price FROM order_lines_by_customer WHERE unit_price > 500 ALLOW FILTERING;

 customer          | sku    | unit_price
-------------------+--------+------------
 bruno@example.com | MN-330 |    1499.00

(1 rows)
cqlsh:shop> exit
```

The primary key is the important line of the `CREATE TABLE`, and its parentheses carry the design:

- **`(customer)` is the partition key.** It decides which node holds the rows, and every row for
  `ana@example.com` lives in the same partition, on the same nodes.
- **`ordered_at, sku` are the clustering columns.** They decide the order of the rows inside the
  partition, and together with the partition key they make a row unique.

So Ana's order 1001 is two rows, one per line, and her earlier order for the keyboard is a third.
The `SELECT` for her partition returned all three **already sorted by date**, the August keyboard
first, with no `ORDER BY`, because that is the order they are stored in. The times come back in
UTC: 10:22 at `-0300` is 13:22 at `+0000`.

## The question the table was not built for

The lines priced over 500 are spread across partitions, and the only way to find them is to read
every partition. **Cassandra refuses to do that unless told to**, and the message says why:
the query "might involve data filtering and thus may have unpredictable performance". Adding
`ALLOW FILTERING` makes it run, and on four rows in one node it is instant. On a cluster holding
millions of partitions the same statement reads all of them, on every node, to return a handful.

The refusal is the design speaking. A relational database would have run the query and been slow;
Cassandra makes you say out loud that you meant to scan. The ordinary answer is not
`ALLOW FILTERING` but **a second table whose partition key is the question**, written at the same
time as the first. Lesson 3 designs tables that way and lesson 4 keeps them in step.

## What this shape is for

Writes in Cassandra are cheap and spread across nodes by the partition key, and a read of one
partition is one sorted slice of one node's data. That suits data written far more than it is read
in new ways: orders by customer, readings by sensor, events by account. The total of order 1001 is
not stored anywhere in this table; adding up its two rows is the application's job, or a third
column written with them.

Cassandra is the wide-column store this course operates. ScyllaDB speaks the same CQL, and HBase and
Google's Bigtable are the same family under different interfaces.
