---
title: Write the query first
version: 1
---

In a relational database you model the data and then write whatever queries you like against it;
an index or a join will cover the ones you did not foresee. **Cassandra reverses the order.** You
list the queries first, and each table is the answer to one of them, shaped so that the query names
a partition and reads a slice. Lesson 3 argued this for every store in the course. Here the
database enforces it, and the refusals are worth seeing in full.

## The refusals

`orders_by_customer` answers "a customer's orders, newest first". Ask it anything else:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT order_id, customer FROM shop.orders_by_customer WHERE ordered_at >= '2026-04-01';
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
cqlsh> SELECT order_id, customer FROM shop.orders_by_customer WHERE status = 'shipped';
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
cqlsh> SELECT order_id, customer FROM shop.orders_by_customer ORDER BY ordered_at;
InvalidRequest: Error from server: code=2200 [Invalid query] message="ORDER BY is only supported when the partition key is restricted by an EQ or an IN."
cqlsh> SELECT order_id, customer FROM shop.orders_by_customer WHERE status = 'shipped' ALLOW FILTERING;

 order_id | customer
----------+-------------------
   A-1007 | bruno@example.com
   A-1006 |   ana@example.com
   A-1005 | diego@example.com

(3 rows)
cqlsh> exit
```

Three refusals, and they are three faces of one rule. A range on `ordered_at` without the
customer, and a condition on `status`, would each have to read **every partition on every node** to
find the rows, so Cassandra refuses with the sentence about `ALLOW FILTERING`. An `ORDER BY` with no
partition named has no single sorted partition to read in order, and is refused for that.

`ALLOW FILTERING` makes the query run, and it gave the right three rows. **The refusal was not about
correctness.** It was about cost, and the cost is invisible with eight orders. Tracing shows it.
Each command below asks `cqlsh` to trace one query and counts, with `grep` and `uniq -c`, the lines
of the trace that say how the coordinator, `c1`, reached the data:

```
ana@vm:~$ docker exec c1 cqlsh -e "TRACING ON; SELECT order_id FROM shop.orders_by_customer WHERE customer = 'ana@example.com';" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c
      1 Executing single-partition query on orders_by_customer
      1 Sending READ_REQ message to /172.18.0.3:7000
ana@vm:~$ docker exec c1 cqlsh -e "TRACING ON; SELECT order_id FROM shop.orders_by_customer WHERE status = 'shipped' ALLOW FILTERING;" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c
     13 Sending RANGE_REQ message to /172.18.0.3:7000
     17 Sending RANGE_REQ message to /172.18.0.4:7000
      1 Submitting range requests on 49 ranges
```

The query that names Ana is **one single-partition read**, sent to `172.18.0.3`, which is `c2`, the
node `getendpoints` named. The filtering query split the whole ring into **49 ranges** and sent 13
range requests to `c2` and 17 to `c3`; the rest it read locally. With eight orders each request
found almost nothing. With eighty million, each of those requests scans its share of the table, and
the query's cost grows with the size of the table rather than with the size of the answer.
`ALLOW FILTERING` is acceptable when you know the partition is small or the table is tiny. In an
application's main path it is the slow query of next year.

## An index, and SAI in particular

Cassandra 5.0 ships **Storage-Attached Indexing**, SAI, a secondary index stored beside each
SSTable rather than in a hidden table of its own. It makes `status = 'shipped'` a legal query:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE INDEX orders_status ON shop.orders_by_customer (status) USING 'sai';
cqlsh> SELECT order_id, customer FROM shop.orders_by_customer WHERE status = 'shipped';

 order_id | customer
----------+-------------------
   A-1007 | bruno@example.com
   A-1006 |   ana@example.com
   A-1005 | diego@example.com

(3 rows)
cqlsh> exit
ana@vm:~$ docker exec c1 cqlsh -e "TRACING ON; SELECT order_id FROM shop.orders_by_customer WHERE status = 'shipped';" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c
      3 Executing single-partition query on orders_by_customer
     13 Sending RANGE_REQ message to /172.18.0.3:7000
     17 Sending RANGE_REQ message to /172.18.0.4:7000
      1 Submitting range requests on 49 ranges
```

The query now runs with no `ALLOW FILTERING`, and each node finds its matching rows from the index
instead of scanning: the three single-partition reads in the trace are the three orders it found.
**But the coordinator still split the ring into 49 ranges and still asked every node.** A
secondary index is local to each node, so a query by `status` cannot know in advance which node
holds a shipped order; it has to ask them all. SAI makes each node's part of the work cheaper. It
does not change how many nodes are asked, and that is why it does not change the modelling rule.

SAI is the right tool for a query that is occasional, or that always names the partition key as
well, such as "Ana's shipped orders", where the index narrows the rows inside one partition. It is
the wrong foundation for the busiest query of an application, which should read one partition.

## One table per query

The warehouse asks a different question from the account page: "every order placed on a given
day", in the order they arrived. That is a partition per day, sorted by time. Save this as
`days.cql`:

```sql
CREATE TABLE shop.orders_by_day (
  day        date,
  ordered_at timestamp,
  order_id   text,
  customer   text,
  total      decimal,
  PRIMARY KEY (day, ordered_at, order_id)
);

INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-03-02', '2026-03-02 13:15:00+0000', 'A-1001', 'ana@example.com',    349.90);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-03-02', '2026-03-02 15:40:00+0000', 'A-1002', 'bruno@example.com', 1499.00);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-03-02', '2026-03-02 19:05:00+0000', 'A-1003', 'carla@example.com',   39.90);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-03-20', '2026-03-20 00:02:00+0000', 'A-1004', 'ana@example.com',    189.00);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-03-20', '2026-03-20 11:20:00+0000', 'A-1005', 'diego@example.com',  349.90);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-04-08', '2026-04-08 12:30:00+0000', 'A-1006', 'ana@example.com',   1499.00);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-04-08', '2026-04-08 14:10:00+0000', 'A-1007', 'bruno@example.com',   39.90);
INSERT INTO shop.orders_by_day (day, ordered_at, order_id, customer, total) VALUES ('2026-04-09', '2026-04-09 09:45:00+0000', 'A-1008', 'elisa@example.com',  189.00);
```

```
ana@vm:~$ docker exec -i c1 cqlsh < days.cql
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT ordered_at, order_id, customer, total FROM shop.orders_by_day WHERE day = '2026-03-02';

 ordered_at                      | order_id | customer          | total
---------------------------------+----------+-------------------+---------
 2026-03-02 13:15:00.000000+0000 |   A-1001 |   ana@example.com |  349.90
 2026-03-02 15:40:00.000000+0000 |   A-1002 | bruno@example.com | 1499.00
 2026-03-02 19:05:00.000000+0000 |   A-1003 | carla@example.com |   39.90

(3 rows)
cqlsh> exit
ana@vm:~$ docker exec c1 cqlsh -e "TRACING ON; SELECT order_id FROM shop.orders_by_day WHERE day = '2026-03-02';" | grep -oE 'Executing single-partition query on [a-z_]+|Submitting range requests on [0-9]+ ranges|Sending [A-Z_]+ message to /[0-9.:]+' | sort | uniq -c
      1 Executing single-partition query on orders_by_day
```

**One partition, and this time the trace has no `Sending` line at all**: the partition for
`2026-03-02` lives on `c1`, the coordinator itself, so the read never left the node. The same eight
orders are now stored twice, once per question, and that is the design rather than a compromise.
The price is that every order placed has to be written to both tables, which lesson 4 called
writing the same data twice deliberately and lesson 5 showed can leave the two copies briefly
disagreeing.

The method, then, as a list you can apply to any new feature:

1. Write down each query the screen or the job will run, with its parameters.
2. For each, the parameter that is always given with `=` becomes the partition key.
3. What the query sorts or ranges on becomes the clustering columns, in that order.
4. Add whatever makes a row unique as the last clustering column.
5. Check the partition cannot grow without bound, which is the next section.
