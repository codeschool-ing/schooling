---
title: Idle in transaction
version: 1
---

The connection that does the most harm is often the one doing nothing. **A session that opened a
transaction and stopped sending statements is `idle in transaction`**, and it keeps everything
the transaction took: the row locks of what it changed, and the snapshot that tells vacuum which
old row versions somebody might still need. An application that forgot a `COMMIT`, a person who
typed `BEGIN` in psql and went to lunch, and a program waiting on a slow web request between two
statements all look like this.

Make one. In a terminal, as `app`, start a transaction, change a row, and stop:

```sh
sudo -u app psql shop
```

```sql
BEGIN;
UPDATE customers SET name = 'Customer 1' WHERE id = 1;
```

## Finding it

`ps` already says it, because the backend's name carries its state:

```
ana@db:~$ ps -u postgres -o pid,cmd | grep "app shop"
    655 postgres: 16/main: app shop [local] idle in transaction
```

`pg_stat_activity` says how long, which is what decides whether it is a problem:

```
ana@db:~$ psql shop
shop=# SELECT pid, usename, state, now() - xact_start AS open_for, query
shop-#   FROM pg_stat_activity WHERE state = 'idle in transaction';
 pid | usename |        state        |    open_for     |                         query                          
-----+---------+---------------------+-----------------+--------------------------------------------------------
 655 | app     | idle in transaction | 00:00:01.682687 | UPDATE customers SET name = 'Customer 1' WHERE id = 1;
(1 row)

shop=# SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE state = 'idle in transaction';
 pg_cancel_backend 
-------------------
 t
(1 row)

shop=# SELECT pid, state FROM pg_stat_activity WHERE usename = 'app';
 pid |        state        
-----+---------------------
 655 | idle in transaction
(1 row)

shop=# SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle in transaction';
 pg_terminate_backend 
----------------------
 t
(1 row)

shop=# SELECT pid, state FROM pg_stat_activity WHERE usename = 'app';
 pid | state 
-----+-------
(0 rows)
```

`xact_start` is when the transaction began, so `open_for` is how long it has held what it holds;
on the recording machine it had been open under two seconds, and on a real server the ones worth
finding have been open for minutes or hours. `query` is the last statement, which here names the
row that is locked. Any other session that tries to update customer 1 now waits for this one, for
as long as it stays open; `db-performance` lessons 12 and 13 follow such a queue to its head.
Lesson 14 shows what an old snapshot does to vacuum.

## Cancel is not enough

**`pg_cancel_backend` cancels the statement a backend is running, and this one is running none.**
It answered `t`, meaning the signal was sent, and the session stayed exactly as it was. Cancelling
is the right tool for a query that runs too long, and it leaves the session and its transaction
alive.

**`pg_terminate_backend` ends the session**: the backend rolls back the transaction, releases its
locks and exits, which is the `SIGTERM` the shell sent in the max-connections section. The update
is undone. Somebody who was waiting for that row proceeds. In the first terminal, the person
who walked away finds out with their next command:

```
ana@db:~$ sudo -u app psql shop
shop=> BEGIN;
BEGIN

shop=*> UPDATE customers SET name = 'Customer 1' WHERE id = 1;
UPDATE 1

shop=*> SELECT name FROM customers WHERE id = 1;
FATAL:  terminating connection due to administrator command
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
```

The `*` in `shop=*>` is psql saying a transaction is open, which is worth noticing in your own
sessions. psql reconnected on its own, into a new session with no transaction.

## Letting the server do it

Finding these by hand works once. **`idle_in_transaction_session_timeout` makes the server end any
session that stays idle in a transaction longer than the limit.** Set it on the application's role
rather than for the whole server, so that your own sessions and long maintenance jobs are not
caught by a limit chosen for the application:

```
ana@db:~$ psql shop -c "ALTER ROLE app SET idle_in_transaction_session_timeout = '10s'"
ALTER ROLE
ana@db:~$ sudo -u app psql shop
shop=> BEGIN;
BEGIN

shop=*> SELECT count(*) FROM orders WHERE customer_id = 42;
 count 
-------
    20
(1 row)

shop=*> SELECT 1;
FATAL:  terminating connection due to idle-in-transaction timeout
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
ana@db:~$ sudo grep "idle-in-transaction" /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:50:44.698 -03 [691] app@shop FATAL:  terminating connection due to idle-in-transaction timeout
```

Twelve seconds passed between the count and `SELECT 1`, and the server had ended the session at
ten. **A role's setting applies from its next connection**, which is why this was a new session.
The log line names the role and the database, and a run of them is the evidence to take to whoever
owns the application, because the fix is in their code: a transaction should be open only while
statements are being sent.

Ten seconds is short, for the demonstration; a real limit is chosen from how long the
application's honest transactions take, often a minute or a few. PostgreSQL 16 also has
`idle_session_timeout`, which ends sessions idle outside a transaction; it is rarely what you want
in front of an application that keeps a pool of connections open on purpose.
