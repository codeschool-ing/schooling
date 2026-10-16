---
title: Cancel or terminate, and what each does to the victim
version: 1
---

The tree names the root. Two functions act on a session by its process id, and the difference
between them is the difference between a fix and a surprise:

| function | what it does to the session |
|---|---|
| `pg_cancel_backend(pid)` | stops the statement it is **running** now; the connection stays |
| `pg_terminate_backend(pid)` | ends the **connection**; any open transaction is rolled back |

The common mistake is to reach for the gentle one first, on the root, and conclude it did not work.
It did exactly what it says. **The root in most lock incidents is not running anything**, so there
is nothing to cancel.

## Cancelling an idle session

The root is window A, 5792, idle in transaction. In window D:

```
market=# SELECT pg_cancel_backend(5792);
 pg_cancel_backend 
-------------------
 t
(1 row)

Time: 0.543 ms

market=# \i ~/lock-tree.sql
    pid     |        state        | in_transaction |                  last_query                   
------------+---------------------+----------------+-----------------------------------------------
 5792       | idle in transaction | 00:00:35       | UPDATE orders SET status = 'shipped' WHERE id
    5794    | active              | 00:00:34       | UPDATE orders SET status = 'shipped' WHERE id
       5796 | active              | 00:00:29       | UPDATE orders SET status = 'cancelled' WHERE 
(3 rows)

Time: 2.566 ms
```

`pg_cancel_backend` answered `t`, which means only that the signal was sent. The tree is unchanged,
34 seconds became 35, and window A is still the root. A cancel interrupts a statement in progress,
and window A had none; **its locks belong to its transaction, and a cancel does not end
transactions.**

## Terminating it

```
market=# SELECT pg_terminate_backend(5792);
 pg_terminate_backend 
----------------------
 t
(1 row)

Time: 3.469 ms

market=# \i ~/lock-tree.sql
   pid   |        state        | in_transaction |                  last_query                   
---------+---------------------+----------------+-----------------------------------------------
 5794    | idle in transaction | 00:00:35       | UPDATE orders SET status = 'shipped' WHERE id
    5796 | active              | 00:00:31       | UPDATE orders SET status = 'cancelled' WHERE 
(2 rows)

Time: 2.067 ms
```

Window A is gone from the tree. Its connection was closed, its transaction rolled back, and
**its row lock on order 1 went with it**. Window B, which had been waiting for that lock, got it
straight away and finished its update:

```
market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 34430.590 ms (00:34.431)
```

**34,431 milliseconds** for an update that takes two. Window B is now the root, idle in transaction,
holding orders 1 and 2, with window C still waiting under it: terminating the root moved the
chain up by one, it did not empty it. Whether that is the end of the incident depends on what the
application behind window B does next; if it commits, window C goes through.

What did window A's user see? Nothing, until they typed the next statement:

```
market=*# SELECT status FROM orders WHERE id = 1;
FATAL:  terminating connection due to administrator command
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
Time: 3.482 ms
```

The server closed the connection, and psql noticed only when it tried to use it. psql reconnects by
itself, which is why it says `Succeeded`, but **the transaction is gone**: the update of order 1 was
rolled back, and the `SELECT` that discovered it was never run. An application sees the same thing
as an error on its next statement, and whether it recovers depends on whether it was written to
retry, which lesson 14 is about.

## Cancelling a waiting statement

A cancel is the right tool for a session that **is** running something: a report that has been
going for an hour, or a statement stuck in a lock queue that you would rather fail than wait. Window
C is the second kind:

```
market=# SELECT pg_cancel_backend(5796);
 pg_cancel_backend 
-------------------
 t
(1 row)

Time: 0.547 ms
```

```
market=# UPDATE orders SET status = 'cancelled' WHERE id = 2;
ERROR:  canceling statement due to user request
CONTEXT:  while updating tuple (0,2) in relation "orders"
Time: 34135.050 ms (00:34.135)
```

Window C's update failed with `canceling statement due to user request`, after 34,135 ms of
waiting, and the `CONTEXT` names the row it was waiting for. Window C was not in a transaction of its
own, so the failed statement left nothing behind. **Inside a transaction it would have been
different**: the statement fails, the transaction is marked failed, the prompt turns into
`market=!#` as in lesson 12, and **every lock the transaction already held stays held** until the
client sends `ROLLBACK`. Cancelling one statement of a long transaction does not release what the
transaction had taken.

Finish the experiment in window B with `ROLLBACK;`, so that orders 1 and 2 are as `market.sql` made
them.

## Which one, when

- **The root is `idle in transaction`:** cancel does nothing. Terminate it, after finding out from
  `last_query` and the application's logs what it was, because its work is rolled back.
- **The root is `active`, a statement running long:** cancel first. The statement fails and, if it
  was a transaction of one statement, its locks go. If it was inside a longer transaction, the locks
  stay until the application rolls back, and you may need to terminate after all.
- **Never terminate a server process with `kill -9`** from the operating system. PostgreSQL treats a
  backend that died that way as possible damage to shared memory and restarts every connection on
  the server to be safe. The two functions above are the way to end one session.

Both functions need either superuser or membership in `pg_signal_backend`, and neither will signal
a superuser's session unless you are one. On a managed service, that role is usually what your
administrator account has instead of superuser.

**Terminating the root ends the incident; it does not explain it.** Something in the application
opened a transaction and stopped talking. Lesson 15 is about finding those sessions before they
block anybody, and `idle_in_transaction_session_timeout`, which ends them automatically.
