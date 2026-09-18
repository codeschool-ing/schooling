---
title: The part that is the same everywhere
version: 1
---

Before the differences, the thing they rest on: **almost everything this course has taught runs
unchanged on all four engines.** That is not a courtesy. It is the reason the eleven lessons
before this one were worth writing as a subject rather than as a manual.

Here is a report against the shop — three tables, a join, a filter, an aggregate and a sort. The
same text, sent to three engines:

```
shop=# SELECT c.city, count(DISTINCT o.id) AS orders, sum(l.quantity * l.unit_price) AS revenue FROM customers c JOIN orders o ON o.customer_id = c.id JOIN order_lines l ON l.order_id = o.id WHERE o.status <> 'cancelled' GROUP BY c.city ORDER BY revenue DESC;
   city    | orders | revenue 
-----------+--------+---------
 Curitiba  |      1 | 2998.00
 Recife    |      2 | 1928.70
 Sao Paulo |      1 |  228.90
(3 rows)
```

```
mysql> SELECT c.city, count(DISTINCT o.id) AS orders, sum(l.quantity * l.unit_price) AS revenue FROM customers c JOIN orders o ON o.customer_id = c.id JOIN order_lines l ON l.order_id = o.id WHERE o.status <> 'cancelled' GROUP BY c.city ORDER BY revenue DESC;
+-----------+--------+---------+
| city      | orders | revenue |
+-----------+--------+---------+
| Curitiba  |      1 | 2998.00 |
| Recife    |      2 | 1928.70 |
| Sao Paulo |      1 |  228.90 |
+-----------+--------+---------+
```

```
sqlite> SELECT c.city, count(DISTINCT o.id) AS orders, sum(l.quantity * l.unit_price) AS revenue FROM customers c JOIN orders o ON o.customer_id = c.id JOIN order_lines l ON l.order_id = o.id WHERE o.status <> 'cancelled' GROUP BY c.city ORDER BY revenue DESC;
city       orders  revenue
---------  ------  -------
Curitiba   1       2998   
Recife     2       1928.7 
Sao Paulo  1       228.9  
```

Same rows, same order, same counts. The frames around them are the clients' — `psql` draws a rule
under the headings, the MySQL client draws a box, the SQLite shell draws neither unless you ask —
and none of that is the database.

## What is portable, and it is most of it

| lesson | what carries over |
|---|---|
| 1, 2 | the relational model, keys, normalisation. Not an engine feature at all |
| 3 | `CREATE TABLE`, `NOT NULL`, `UNIQUE`, `PRIMARY KEY`, `FOREIGN KEY`, `CHECK` |
| 4 | `SELECT`, `WHERE`, `ORDER BY`, `LIMIT` |
| 5 | `INNER`, `LEFT` and `CROSS JOIN` |
| 6 | the aggregates, `GROUP BY`, `HAVING`, and window functions on all four |
| 7 | subqueries, `EXISTS`, `WITH`, views |
| 8 | `BEGIN`, `COMMIT`, `ROLLBACK`, and the anomalies the isolation levels are named for |
| 9 | `CREATE INDEX`, the leftmost prefix, why a function on a column defeats one |
| 10 | that there is a plan, and that you read it before you change anything |

Window functions are the newest item on that list and the one worth dating, because the internet
still carries advice from before they arrived: SQLite has had them since 3.25 in 2018, MySQL since
8.0 in 2018, MariaDB since 10.2 in 2017. PostgreSQL has had them since 2009. On any version
somebody installs today, all four have them.

## So what is left

The differences fall into four groups, and the rest of the lesson is one section each:

**What the engine refuses.** The same `INSERT` is an error on one and a stored row on another.
This is the largest gap of the four and it is not close.

**How text is compared.** Whether `'ANA@EXAMPLE.COM'` finds `ana@example.com` is an engine
default, and it decides whether a `UNIQUE` constraint on an address means what you think.

**The dialect.** Small syntax: how a key auto-numbers, what `||` does, what `5 / 2` is, whether
`RETURNING` exists.

**How it is run.** Replication, backup, upgrades and who is on call — which is what actually
decides an engine in a company, and has nothing to do with SQL.

Lesson 10 already covered the fifth group, `EXPLAIN`, which reads differently on each of the
three servers and has a section of its own there. This lesson does not repeat it.
