---
title: Repeatable read, and the error instead of the loss
version: 1
---

`REPEATABLE READ` changes one thing about what a transaction sees, and the change has a
consequence most people meet first as an error message. **The transaction takes one snapshot, at
its first statement, and every statement in it reads from that snapshot.** Nothing committed by
anybody else afterwards is visible to it, however many times it asks.

The common expectation is that the higher level makes the second writer wait and then do the
right thing. It does not wait its way out. **If a `REPEATABLE READ` transaction tries to change a
row somebody else changed after its snapshot, it fails**, and the application has to run it again.

## Read committed sees the change

First the default, for comparison. In window A, start a transaction and read product 2's price:

```
market=# BEGIN;
BEGIN
Time: 0.340 ms

market=*# SELECT price_cents FROM products WHERE id = 2;
 price_cents 
-------------
       21990
(1 row)

Time: 1.346 ms
```

In window B, raise it by 100, outside any explicit transaction, so that it commits at once:

```
market=# UPDATE products SET price_cents = price_cents + 100 WHERE id = 2;
UPDATE 1
Time: 2.626 ms
```

Back in window A, same transaction, same query:

```
market=*# SELECT price_cents FROM products WHERE id = 2;
 price_cents 
-------------
       22090
(1 row)

Time: 0.521 ms

market=*# COMMIT;
COMMIT
Time: 0.499 ms
```

**21990, then 22090**, inside one transaction. That is the **non-repeatable read** the level is
named after: in `READ COMMITTED` each statement takes a fresh view, so a report that reads a total
in one query and the detail in the next can find that they do not add up.

## Repeatable read does not

Now window A starts a `REPEATABLE READ` transaction:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.372 ms

market=*# SELECT price_cents FROM products WHERE id = 2;
 price_cents 
-------------
       22090
(1 row)

Time: 0.614 ms
```

Window B raises the price again:

```
market=# UPDATE products SET price_cents = price_cents + 100 WHERE id = 2;
UPDATE 1
Time: 2.034 ms
```

And window A reads it, then tries to raise it too:

```
market=*# SELECT price_cents FROM products WHERE id = 2;
 price_cents 
-------------
       22090
(1 row)

Time: 0.431 ms

market=*# UPDATE products SET price_cents = price_cents + 100 WHERE id = 2;
ERROR:  could not serialize access due to concurrent update
Time: 0.856 ms

market=!# ROLLBACK;
ROLLBACK
Time: 0.381 ms
```

The second `SELECT` still says **22090**: the snapshot was taken at window A's first query, and
window B's commit came after it. That is what makes the level useful for reports, exports and
anything that reads several tables and needs them to agree with each other.

Then the `UPDATE` failed with **`could not serialize access due to concurrent update`**. Window A
was about to add 100 to a row whose current version it cannot see. In `READ COMMITTED` the update
would have waited, re-read the row and gone ahead, as section 02 of this lesson showed; in
`REPEATABLE READ` the server refuses, because going ahead would mean writing on top of a change the
transaction never saw, which is exactly the lost update. The transaction is now failed, and the
only thing left to do with it is `ROLLBACK`.

**The error is the protection.** The application gets SQLSTATE **40001**, rolls back, and runs the
whole transaction again from the start, this time with a snapshot that includes window B's change.

## The workload again

The same `price-bump.sql`, ten seconds, eight clients, with every transaction in `REPEATABLE READ`.
pgbench takes no option for the level, so it is set for each connection through `PGOPTIONS`, which
passes a setting to the server when the connection opens; the backslash keeps the space in
`repeatable read` from ending the value:

```
market=# SELECT sum(price_cents) AS before FROM products WHERE id <= 10 \gset
Time: 1.602 ms

market=# \! PGOPTIONS='-c default_transaction_isolation=repeatable\ read' pgbench -n -c 8 -j 4 -T 10  -f ~/workload/price-bump.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: /home/ana/workload/price-bump.sql
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 10 s
number of transactions actually processed: 49741
number of failed transactions: 28848 (36.707%)
latency average = 1.018 ms (including failures)
initial connection time = 11.943 ms
tps = 4974.825330 (without initial connection time)

market=# SELECT sum(price_cents) - :before AS cents_added FROM products WHERE id <= 10;
 cents_added 
-------------
       49741
(1 row)

Time: 0.603 ms
```

Read the three numbers together. **49,741 transactions committed, and the prices rose by exactly
49,741 cents: nothing was lost.** And **28,848 transactions, 36.7%, failed**: each was a read-then-
write that lost the race for its row and was refused rather than allowed to overwrite. pgbench was
told to try each one once, so those failures are simply counted; an application that does nothing
with the error would show its users an error for one request in three.

So the level trades a silent wrong answer for a loud failure. **That is the right trade**, and it
is only finished when something retries, which is section 05 of this lesson.

## What it does not catch

`REPEATABLE READ` refuses to overwrite a row changed since the snapshot. It does not notice two
transactions that each read something, decide from it, and then write **different** rows. Neither
overwrote the other, so neither is refused, and the rule they each checked can still end up broken.
The next section builds that case with two orders.
