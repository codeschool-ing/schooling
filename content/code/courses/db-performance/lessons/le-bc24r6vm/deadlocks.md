---
title: A deadlock, and the order that prevents it
version: 1
---

Everything so far waited and then went ahead, because the transaction being waited for eventually
finished. A **deadlock** is two transactions each waiting for the other, so neither can finish and
waiting would last forever. The common belief is that a deadlock means the database is broken or
overloaded. It means neither. **It is two correct transactions that lock the same rows in opposite
orders**, and PostgreSQL's answer to it is to cancel one of them, which turns a silent hang into an
error your application has to handle.

## Making one

Two windows, each updating orders 1 and 2, in opposite orders. Window A takes order 1, window B
takes order 2, and then window A asks for order 2:

```
market=# BEGIN;
BEGIN
Time: 0.359 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 1.932 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
```

```
market=# BEGIN;
BEGIN
Time: 0.420 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 1.906 ms
```

Window A is waiting for window B, which is an ordinary wait so far. Now window B asks for order 1,
which window A holds:

```
market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
ERROR:  deadlock detected
DETAIL:  Process 8870 waits for ShareLock on transaction 1525089; blocked by process 8868.
Process 8868 waits for ShareLock on transaction 1525090; blocked by process 8870.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (16666,82) in relation "orders"
Time: 1001.015 ms (00:01.001)
```

```
market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 5368.645 ms (00:05.369)
```

Read the error, because it says exactly what happened. **`deadlock detected`**, and the `DETAIL`
names the cycle: process 8870 (window B) waits for transaction 1525089, held by process 8868
(window A), and process 8868 waits for transaction 1525090, held by 8870. A row lock waits on the
**transaction** that holds the row, which is why the lock named is a `ShareLock on transaction`
rather than anything about a row; `CONTEXT` gives the row's physical address in `orders`.

Window B's statement failed after **1001 ms**, and the number is not chance. The server does not
look for cycles on every wait, which would be expensive; a waiting session checks once it has
waited **`deadlock_timeout`**, one second by default. Window B's check found the cycle and cancelled
window B's statement, and its transaction with it. Window A was released the instant window B's
transaction failed and let go of order 2: its update finished after 5369 ms, most of it the wait
before window B even asked. Roll both windows back.

The `HINT` points at the log, which has the half the client is not told, the statement each process
was running:

```
ana@vm:~$ sudo tail -n 8 /var/log/postgresql/postgresql-16-main.log
2026-10-10 17:13:37.345 -03 [8870] ana@market ERROR:  deadlock detected
2026-10-10 17:13:37.345 -03 [8870] ana@market DETAIL:  Process 8870 waits for ShareLock on transaction 1525089; blocked by process 8868.
	Process 8868 waits for ShareLock on transaction 1525090; blocked by process 8870.
	Process 8870: UPDATE orders SET status = 'shipped' WHERE id = 1;
	Process 8868: UPDATE orders SET status = 'shipped' WHERE id = 2;
2026-10-10 17:13:37.345 -03 [8870] ana@market HINT:  See server log for query details.
2026-10-10 17:13:37.345 -03 [8870] ana@market CONTEXT:  while updating tuple (16666,82) in relation "orders"
2026-10-10 17:13:37.345 -03 [8870] ana@market STATEMENT:  UPDATE orders SET status = 'shipped' WHERE id = 1;
```

That log entry is written for every deadlock, whatever the logging settings, and it is the first
place to look when an application reports `deadlock detected`: the two statements, side by side,
usually show the two orders at a glance. Lesson 13 adds the log line for waits that are long but
not deadlocks.

## What the application does with it

A deadlock error is **SQLSTATE 40P01**, and the right response is to **roll back and run the whole
transaction again**. Retrying only the failed statement does not work: the transaction is already
aborted. Lesson 14 writes the retry loop, because a serialisation failure needs exactly the same
one.

Retrying makes a deadlock harmless; it does not make it rare. On a busy table, two transactions
that touch the same pair of rows in opposite orders deadlock whenever they overlap, and each one
costs a second of waiting and a whole transaction thrown away.

## The cure: one order for everybody

A cycle needs two transactions taking the same locks in different orders. **If every transaction
locks the rows it will change in the same order, no cycle can form**: whoever gets the first row
gets them all, and everybody else waits in line. The easy order is the primary key, taken up front
with one `SELECT … ORDER BY id FOR UPDATE`. Window A, which happens to list the ids as `(2, 1)`:

```
market=# BEGIN;
BEGIN
Time: 0.441 ms

market=*# SELECT id FROM orders WHERE id IN (2, 1) ORDER BY id FOR UPDATE;
 id 
----
  1
  2
(2 rows)

Time: 2.020 ms
```

Window B lists them the other way and asks for the same locks:

```
market=# BEGIN;
BEGIN
Time: 0.354 ms

market=*# SELECT id FROM orders WHERE id IN (1, 2) ORDER BY id FOR UPDATE;
```

Window B is waiting for order 1, before it has locked anything, so it holds nothing window A could
need. Window A does its two updates, in whatever order its code likes, and commits:

```
market=*# UPDATE orders SET status = 'shipped' WHERE id = 2;
UPDATE 1
Time: 0.854 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 0.476 ms

market=*# COMMIT;
COMMIT
Time: 1.211 ms
```

```
market=*# SELECT id FROM orders WHERE id IN (1, 2) ORDER BY id FOR UPDATE;
 id 
----
  1
  2
(2 rows)

Time: 5471.529 ms (00:05.472)
```

**Window B waited 5472 ms and got both rows. No deadlock, no error, nothing thrown away.** The `ORDER
BY id` is the whole fix: the `IN` list's order does not matter, because the rows are locked in the
order of the result. An `UPDATE … WHERE id IN (…)` with no `SELECT` before it gives no such
guarantee, since the order it reaches the rows in is whatever its plan happens to read them in.

Three habits come out of this:

- **Lock what you will change, in a fixed order, at the start** — by primary key, or by any rule
  every code path follows.
- **Keep the transaction short**, so the window in which two of them overlap is small.
- **Handle 40P01 anyway**, because some orders cannot be fixed: a foreign key check locks a parent
  row you never named.

## Before lesson 13

This lesson changed some orders: order 1 is `shipped` and three orders are `packing` for good. Close
every window and put `market` back with `~/reset-market.sh`, as at the end of lesson 11.
