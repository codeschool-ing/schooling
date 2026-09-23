---
title: What a transaction is, and the one you are already in
version: 2
---

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```

Two statements, one unit. Either both took effect or neither did, and no other connection ever sees
a moment where the money has left one account and not arrived at the other.

Without the `BEGIN` and `COMMIT`, the machine losing power between the two lines destroys a hundred
units of currency. Not misplaces — **destroys**, in a way no code around the statements can repair,
because the first one is already durable and nothing records that a second was owed.

That is the easy half of this lesson and the part everybody knows. The rest of it is about what
happens when somebody else is running their two statements at the same time.

## `ROLLBACK`, which is the other exit

```sql
BEGIN;
DELETE FROM order_lines WHERE order_id = 7;
-- that was the wrong order
ROLLBACK;
```

Nothing happened. The rows are back — or rather they never left, because until a transaction
commits, its changes are visible to nobody else and can be discarded entirely.

This is the safety net lesson 7 kept pointing at. A `DELETE` you are not sure of, run inside a
transaction, is a statement you can look at before agreeing to it:

```sql
BEGIN;
DELETE FROM contacts WHERE id IN (…);
SELECT count(*) FROM contacts;     -- 4 812, and you expected 4 812
COMMIT;
```

Get into the habit while the stakes are low. It costs one word.

## You are always in a transaction

Every statement runs in one. What varies is who opened it:

```sql
UPDATE products SET price = price * 1.1;
```

With **autocommit** on — which is the default in `psql`, in the `mysql` client, and in most drivers
— that statement is wrapped in a transaction of its own, opened before it and committed after. So
it is atomic on its own: a power cut in the middle of a ten-million-row update leaves the table
exactly as it was, not half updated.

Which is worth saying plainly, because people assume the opposite: **a single statement is already
atomic.** You do not need a transaction to make one `UPDATE` safe. You need one to make *two*
statements safe together.

Some drivers turn autocommit off, and then every statement you run opens a transaction that stays
open until you commit — including a `SELECT`, which is how an idle connection ends up holding
something open for four hours. The `long-transactions` section is about what that costs.

## What a transaction is not

**It is not a lock on everything you touched.** Other connections keep working. What they can see
and what they are made to wait for is the subject of the next four sections, and the answer is not
"nothing" and not "everything".

**It is not a way to make a long job safe by wrapping it.** A transaction around a million-row
migration does give you all-or-nothing, and it also holds every lock it has taken for the whole
run, and makes the rows it replaced unreclaimable until it ends. Lesson 3's batched backfill exists
because of this: **atomicity has a cost that grows with how long you hold it.**

**And it is not a substitute for a constraint.** A transaction guarantees your two statements
happen together. It does not check that the result makes sense — that is what `NOT NULL`, `CHECK`
and foreign keys are for, and the next section is about why people expect otherwise.

## Savepoints, for a part of one

```sql
BEGIN;
INSERT INTO orders …;
SAVEPOINT before_lines;
INSERT INTO order_lines …;          -- this one fails
ROLLBACK TO before_lines;           -- undo just that, keep the order
INSERT INTO order_lines …;          -- try again differently
COMMIT;
```

A savepoint is a marker you can roll back to without abandoning the whole transaction. It is how
a driver implements a nested transaction — there is no such thing underneath, and what your
framework calls one is almost always a savepoint.

Worth knowing for one specific reason. In PostgreSQL, **a failed statement poisons the transaction**:

```
ERROR:  current transaction is aborted, commands ignored until end of transaction block
```

Every statement after the error is refused until you roll back. A savepoint before a statement that
might fail is the way to carry on, and it is why an ORM that wants to catch an integrity error and
continue puts one there. MySQL does not behave this way — a failed statement leaves the transaction
usable — which is a real difference between the two and one that application code tends to be
written against without realising.
