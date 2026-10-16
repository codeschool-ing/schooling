---
title: One query, one table, in Cassandra
version: 1
---

In Cassandra the method of this lesson stops being advice. **A query must name a partition**, so a
table is only useful for the questions whose partition key the application already has, and the
habit is to design one table per question and name it after the question. Row 4 of the list, "my
orders, newest first, ten at a time", becomes `orders_by_customer`.

## From the question to the key

Read the row left to right and the primary key falls out of it:

- the application knows **the customer**, so the customer is the partition key, and all her orders
  live together;
- it wants them **newest first**, so the order date is a clustering column, stored descending;
- it wants **ten at a time**, so the query is `LIMIT` on a partition that is already in order.

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> USE shop;
cqlsh:shop> CREATE TABLE orders_by_customer (customer text, ordered_at timestamp, order_id int, total decimal, PRIMARY KEY ((customer), ordered_at)) WITH CLUSTERING ORDER BY (ordered_at DESC);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-08-02 19:40:00-0300', 987, 349.90);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-09-14 10:22:00-0300', 1001, 268.80);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1013, 1499.00);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('bruno@example.com', '2026-09-15 14:05:00-0300', 1002, 1499.00);
cqlsh:shop> SELECT ordered_at, order_id, total FROM orders_by_customer WHERE customer = 'ana@example.com' LIMIT 2;

 ordered_at                      | order_id | total
---------------------------------+----------+---------
 2026-10-03 12:15:00.000000+0000 |     1013 | 1499.00
 2026-09-14 13:22:00.000000+0000 |     1001 |  268.80

(2 rows)
cqlsh:shop> SELECT customer, order_id FROM orders_by_customer ORDER BY ordered_at DESC LIMIT 3;
InvalidRequest: Error from server: code=2200 [Invalid query] message="ORDER BY is only supported when the partition key is restricted by an EQ or an IN."
cqlsh:shop> exit
```

`WITH CLUSTERING ORDER BY (ordered_at DESC)` is the part of the design that answers "newest first".
The rows of Ana's partition are stored with October's order on top, so `LIMIT 2` took the first two
rows and stopped. Nothing was sorted when the query ran, and Bruno's partition was never opened:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 215\" role=\"img\" aria-label=\"Two partitions of orders_by_customer. Ana's partition holds her three orders stored newest first: 1013 in October, 1001 in September, 987 in August. A query naming Ana with LIMIT 2 reads the top two rows of that partition and stops. Bruno's partition, with order 1002, is never read.\"><defs><marker id=\"obc3-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition</text><rect x=\"30\" y=\"32\" width=\"240\" height=\"170\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">ana@example.com</text><rect x=\"42\" y=\"66\" width=\"216\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"52\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">2026-10-03</text><text x=\"150\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1013</text><text x=\"248\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1499.00</text><rect x=\"42\" y=\"108\" width=\"216\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"52\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">2026-09-14</text><text x=\"150\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1001</text><text x=\"248\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">268.80</text><rect x=\"42\" y=\"150\" width=\"216\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">2026-08-02</text><text x=\"150\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">987</text><text x=\"248\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">349.90</text><line x1=\"290\" y1=\"160\" x2=\"290\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#obc3-ah-paper-dim)\"></line><text x=\"298\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">newest</text><text x=\"298\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">oldest</text><line x1=\"360\" y1=\"66\" x2=\"372\" y2=\"66\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"372\" y1=\"66\" x2=\"372\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><line x1=\"360\" y1=\"140\" x2=\"372\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"380\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">LIMIT 2 reads these</text><text x=\"580\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition</text><rect x=\"480\" y=\"32\" width=\"200\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"580\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bruno@example.com</text><rect x=\"492\" y=\"66\" width=\"176\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"502\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2026-09-15</text><text x=\"658\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">1002</text><text x=\"580\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">never read</text></svg>", "caption": "\"My orders\" is the top of one partition. The rows are already in the order the page shows them, so the query reads two rows and touches nothing else."}
```

The second `SELECT` asks the question this table was not designed for, every customer's orders
newest first, and Cassandra refuses it: `ORDER BY is only supported when the partition key is
restricted by an EQ or an IN`. **Order exists inside a partition and nowhere else.** Sorting across
partitions would mean reading all of them, on every node, which is row 6's kind of question, and it
needs a different structure.

## The key that loses an order

The design above has a defect that no test with three tidy orders shows. On 3 October Ana places a
second order in the same instant as the monitor, a cable bought from another tab, and the shop writes
it:

```
ana@vm:~$ docker exec -it cassandra cqlsh -k shop
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1014, 39.90);
cqlsh:shop> SELECT ordered_at, order_id, total FROM orders_by_customer WHERE customer = 'ana@example.com';

 ordered_at                      | order_id | total
---------------------------------+----------+--------
 2026-10-03 12:15:00.000000+0000 |     1014 |  39.90
 2026-09-14 13:22:00.000000+0000 |     1001 | 268.80
 2026-08-02 22:40:00.000000+0000 |      987 | 349.90

(3 rows)
cqlsh:shop> DROP TABLE orders_by_customer;
cqlsh:shop> CREATE TABLE orders_by_customer (customer text, ordered_at timestamp, order_id int, total decimal, PRIMARY KEY ((customer), ordered_at, order_id)) WITH CLUSTERING ORDER BY (ordered_at DESC, order_id ASC);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1013, 1499.00);
cqlsh:shop> INSERT INTO orders_by_customer (customer, ordered_at, order_id, total) VALUES ('ana@example.com', '2026-10-03 09:15:00-0300', 1014, 39.90);
cqlsh:shop> SELECT ordered_at, order_id, total FROM orders_by_customer WHERE customer = 'ana@example.com';

 ordered_at                      | order_id | total
---------------------------------+----------+---------
 2026-10-03 12:15:00.000000+0000 |     1013 | 1499.00
 2026-10-03 12:15:00.000000+0000 |     1014 |   39.90

(2 rows)
cqlsh:shop> exit
```

The first `SELECT` shows three rows, not four. **Order 1013, the monitor, is gone**, replaced by 1014
without an error. A primary key in Cassandra is the identity of a row, and an `INSERT` for a key that
already exists overwrites it. There is no duplicate-key check, because checking would mean reading
before every write, and the write path is built to avoid exactly that. Two orders with the same
customer and the same timestamp had the same key.

The fix is to make the key say what makes a row unique. With `order_id` added as a second clustering
column, the partition still sorts by date, newest first, and two orders in the same instant are two
rows, as the last `SELECT` shows. Changing a primary key means a new table, which is why the
`DROP TABLE` and `CREATE TABLE` are there; on a table holding real data it means copying every row
across, the subject of lesson 4.

**The rule to keep**: the partition key is what the query names, the clustering columns are the
order it wants, and the whole primary key is what makes one row different from every other. Lesson 16
comes back to all three with a cluster under them.
