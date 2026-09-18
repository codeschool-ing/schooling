---
title: A write does not rerun, and that is the whole difference
version: 1
---

A `SELECT` with a bug in it costs nothing. You read the result, see that it is wrong, fix the
condition and run it again — and the database is exactly as it was before you started. Lessons 4 to
7 were written in that key, which is why you could learn them by experimenting.

Here is the same bug in an `UPDATE`:

```
shop=# SELECT sku, price FROM products;
  sku   |  price  
--------+---------
 KB-101 |  349.90
 MS-204 |  189.00
 MN-330 | 1499.00
 CB-012 |   39.90
(4 rows)

shop=# UPDATE products SET price = price * 1.10;
UPDATE 4

shop=# SELECT sku, price FROM products;
  sku   |  price  
--------+---------
 KB-101 |  384.89
 MS-204 |  207.90
 MN-330 | 1648.90
 CB-012 |   43.89
(4 rows)
```

No error. No warning. Nothing in that output says a `WHERE` is missing, because nothing is wrong
with the statement — `UPDATE 4` is a true and complete report that four rows changed, which is what
was asked for. The old prices are not recoverable from anything on this page.

**A write does not rerun.** Fixing the statement and running the correct one does not undo the
first: the catalogue is now ten per cent higher and one product is also correctly repriced. Two
mistakes where a `SELECT` would have left none.

## Write the `WHERE` first, as a `SELECT`

The habit costs one statement and it is the cheapest insurance in this course:

```
shop=# SELECT id, status FROM orders WHERE customer_id = 1 AND status = 'placed';
 id | status 
----+--------
  1 | placed
  3 | placed
  4 | placed
(3 rows)

shop=# UPDATE orders SET status = 'cancelled' WHERE customer_id = 1 AND status = 'placed';
UPDATE 3
```

Three rows, and you saw which three before anything moved. The `SELECT` is the proof that the
condition means what you believe it means — and it catches the whole class of errors lesson 4 spent
a section on, where `city <> 'Recife'` quietly drops everybody whose city is `NULL`.

Then change the verb and nothing else. The moment you retype the condition is the moment it stops
being the condition you checked.

## Read the count

`UPDATE 3` against three rows you had just counted is a confirmation. `UPDATE 4812` is a sentence
telling you something is wrong **while you can still do something about it**, and it costs nothing
to look at.

**Know the number before you press return, and read the number that comes back.** Most write
accidents are somebody who knew neither.

## `RETURNING` when the count is not enough

**A count says how many. `RETURNING` says which:**

```
shop=# UPDATE products SET price = price * 1.10 WHERE sku = 'KB-101' RETURNING sku, price;
  sku   | price  
--------+--------
 KB-101 | 384.89
(1 row)

UPDATE 1
```

One statement, one pass, and the rows as they now are rather than as you hope they are. It works on
all three statements, and it is the honest way to log what a job did.

It is not everywhere. MySQL has no `RETURNING` at all, MariaDB has it for `INSERT` and `DELETE`,
and lesson 12 is where those differences live. Where it is missing, the count is what you have.

## And none of that undoes anything

Everything in this section is care taken **before** the fact: check the condition, read the number,
ask for the rows back. All of it helps and none of it is a way out, because by the time you can see
that `UPDATE 4812` the four thousand eight hundred and twelve rows have changed.

Lesson 4 promised that this lesson was the right place for these three statements, and this is the
reason: the thing that makes a write recoverable is not a habit, it is a transaction, and that is
the rest of the lesson.
